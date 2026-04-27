# SawitKu — Full-Stack Design Spec
**Date:** 2026-04-27  
**Approach:** Sequential Strict (Fase 1 → 10)  
**Stack:** Spring Boot 3.5 + Flutter + PostgreSQL + Redis + Claude API

---

## 1. Project Context

### Existing State
- `D:\sawit_app\frontend\` — Flutter app sudah ada (screens: Splash, Beranda, InputPanen, HasilAnalisa, Riwayat)
- `D:\sawit_app\backend\` — **kosong**, diisi dari nol
- Flutter saat ini: 1 kebun hardcoded, analisa lokal tanpa backend

### Target State
Platform SaaS manajemen kebun sawit multi-lahan dengan:
- Multi-lahan per user (tiap lahan punya data & riwayat sendiri)
- Input panen bulanan per lahan
- Analisa penyebab AI (Claude API) per panen
- Sistem subscription (Gratis/Petani/Pro)
- Backend REST API (Spring Boot) + Mobile (Flutter)

---

## 2. Arsitektur

```
D:\sawit_app\
├── backend/                          ← Spring Boot (BARU)
│   ├── Dockerfile
│   ├── pom.xml                       (Java 21, Spring Boot 3.5.x, Maven)
│   └── src/main/java/com/sawitku/
│       ├── config/                   (SecurityConfig, RedisConfig, SwaggerConfig)
│       ├── controller/               (AuthController, LahanController, PanenController, BerandaController)
│       ├── service/                  (AuthService, LahanService, PanenService, AnalisaService, ClaudeService, SubscriptionService)
│       ├── repository/               (UserRepository, LahanRepository, PanenRepository, AnalisaRepository)
│       ├── entity/                   (User, Lahan, Panen, Analisa, Subscription)
│       ├── dto/request/              (LoginRequest, RegisterRequest, LahanRequest, PanenRequest)
│       ├── dto/response/             (ApiResponse, AuthResponse, LahanResponse, PanenResponse, AnalisaResponse)
│       ├── mapper/                   (LahanMapper, PanenMapper)
│       ├── security/                 (JwtUtil, JwtAuthFilter, UserDetailsServiceImpl)
│       ├── exception/                (GlobalExceptionHandler, ResourceNotFoundException, BusinessException)
│       └── util/                     (AnalisaCalculator, ResponseUtil)
│
├── frontend/                         ← Flutter (UPDATE dari yang sudah ada)
│   └── lib/
│       ├── theme/                    (app_theme.dart — UPDATE ke design system baru)
│       ├── models/                   (panen_model.dart UPDATE + lahan_model.dart + analisa_model.dart + user_model.dart BARU)
│       ├── services/                 (api_service.dart DIPERLUAS + analisa_service.dart TETAP sebagai fallback)
│       ├── providers/                (auth_provider.dart + lahan_provider.dart + panen_provider.dart BARU)
│       └── screens/
│           ├── auth/                 (login_screen.dart + register_screen.dart BARU)
│           ├── lahan/                (daftar_lahan_screen.dart + tambah_lahan_screen.dart + detail_lahan_screen.dart BARU)
│           ├── panen/                (input_panen_screen.dart UPDATE + hasil_analisa_screen.dart UPDATE)
│           ├── beranda_screen.dart   (UPDATE — multi-lahan summary)
│           ├── riwayat_screen.dart   (UPDATE — per lahan)
│           └── profil_screen.dart    (BARU)
│
├── docker-compose.yml                ← dev: postgres + redis
├── docker-compose.prod.yml           ← prod: app + postgres + redis + nginx
└── nginx/nginx.conf
```

---

## 3. Database Schema

### Tabel utama
```sql
users           → id, name, email, password, phone, created_at, updated_at
subscriptions   → id, user_id, paket(GRATIS/PETANI/PRO), status, expired_at
lahan           → id, user_id, nama_lahan, luas_ha, usia_pohon, jumlah_pohon,
                   lokasi, latitude, longitude, catatan, is_active, created_at
panen           → id, lahan_id, bulan, tahun, bulan_angka, ton_aktual,
                   target_min, target_max, target_mid, status_panen,
                   persen_kurang, harga_per_ton, catatan, created_at
                   UNIQUE(lahan_id, tahun, bulan_angka)
analisa         → id, panen_id, lahan_id, penyebab_json(JSONB),
                   rekomendasi, ai_response_raw, created_at
