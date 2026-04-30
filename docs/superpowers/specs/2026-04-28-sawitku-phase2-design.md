# SawitKu Phase 2 — Feature Expansion Design Spec

**Date:** 2026-04-28
**Status:** Approved

---

## Goal

Expand SawitKu from a basic harvest tracker into a comprehensive palm oil farm management app with hybrid navigation, cost tracking, AI visual diagnosis, fertilization scheduling, cross-farm comparison, and tips content — making the subscription tiers meaningfully differentiated.

---

## Architecture Overview

### Navigation Restructure (Hybrid Pattern)

Bottom nav reduced from 4 tabs to **3 tabs**:
- **Beranda** — smart dashboard + 2×4 feature grid (launchpad)
- **Analisa** — latest harvest analysis result
- **Profil** — account, settings, subscription info

Beranda acts as the central hub. All features are accessible from the grid icons on Beranda. This mirrors the BRImo/BSI Mobile pattern familiar to Indonesian users.

**Grid icon layout (2×4, 8 icons):**
```
[ Input Panen ] [ Biaya Ops  ] [ Foto Diag  ] [ Riwayat   ]
[ Jadwal Pupuk] [ Banding    ] [ Tips       ] [ Export PDF ]
```

Each grid icon card: 72×72dp, icon + label below, color-coded by category, badge for unread/pending state.

---

## Feature 1: Biaya Operasional (Cost Tracking)

### Purpose
Let farmers track monthly operational costs per farm and calculate **net profit** (pendapatan - biaya).

### Backend

**New Entity: `Biaya`**
```
id            BIGSERIAL PK
lahan_id      BIGINT FK → lahan
bulan         VARCHAR(20)   -- "Januari"
tahun         INT
bulan_angka   INT           -- 1–12
kategori      VARCHAR(30)   -- PUPUK | TENAGA_KERJA | PESTISIDA | PERALATAN | LAINNYA
jumlah        NUMERIC(15,2) -- Rp amount
keterangan    TEXT nullable
created_at    TIMESTAMP
```

**Flyway migration:** `V5__create_biaya_table.sql`

**Endpoints:**
- `POST   /api/lahan/{lahanId}/biaya`            — create
- `GET    /api/lahan/{lahanId}/biaya?tahun=&limit=` — list
- `PUT    /api/lahan/{lahanId}/biaya/{biayaId}`  — update
- `DELETE /api/lahan/{lahanId}/biaya/{biayaId}`  — delete

**BiayaResponse fields:** id, lahanId, bulan, tahun, bulanAngka, kategori, jumlah, keterangan, createdAt

**Profit calculation:** `GET /api/lahan/{lahanId}/panen/{panenId}/profit` returns `{ pendapatan, totalBiaya, labaBersih }` — fetches biaya for same bulan/tahun as panen.

### Frontend

**New screen: `biaya_screen.dart`**
- Header: lahan name + year selector
- List biaya grouped by month, sorted newest first
- Each item: kategori chip (color-coded) + jumlah + keterangan
- FAB → bottom sheet form: kategori dropdown, nominal field (Rp formatter), bulan/tahun picker, keterangan optional
- Swipe-to-delete with confirm dialog
- Empty state: "Belum ada catatan biaya. Tap + untuk tambah."

**Riwayat screen changes:**
- Add toggle tabs: `Panen | Biaya` at top of screen
- Panen tab: existing view unchanged
- Biaya tab: shows BiayaScreen content inline
- Summary card: Pendapatan Bulan Ini vs Total Biaya vs **Laba Bersih** (green if positive, red if negative)

**API service additions:** `getBiaya()`, `createBiaya()`, `updateBiaya()`, `deleteBiaya()`

---

## Feature 2: Diagnosa Visual AI

### Purpose
Farmer takes a photo of palm oil buah/batang/pelepah → Claude Vision API analyzes the image → returns diagnosis + recommended action. Two entry points: standalone from grid, and optional attachment during panen input.

### Backend

**New Entity: `Diagnosa`**
```
id            BIGSERIAL PK
lahan_id      BIGINT FK → lahan
jenis         VARCHAR(20)   -- BUAH | BATANG | PELEPAH
image_base64  TEXT          -- stored as base64 (MVP; replace with S3 later)
diagnosis     TEXT          -- Claude response: kondisi
penyebab      TEXT          -- Claude response: penyebab
rekomendasi   TEXT          -- Claude response: tindakan
severity      VARCHAR(20)   -- NORMAL | PERHATIAN | KRITIS
created_at    TIMESTAMP
```

