# Offline Mode Design — Sawitku

**Date:** 2026-05-01  
**Status:** Approved  

---

## Problem

Petani sawit di lokasi rural (Riau, Kaltim, Sumsel) sering berada di kebun dengan sinyal 2G intermittent atau tidak ada sinyal. App crash/freeze saat input panen di kebun = uninstall. Offline mode adalah critical path untuk retention.

---

## Scope

**In scope:**
- Input panen (create, update, delete)
- Input biaya operasional (create, update, delete)
- CRUD lahan
- Baca riwayat panen, data lahan, data biaya (read-only cache)

**Out of scope:**
- Diagnosa Visual AI (butuh Claude API — mustahil offline)
- Payment / subscription
- Export PDF

---

## Architecture

```
┌─────────────────────────────────────────┐
│              UI Screens                  │
│  (beranda, riwayat, biaya, lahan)        │
└──────────────┬──────────────────────────┘
               │ calls
┌──────────────▼──────────────────────────┐
│           Repository Layer               │
│  LahanRepository / PanenRepository /    │
│  BiayaRepository                        │
│                                         │
│  • Read: SQLite first, never network    │
│  • Write: SQLite + enqueue sync         │
└──────┬───────────────────┬──────────────┘
       │                   │
┌──────▼──────┐   ┌────────▼────────────┐
│  Drift DB   │   │    SyncService      │
│  (SQLite)   │   │                     │
│             │   │  • Monitor koneksi  │
│  lahans     │   │  • On online: flush │
│  panens     │   │    sync_queue       │
│  biayas     │   │  • Server menang    │
│  sync_queue │   │    jika konflik     │
└─────────────┘   └─────────────────────┘
                           │
                  ┌────────▼────────────┐
                  │    ApiService       │
                  │  (existing Dio)     │
                  └─────────────────────┘
```

**Prinsip:**
- Screen tidak pernah call `ApiService` langsung — selalu lewat Repository
- `ApiService` tidak berubah — hanya dipanggil oleh SyncService dan Repository saat refresh online
- SQLite adalah source of truth di device; server adalah source of truth canonical

---

## Database Schema (Drift)

### `lahans`
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | server id |
| nama_lahan | TEXT | |
| luas_ha | REAL | |
| usia_pohon | INTEGER | |
| tahun_tanam | INTEGER NULLABLE | |
| jumlah_pohon | INTEGER NULLABLE | |
| lokasi | TEXT NULLABLE | |
| is_active | BOOLEAN | default true |
| cached_at | INTEGER | unix timestamp |

### `panens`
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | server id, atau negative temp id saat offline |
| lahan_id | INTEGER | FK ke lahans |
| bulan | TEXT | |
| tahun | INTEGER | |
| bulan_angka | INTEGER | |
| tanggal | INTEGER NULLABLE | |
| ton_aktual | REAL | |
| target_min | REAL | default 0 saat offline |
| target_max | REAL | default 0 saat offline |
| target_mid | REAL | default 0 saat offline |
| harga_per_ton | REAL | default 2400000 |
| status_panen | TEXT NULLABLE | |
| persen_kurang | REAL | default 0 |
| catatan | TEXT NULLABLE | |
| cached_at | INTEGER | unix timestamp |

### `biayas`
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | server id, atau negative temp id saat offline |
| lahan_id | INTEGER | FK ke lahans |
| bulan | TEXT | |
| tahun | INTEGER | |
| bulan_angka | INTEGER | |
| kategori | TEXT | PUPUK/TENAGA_KERJA/PESTISIDA/PERALATAN/LAINNYA |
| jumlah | REAL | |
| keterangan | TEXT NULLABLE | |
| cached_at | INTEGER | unix timestamp |

### `sync_queue`
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| entity | TEXT | 'panen' \| 'biaya' \| 'lahan' |
| operation | TEXT | 'create' \| 'update' \| 'delete' |
| payload | TEXT | JSON string request body |
| lahan_id | INTEGER | untuk routing endpoint |
| local_id | INTEGER | temp id di SQLite (untuk update setelah sync) |
| created_at | INTEGER | unix timestamp, ORDER BY ini saat flush |
| retry_count | INTEGER | default 0, max 3 |

---

## Sync Strategy

### Read Flow
```
Repository.getList(lahanId)
  → return data dari SQLite (immediate)
  → IF online: background fetch dari server → upsert ke SQLite
```