```

### Flyway migrations
- `V1__init_schema.sql` — semua tabel + indexes
- `V2__seed_data.sql` — demo data (opsional)

---

## 4. Business Logic

### AnalisaCalculator — Target per fase usia pohon
| Usia | Min/ha | Max/ha | Fase |
|------|--------|--------|------|
| <3 | 0.3 | 0.8 | Belum Produksi |
| 3–5 | 0.8 | 1.4 | Produksi Awal |
| 6–10 | 1.5 | 2.0 | Puncak Awal |
| 11–15 | 1.8 | 2.3 | Puncak Produktif |
| 16–20 | 1.5 | 1.9 | Produksi Stabil |
| >20 | 1.0 | 1.5 | Produksi Menurun |

### Status Panen
- `NORMAL` — tonAktual >= targetMin
- `WARN` — persenKurang <= 20%
- `DANGER` — persenKurang > 20%

### Subscription Limits
| Fitur | GRATIS | PETANI | PRO |
|-------|--------|--------|-----|
| Max lahan | 2 | 10 | ∞ |
| Analisa AI/bulan | 5 | 30 | ∞ |
| Harga | Rp0 | Rp49k | Rp149k |

---

## 5. REST API Endpoints

### Auth
```
POST /api/auth/register   → { name, email, password, phone }
POST /api/auth/login      → { email, password } → { token, user, subscription }
GET  /api/auth/me         → user + subscription aktif
```

### Lahan
```
GET    /api/lahan                    → list lahan user (+ panen terakhir)
POST   /api/lahan                    → buat lahan baru
PUT    /api/lahan/{id}               → update lahan
DELETE /api/lahan/{id}               → soft delete
GET    /api/lahan/{id}               → detail + statistik + 6 bulan riwayat
```

### Panen
```
POST /api/lahan/{id}/panen           → input panen (trigger AI async)
GET  /api/lahan/{id}/panen           → riwayat panen (?limit=7)
GET  /api/lahan/{id}/panen/{pid}     → detail panen + analisa
GET  /api/lahan/{id}/panen/{pid}/analisa → hasil AI (atau PROCESSING)
GET  /api/beranda                    → summary semua lahan user
```

### Response wrapper standar
```json
{ "success": true, "message": "Berhasil", "data": {...}, "timestamp": "..." }
```

### Error codes
- `LAHAN_NOT_FOUND` → 404
- `LAHAN_LIMIT_EXCEEDED` → 400
- `DUPLICATE_PANEN` → 400
- `UNAUTHORIZED` → 401
- `FORBIDDEN` → 403

---

## 6. AI Integration — Claude API

### Flow
1. Input panen disimpan ke DB
2. `@Async` trigger `ClaudeService.analyzePanen()`
3. Claude API call: `POST https://api.anthropic.com/v1/messages`
   - Model: `claude-sonnet-4-20250514`
   - Max tokens: 1000
   - Prompt: context lahan + data panen → minta JSON analisa
4. Parse JSON response → simpan ke tabel `analisa`
5. Cache di Redis: `analisa:{panenId}` TTL 7 hari
6. Fallback ke `AnalisaCalculator.getPenyebabLocal()` jika API error

### Prompt Output Format (JSON)
```json
{
  "penyebab": [
    { "icon": "🌿", "title": "...", "detail": "...", "severity": "high|medium|low", "estimasi_dampak": "X-Y%" }
  ],
  "ringkasan": "1 kalimat untuk petani awam",
  "prioritas_tindakan": "tindakan paling penting minggu ini"
}
```

---

## 7. Security

- **JWT:** JJWT 0.12.3, secret 64+ karakter, expire 24 jam, stateless
- **Password:** BCrypt strength 12
- **Filter:** `JwtAuthFilter extends OncePerRequestFilter`
- **Public endpoints:** `POST /api/auth/register`, `POST /api/auth/login`
- **Protected:** semua `/api/**` lainnya
- **CORS:** `*` di dev, domain spesifik di prod
- **Rate limiting:** 10 req/s per IP di Nginx (prod)

---

## 8. Flutter Design System (UI/UX Pro Max)

### Style: Organic Biophilic
Alam, organik, earthy green — cocok untuk agrikultur Indonesia