**Flyway migration:** `V6__create_diagnosa_table.sql`

**Endpoints:**
- `POST /api/lahan/{lahanId}/diagnosa/visual` — multipart: `image` (file) + `jenis` (string)
- `GET  /api/lahan/{lahanId}/diagnosa?limit=20` — history

**ClaudeService addition:** `analyzeImage(byte[] imageBytes, String jenis, Lahan lahan)` — builds prompt with context (lahan area, tree age, jenis), sends to Claude with vision, parses JSON response.

**Claude prompt template:**
```
Kamu adalah ahli pertanian sawit. Analisa foto [jenis] tanaman kelapa sawit ini.
Konteks: Kebun luas [X] ha, usia pohon [Y] tahun.
Berikan diagnosis dalam format JSON:
{
  "kondisi": "deskripsi kondisi yang terlihat",
  "penyebab": "kemungkinan penyebab",
  "rekomendasi": "tindakan yang harus dilakukan",
  "severity": "NORMAL|PERHATIAN|KRITIS"
}
```

**Fallback** (Claude error/timeout): return pre-defined advice per `jenis`:
- BUAH → "Pastikan panen saat tandan matang (brondolan jatuh 5-10 buah/tandan)..."
- BATANG → "Periksa tanda-tanda Ganoderma: akar busuk, jamur putih di pangkal..."
- PELEPAH → "Pelepah menguning bisa tanda defisiensi Mg atau N..."

**Image size limit:** reject if > 5MB, recommend compress on client.

### Frontend

**New screen: `diagnosa_screen.dart`**
- Header: "Diagnosa Visual" + riwayat button (top right)
- Three jenis selector chips: `🌿 Buah Sawit` | `🌲 Batang` | `🍃 Pelepah/Daun`
- Large camera area (placeholder when no image): tap → action sheet (Ambil Foto / Pilih dari Galeri)
- Selected image preview with "Ganti Foto" button
- "Analisa Sekarang" CTA button (disabled until image + jenis selected)
- Loading state: "Sedang menganalisa..." with spinner
- Result card: severity badge (color-coded) + kondisi + penyebab + rekomendasi
- Save result + "Analisa Lagi" actions
- History screen: `diagnosa_history_screen.dart` — list past diagnosa

**Input panen changes:**
- Add optional section at bottom: "Foto Kondisi Kebun (Opsional)"
- Same image picker, no jenis selector (auto = BUAH for panen context)
- Foto disimpan bersama panen data, analisa visual dijalankan background

**Dependencies to add to pubspec:**
- `image_picker: ^1.0.7`
- `image_compress` or Flutter built-in resize before upload

---

## Feature 3: Jadwal Pupuk

### Purpose
Display PPKS-standard fertilization schedule for the current year based on tree age, so farmers know when to fertilize and what to use.

### Logic (pure frontend, no backend)

Fertilization schedule based on `usiaPohon`:
- **TBM (< 3 tahun):** 4x/year — Jan, Apr, Jul, Okt — NPK + Urea + Dolomit
- **TM Muda (3–8 tahun):** 4x/year — Feb, Mei, Agu, Nov — NPK + Urea + Dolomit + Boraks
- **TM Dewasa (> 8 tahun):** 2x/year — Mar, Sep — NPK + MOP + Dolomit

Dose per ha varies by phase (shown in detail screen).

### Frontend

**New screen: `jadwal_pupuk_screen.dart`**
- Year header + lahan info
- Timeline list: month cards with status (Selesai / Akan Datang / Bulan Ini — highlighted)
- Each card: bulan, jenis pupuk, dosis/ha, estimated cost
- "Bulan Ini" card has green highlight + "Tandai Selesai" (local state only)

**Beranda grid:** shows next fertilization month as subtitle on the icon badge.

---

## Feature 4: Perbandingan Lahan

### Purpose
One screen comparing all user's farms by harvest performance, so multi-farm farmers can prioritize attention.

### Frontend

**New screen: `perbandingan_screen.dart`**
- Fetch: `GET /api/beranda` (already returns all lahan + latest panen status)
- Bar chart horizontal: each bar = satu lahan, value = (tonAktual / targetMid × 100)%
- Color: green if ≥100%, yellow if ≥70%, red if <70%
- Below chart: ranked list cards (1st, 2nd, 3rd…) with lahan name, status, and last panen ton
- Tap card → navigate to that lahan's riwayat (via LahanScreen switch)