### Write Flow
```
Repository.create(data)
  1. Generate temp id = -DateTime.now().millisecondsSinceEpoch
  2. INSERT ke SQLite dengan temp id
  3. Enqueue ke sync_queue (operation='create', local_id=temp_id)
  4. Return model lokal → UI update seketika, tidak nunggu network
```

### Sync Flush
```
SyncService.flush():
  1. Ambil semua rows dari sync_queue ORDER BY created_at ASC
  2. Untuk tiap item:
     a. Call ApiService sesuai entity+operation
     b. SUCCESS (2xx):
        - operation='create': update SQLite ganti temp_id → server_id
        - operation='update'/'delete': tidak ada perubahan id
        - Hapus dari sync_queue
     c. FAIL 4xx (client error, data invalid):
        - Hapus dari sync_queue (skip, tidak retry)
     d. FAIL 5xx / timeout:
        - INCREMENT retry_count
        - Jika retry_count >= 3: hapus dari queue (abandon)
  3. Setelah queue kosong: full refresh cache dari server
```

### Conflict Resolution
**Server selalu menang.** Rasional: petani menggunakan 1 device, konflik nyata hampir mustahil. Setelah sync berhasil, server data di-upsert ke SQLite menimpa versi lokal.

### Trigger Sync
1. App foreground (lifecycle `resumed`)
2. `connectivity_plus` detect `ConnectivityResult.mobile` atau `.wifi`
3. Pull-to-refresh manual di screen manapun

---

## Offline UX Indicator

### Status Banner
Banner tipis di bawah AppBar saat offline:
```
┌────────────────────────────────────────┐
│  ⚡ Mode Offline — data tersimpan lokal │
└────────────────────────────────────────┘
```
- Warna: `AppColors.warning` (amber)
- Auto-hilang saat kembali online dengan animasi slide-up
- Widget: `OfflineBanner` (reusable, dipakai di semua screen utama)

### Sync Badge
Badge di AppBar saat ada item pending di `sync_queue`:
```
Kebun Saya  [↑3]
```
- Tap badge → bottom sheet "3 data menunggu sync"
- Hilang otomatis setelah queue kosong

---

## File Structure

```
frontend/lib/
├── database/
│   ├── app_database.dart          ← Drift DB class, semua table ref
│   ├── app_database.g.dart        ← generated (jangan edit manual)
│   └── tables/
│       ├── lahan_table.dart       ← LahanTable drift definition
│       ├── panen_table.dart       ← PanenTable drift definition
│       ├── biaya_table.dart       ← BiayaTable drift definition
│       └── sync_queue_table.dart  ← SyncQueueTable drift definition
├── repositories/
│   ├── lahan_repository.dart      ← read/write lahan via SQLite+sync
│   ├── panen_repository.dart      ← read/write panen via SQLite+sync
│   └── biaya_repository.dart      ← read/write biaya via SQLite+sync
└── services/
    └── sync_service.dart          ← flush queue, monitor connectivity
```

**Screens yang dimodifikasi** (ganti direct ApiService call → Repository):
- `beranda_screen.dart`
- `lahan_screen.dart`
- `riwayat_screen.dart`
- `biaya_screen.dart`
- `input_panen_screen.dart`

**Widget baru:**
- `offline_banner.dart` — status indicator

---

## Dependencies Baru

```yaml
# pubspec.yaml additions
drift: ^2.18.0
drift_flutter: ^0.2.0        # SQLite native bindings (iOS/Android/desktop)
connectivity_plus: ^6.0.3    # monitor network state
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Create offline, sync gagal 3x | Data tetap di SQLite, hapus dari queue, tampilkan snackbar "Gagal sync, cek koneksi" |
| Delete offline, item belum pernah sync | Hapus dari SQLite dan hapus dari sync_queue (operasi create yang pending) |
| Server return 409 conflict | Treat as 4xx — hapus dari queue, refresh dari server |
| DB corrupt / migration fail | Catch error, reset DB, force re-login |

---

## Testing

- Unit test `SyncService.flush()`: mock ApiService, assert queue cleared on success, retry_count incremented on 5xx
- Unit test Repository: assert SQLite write before network call
- Widget test `OfflineBanner`: appears when connectivity mock returns none
- Integration test: create panen offline → go online → assert server has data