### Color Tokens
```dart
// AppColors update
static const primary     = Color(0xFF15803D);  // green-700
static const secondary   = Color(0xFF22C55E);  // green-500 (NORMAL)
static const accent      = Color(0xFFA16207);  // amber-700 (harga/nilai)
static const background  = Color(0xFFF0FDF4);  // green-50
static const foreground  = Color(0xFF14532D);  // green-900
static const destructive = Color(0xFFDC2626);  // red-600 (DANGER)
static const border      = Color(0xFFBBF7D0);  // green-200
static const surface     = Color(0xFFFFFFFF);
static const muted       = Color(0xFFE8F0F1);
```

### Typography
- Heading: **Calistoga** (bold, karakteristik)
- Body/Label: **Inter** (clean, readable)
- Scale: 10 / 12 / 13 / 14 / 16 / 18 / 20 / 24 / 32 / 44

### Navigation
- **go_router** (declarative, deep link support)
- Bottom nav: 4 item — Beranda / Lahan / Riwayat / Profil

### Charts
- **Bar Chart** — riwayat panen 7 bulan (sudah ada, update style)
- **Bullet Chart** — aktual vs target per lahan di beranda
- Library: `fl_chart` (sudah ringan, Flutter-native)

### UX Rules Kritis
- Skeleton shimmer (bukan spinner) saat loading AI analisa
- Touch target min 44×44pt semua elemen interaktif
- Error message di bawah field input
- `inputMode: numeric` untuk field ton/luas/usia
- Konfirmasi sebelum hapus lahan (destructive action)
- Pull-to-refresh di semua list screen

---

## 9. Flutter State Management

**Provider** (bukan Riverpod/Bloc — cukup untuk scope ini)

```
AuthProvider   → user, token, login(), logout(), register()
LahanProvider  → list lahan, selectedLahan, CRUD operations
PanenProvider  → panen per lahan, inputPanen(), getAnalisa()
```

---

## 10. Testing Plan

### Unit Tests
- `AnalisaCalculatorTest` — semua range usia + edge cases
- `LahanServiceTest` — CRUD + limit subscription
- `PanenServiceTest` — input panen + duplikasi + hitung target

### Integration Tests
- `@Testcontainers` dengan PostgreSQL container
- Auth flow: register → login → get profile
- Lahan CRUD + limit enforcement
- Panen input → status calculation

### Coverage target: minimal 70%

---

## 11. Production Infra

```yaml
# docker-compose.prod.yml
services:
  app:      Spring Boot JAR (multi-stage Dockerfile)
  postgres: postgres:16-alpine
  redis:    redis:7-alpine
  nginx:    reverse proxy, SSL termination, rate limit 10 req/s
```

### Env vars production (tidak di-commit)
```
DB_URL, DB_USERNAME, DB_PASSWORD
REDIS_HOST, REDIS_PORT
JWT_SECRET (min 64 karakter random)
CLAUDE_API_KEY
```

---

## 12. Urutan Eksekusi (Sequential Strict)

| Fase | Scope | Output |
|------|-------|--------|
| 1 | Spring Boot setup + Docker Compose | `backend/pom.xml`, `application.yml`, `docker-compose.yml` |
| 2 | Flyway DB migrations | `V1__init_schema.sql` |
| 3 | Entity + Repository | 5 entity, 4 repository |
| 4 | Business Logic + Services | AnalisaCalculator, LahanService, PanenService, ClaudeService |
| 5 | REST Controllers | Auth, Lahan, Panen, Beranda |
| 6 | Spring Security + JWT | SecurityConfig, JwtUtil, JwtAuthFilter |
| 7 | SubscriptionService | Limit enforcement + Redis tracking |
| 8 | Flutter update | Design system, go_router, Provider, semua screen baru/update |
| 9 | Tests | Unit + Integration tests |
| 10 | Production | Dockerfile, docker-compose.prod, nginx.conf |

**Catatan Fase 8:** Flutter refactor cukup besar — PanenModel berubah (hilang luasHa/usiaTahun), tambah LahanModel, ganti Navigator ke go_router, tambah Provider layer, tambah 6 screen baru.

---

## 13. Dependency Versions

### Backend (pom.xml)
```xml
Java: 21
Spring Boot: 3.5.x
jjwt-api/impl/jackson: 0.12.3
mapstruct: 1.5.5
lombok: latest
flyway-core: latest
postgresql driver: latest
spring-boot-starter-data-redis
```

### Flutter (pubspec.yaml additions)
```yaml
go_router: ^14.x
provider: ^6.x
fl_chart: ^0.68.x
dio: ^5.x (sudah ada)
shared_preferences: ^2.x (sudah ada)
google_fonts: ^6.x
```