**No backend changes needed** — reuses existing `/api/beranda` endpoint.

---

## Feature 5: Info & Tips

### Purpose
Static educational content for palm oil farmers: best practices for fertilization, harvesting, and pest management.

### Frontend

**New screen: `tips_screen.dart`**
- 3 category tabs: `Pemupukan` | `Panen & Kualitas` | `Hama & Penyakit`
- Card list per category, expandable (ExpansionTile)
- Each card: title + 3-5 bullet points
- Static data defined in `lib/data/tips_data.dart`
- No backend, no API calls

**Content (15 tips total, 5 per category) — defined in code.**

---

## Navigation Changes Detail

### `main_screen.dart`
- Bottom nav: 3 items `[Beranda, Analisa, Profil]`
- `IndexedStack` screens: `[BerandaScreen, HasilAnalisaScreen, ProfileScreen]`
- Remove: Input tab, Riwayat tab from bottom nav (accessible via grid)
- Profil no longer push-navigated from AppBar icon; it IS a tab now
- AppBar: remove profile icon button, keep Kebun switcher + paket badge

### `beranda_screen.dart`
- Keep existing: status cards + mini chart
- ADD below: section header "Fitur" + `_FeatureGrid` widget (2×4 GridView)
- Each `_GridIcon`: icon, label, optional badge/subtitle, onTap → Navigator.push to target screen
- Pass `lahan` to all navigated screens

---

## Subscription Gating Changes

| Feature | GRATIS | PETANI | PRO |
|---|---|---|---|
| Diagnosa Visual AI | 3/bulan | 20/bulan | Unlimited |
| Biaya Operasional | ✅ | ✅ | ✅ |
| Jadwal Pupuk | ✅ | ✅ | ✅ |
| Perbandingan Lahan | ❌ | ✅ | ✅ |
| Export PDF | ❌ | ✅ | ✅ |
| Info & Tips | ✅ | ✅ | ✅ |

Add `DIAGNOSA_LIMIT` to `SubscriptionService.checkLimitDiagnosaAI()` — same Redis pattern as analisa.
Move PDF export gate: check subscription before generating PDF.

---

## File Map

### New Backend Files
- `entity/Biaya.java`
- `entity/Diagnosa.java`
- `repository/BiayaRepository.java`
- `repository/DiagnosaRepository.java`
- `dto/request/BiayaRequest.java`
- `dto/request/DiagnosaRequest.java`
- `dto/response/BiayaResponse.java`
- `dto/response/DiagnosaResponse.java`
- `service/BiayaService.java`
- `service/DiagnosaService.java`
- `controller/BiayaController.java`
- `controller/DiagnosaController.java`
- `resources/db/migration/V5__create_biaya_table.sql`
- `resources/db/migration/V6__create_diagnosa_table.sql`

### New Frontend Files
- `screens/biaya_screen.dart`
- `screens/diagnosa_screen.dart`
- `screens/diagnosa_history_screen.dart`
- `screens/jadwal_pupuk_screen.dart`
- `screens/perbandingan_screen.dart`
- `screens/tips_screen.dart`
- `data/tips_data.dart`
- `data/jadwal_pupuk_data.dart`
- `models/biaya_model.dart`
- `models/diagnosa_model.dart`

### Modified Backend Files
- `service/ClaudeService.java` — add `analyzeImage()` method
- `service/SubscriptionService.java` — add `checkLimitDiagnosaAI()`

### Modified Frontend Files
- `screens/main_screen.dart` — 3-tab nav, remove profile icon
- `screens/beranda_screen.dart` — add feature grid
- `screens/riwayat_screen.dart` — add Panen/Biaya toggle tabs
- `screens/input_panen_screen.dart` — add optional photo
- `services/api_service.dart` — add biaya + diagnosa methods

---

## Tech Stack Additions

**Flutter:**
- `image_picker: ^1.0.7` — camera + gallery access
- `flutter_image_compress: ^2.1.0` — compress before upload

**Backend:**
- No new dependencies — Claude Vision uses existing Anthropic SDK (messages API supports images)

---

## Error Handling

| Scenario | Handling |
|---|---|
| Claude Vision timeout/error | Return fallback advice per jenis |
| Image > 5MB | Client-side validation before upload |
| Diagnosa limit exceeded | Same 429-style BusinessException as analisa |
| Biaya delete fails | Show snackbar, keep item in list |
| Perbandingan with 1 lahan | Show empty state: "Tambah minimal 2 kebun untuk membandingkan" |
