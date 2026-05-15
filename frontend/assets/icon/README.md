# App Icon Assets

Letakkan file berikut di folder ini sebelum generate:

| File | Ukuran | Keterangan |
|------|--------|------------|
| `icon.png` | 1024×1024 px | Icon utama (PNG transparan atau solid) |
| `icon_foreground.png` | 1024×1024 px | Foreground adaptive icon Android 8+ (aman zone 66%) |

Setelah file tersedia, generate icons dan splash:

```bash
cd frontend
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Warna background: `#166534` (hijau sawit gelap)
