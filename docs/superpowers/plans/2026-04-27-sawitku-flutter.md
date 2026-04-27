# SawitKu Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Update Flutter app untuk mendukung multi-lahan, auth, dan koneksi ke Spring Boot backend.

**Architecture:** Provider state management, go_router navigation, Dio HTTP client dengan JWT interceptor. Design system Organic Biophilic (#15803D green palette, Calistoga + Inter fonts).

**Tech Stack:** Flutter, Provider, go_router, Dio, fl_chart, google_fonts, shared_preferences

**Working Directory:** `D:\sawit_app\frontend\`

---

## Task 1: Update pubspec.yaml & Design System

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/theme/app_theme.dart`

- [ ] **Step 1: Update pubspec.yaml**

```yaml
name: sawitku
description: Platform manajemen kebun sawit
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  shared_preferences: ^2.3.0
  provider: ^6.1.2
  go_router: ^14.3.0
  fl_chart: ^0.68.0
  google_fonts: ^6.2.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Update lib/theme/app_theme.dart** (ganti seluruh isi)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary     = Color(0xFF15803D);
  static const primary2    = Color(0xFF166534);
  static const primary3    = Color(0xFF22C55E);
  static const primaryTint = Color(0xFFDCFCE7);
  static const accent      = Color(0xFFA16207);
  static const goldLight   = Color(0xFFD97706);
  static const background  = Color(0xFFF0FDF4);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF8FAF9);
  static const border      = Color(0xFFBBF7D0);
  static const text        = Color(0xFF14532D);
  static const textMid     = Color(0xFF166534);
  static const textMuted   = Color(0xFF6B7280);
  static const textLight   = Color(0xFF9CA3AF);
  static const danger      = Color(0xFFDC2626);
  static const dangerTint  = Color(0xFFFEF2F2);
  static const warn        = Color(0xFFD97706);
  static const warnTint    = Color(0xFFFFFBEB);
}

class AppTextStyles {
  static TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.calistoga(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

  static TextStyle label({Color? color}) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
          color: color ?? AppColors.textLight, letterSpacing: 0.8);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.calistoga(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}
```

- [ ] **Step 3: Install packages**

```bash
cd /d/sawit_app/frontend
flutter pub get
```

- [ ] **Step 4: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/lib/theme/
git commit -m "feat: update Flutter design system (Organic Biophilic palette + Calistoga/Inter)"
```

---

## Task 2: Models

**Files:**
- Modify: `lib/models/panen_model.dart`
- Create: `lib/models/lahan_model.dart`
- Create: `lib/models/user_model.dart`
- Create: `lib/models/analisa_model.dart`

- [ ] **Step 1: Create lib/models/user_model.dart**

```dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String paket;

  const UserModel({required this.id, required this.name, required this.email, this.phone, required this.paket});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'], name: json['name'], email: json['email'],
    phone: json['phone'], paket: json['paket'] ?? 'GRATIS',
  );
}
```

- [ ] **Step 2: Create lib/models/lahan_model.dart**

```dart
class LahanModel {
  final int id;
  final String namaLahan;
  final double luasHa;
  final int usiaPohon;
  final int? jumlahPohon;
  final String? lokasi;
  final String? catatan;
  final bool isActive;
  final String? faseProduksi;
  final PanenSummary? panenTerakhir;
  final String? statusTerkini;

  const LahanModel({
    required this.id, required this.namaLahan, required this.luasHa,
    required this.usiaPohon, this.jumlahPohon, this.lokasi, this.catatan,
    required this.isActive, this.faseProduksi, this.panenTerakhir, this.statusTerkini,
  });

  factory LahanModel.fromJson(Map<String, dynamic> json) => LahanModel(
    id: json['id'], namaLahan: json['namaLahan'], luasHa: (json['luasHa'] as num).toDouble(),
    usiaPohon: json['usiaPohon'], jumlahPohon: json['jumlahPohon'],
    lokasi: json['lokasi'], catatan: json['catatan'],
    isActive: json['isActive'] ?? true, faseProduksi: json['faseProduksi'],
    panenTerakhir: json['panenTerakhir'] != null ? PanenSummary.fromJson(json['panenTerakhir']) : null,
    statusTerkini: json['statusTerkini'],
  );
}

class PanenSummary {
  final int id;
  final String bulan;
  final int tahun;
  final double tonAktual;
  final double targetMid;
  final String statusPanen;
  final double persenKurang;

  const PanenSummary({
    required this.id, required this.bulan, required this.tahun,
    required this.tonAktual, required this.targetMid,
    required this.statusPanen, required this.persenKurang,
  });

  factory PanenSummary.fromJson(Map<String, dynamic> json) => PanenSummary(
    id: json['id'], bulan: json['bulan'], tahun: json['tahun'],
    tonAktual: (json['tonAktual'] as num).toDouble(),
    targetMid: (json['targetMid'] as num).toDouble(),
    statusPanen: json['statusPanen'],
    persenKurang: (json['persenKurang'] as num).toDouble(),
  );
}
```

- [ ] **Step 3: Create lib/models/analisa_model.dart**

```dart
class AnalisaModel {
  final int? id;
  final String status; // DONE, PROCESSING, FAILED
  final List<PenyebabItem> penyebab;
  final String? ringkasan;
  final String? prioritasTindakan;

  const AnalisaModel({required this.id, required this.status, required this.penyebab, this.ringkasan, this.prioritasTindakan});

  factory AnalisaModel.fromJson(Map<String, dynamic> json) => AnalisaModel(
    id: json['id'], status: json['status'] ?? 'PROCESSING',
    penyebab: (json['penyebab'] as List? ?? []).map((p) => PenyebabItem.fromJson(p)).toList(),
    ringkasan: json['ringkasan'], prioritasTindakan: json['prioritasTindakan'],
  );
}

class PenyebabItem {
  final String icon;
  final String title;
  final String detail;
  final String severity;
  final String? estimasiDampak;

  const PenyebabItem({required this.icon, required this.title, required this.detail, required this.severity, this.estimasiDampak});

  factory PenyebabItem.fromJson(Map<String, dynamic> json) => PenyebabItem(
    icon: json['icon'] ?? '🌿', title: json['title'],
    detail: json['detail'], severity: json['severity'],
    estimasiDampak: json['estimasiDampak'],
  );
}
```

- [ ] **Step 4: Update lib/models/panen_model.dart** (hapus luasHa/usiaTahun, tambah field baru)

```dart
class PanenModel {
  final int? id;
  final int? lahanId;
  final String? namaLahan;
  final double tonAktual;
  final double targetMin;
  final double targetMax;
  final double targetMid;
  final String bulan;
  final int? tahun;
  final int? bulanAngka;
  final DateTime? createdAt;
  final AnalisaModel? analisa;

  const PanenModel({
    this.id, this.lahanId, this.namaLahan,
    required this.tonAktual, required this.targetMin,
    required this.targetMax, required this.targetMid,
    required this.bulan, this.tahun, this.bulanAngka,
    this.createdAt, this.analisa,
  });

  double get persenKurang => targetMid > 0
      ? ((targetMid - tonAktual) / targetMid * 100).clamp(0, 100) : 0;
  String get status {
    if (tonAktual >= targetMin) return 'normal';
    if (persenKurang <= 20) return 'warn';
    return 'danger';
  }

  factory PanenModel.fromJson(Map<String, dynamic> json) => PanenModel(
    id: json['id'], lahanId: json['lahanId'], namaLahan: json['namaLahan'],
    tonAktual: (json['tonAktual'] as num).toDouble(),
    targetMin: (json['targetMin'] as num).toDouble(),
    targetMax: (json['targetMax'] as num).toDouble(),
    targetMid: (json['targetMid'] as num).toDouble(),
    bulan: json['bulan'], tahun: json['tahun'], bulanAngka: json['bulanAngka'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    analisa: json['analisa'] != null ? AnalisaModel.fromJson(json['analisa']) : null,
  );
}

// AnalisaPenyebab + HasilAnalisa tetap untuk backward compat dengan analisa_service.dart
class AnalisaPenyebab {
  final String icon, title, detail, severity;
  AnalisaPenyebab({required this.icon, required this.title, required this.detail, required this.severity});
  factory AnalisaPenyebab.fromJson(Map<String, dynamic> j) =>
      AnalisaPenyebab(icon: j['icon'], title: j['title'], detail: j['detail'], severity: j['severity']);
}

class HasilAnalisa {
  final PanenModel panen;
  final List<AnalisaPenyebab> penyebab;
  HasilAnalisa({required this.panen, required this.penyebab});
}
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/models/
git commit -m "feat: update Flutter models (LahanModel, AnalisaModel, UserModel, PanenModel refactor)"
```

---

## Task 3: Providers & ApiService

**Files:**
- Modify: `lib/services/api_service.dart`
- Create: `lib/providers/auth_provider.dart`
- Create: `lib/providers/lahan_provider.dart`
- Create: `lib/providers/panen_provider.dart`

- [ ] **Step 1: Update lib/services/api_service.dart**

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lahan_model.dart';
import '../models/panen_model.dart';
import '../models/analisa_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  ApiException(this.message, {this.code});
  @override String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15)));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final data = error.response?.data;
        final msg = data is Map ? data['message'] ?? 'Terjadi kesalahan' : 'Terjadi kesalahan';
        final code = data is Map ? data['code'] : null;
        handler.reject(DioException(requestOptions: error.requestOptions,
            error: ApiException(msg, code: code)));
      },
    ));
  }

  T _extract<T>(Response res, T Function(dynamic) fromJson) {
    final data = res.data;
    if (data['success'] == true) return fromJson(data['data']);
    throw ApiException(data['message'] ?? 'Error');
  }

  // AUTH
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final token = res.data['data']['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return res.data['data'];
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, {String? phone}) async {
    final res = await _dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password, 'phone': phone});
    final token = res.data['data']['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return res.data['data'];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // LAHAN
  Future<List<LahanModel>> getMyLahan() async {
    final res = await _dio.get('/lahan');
    return _extract(res, (d) => (d as List).map((e) => LahanModel.fromJson(e)).toList());
  }

  Future<LahanModel> createLahan(Map<String, dynamic> data) async {
    final res = await _dio.post('/lahan', data: data);
    return _extract(res, (d) => LahanModel.fromJson(d));
  }

  Future<LahanModel> updateLahan(int lahanId, Map<String, dynamic> data) async {
    final res = await _dio.put('/lahan/$lahanId', data: data);
    return _extract(res, (d) => LahanModel.fromJson(d));
  }

  Future<void> deleteLahan(int lahanId) async {
    await _dio.delete('/lahan/$lahanId');
  }

  Future<LahanModel> getLahanDetail(int lahanId) async {
    final res = await _dio.get('/lahan/$lahanId');
    return _extract(res, (d) => LahanModel.fromJson(d));
  }

  // PANEN
  Future<PanenModel> inputPanen(int lahanId, Map<String, dynamic> data) async {
    final res = await _dio.post('/lahan/$lahanId/panen', data: data);
    return _extract(res, (d) => PanenModel.fromJson(d));
  }

  Future<List<PanenModel>> getRiwayatPanen(int lahanId, {int limit = 7}) async {
    final res = await _dio.get('/lahan/$lahanId/panen', queryParameters: {'limit': limit});
    return _extract(res, (d) => (d as List).map((e) => PanenModel.fromJson(e)).toList());
  }

  Future<AnalisaModel> getAnalisa(int lahanId, int panenId) async {
    final res = await _dio.get('/lahan/$lahanId/panen/$panenId/analisa');
    return _extract(res, (d) => AnalisaModel.fromJson(d));
  }

  Future<Map<String, dynamic>> getBeranda() async {
    final res = await _dio.get('/beranda');
    return _extract(res, (d) => d as Map<String, dynamic>);
  }
}
```

- [ ] **Step 2: Create lib/providers/auth_provider.dart**

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  String? _error;
  bool _loading = false;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> checkAuth() async {
    _isLoggedIn = await _api.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _userData = await _api.login(email, password);
      _isLoggedIn = true;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password, {String? phone}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _userData = await _api.register(name, email, password, phone: phone);
      _isLoggedIn = true;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _isLoggedIn = false; _userData = null;
    notifyListeners();
  }
}
```

- [ ] **Step 3: Create lib/providers/lahan_provider.dart**

```dart
import 'package:flutter/material.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';

class LahanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<LahanModel> _lahans = [];
  bool _loading = false;
  String? _error;

  List<LahanModel> get lahans => _lahans;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchLahans() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _lahans = await _api.getMyLahan();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> createLahan(Map<String, dynamic> data) async {
    try {
      final lahan = await _api.createLahan(data);
      _lahans.add(lahan); notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLahan(int lahanId) async {
    try {
      await _api.deleteLahan(lahanId);
      _lahans.removeWhere((l) => l.id == lahanId);
      notifyListeners(); return true;
    } catch (e) {
      _error = e.toString(); notifyListeners(); return false;
    }
  }
}
```

- [ ] **Step 4: Create lib/providers/panen_provider.dart**

```dart
import 'package:flutter/material.dart';
import '../models/panen_model.dart';
import '../models/analisa_model.dart';
import '../services/api_service.dart';

class PanenProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<PanenModel> _riwayat = [];
  AnalisaModel? _lastAnalisa;
  bool _loading = false;
  String? _error;

  List<PanenModel> get riwayat => _riwayat;
  AnalisaModel? get lastAnalisa => _lastAnalisa;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchRiwayat(int lahanId) async {
    _loading = true; notifyListeners();
    try {
      _riwayat = await _api.getRiwayatPanen(lahanId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<PanenModel?> inputPanen(int lahanId, Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final panen = await _api.inputPanen(lahanId, data);
      _riwayat.insert(0, panen); notifyListeners();
      return panen;
    } catch (e) {
      _error = e.toString(); notifyListeners(); return null;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> fetchAnalisa(int lahanId, int panenId) async {
    try {
      _lastAnalisa = await _api.getAnalisa(lahanId, panenId);
      notifyListeners();
    } catch (_) {}
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/services/ frontend/lib/providers/
git commit -m "feat: add Provider state management and update ApiService"
```

---

## Task 4: go_router & main.dart

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/router.dart`

- [ ] **Step 1: Create lib/router.dart**

```dart
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/lahan/daftar_lahan_screen.dart';
import 'screens/lahan/tambah_lahan_screen.dart';
import 'screens/lahan/detail_lahan_screen.dart';
import 'screens/panen/input_panen_screen.dart';
import 'screens/panen/hasil_analisa_screen.dart';

GoRouter createRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final onPublic = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/splash';
    if (!loggedIn && !onPublic) return '/login';
    if (loggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/', builder: (c, s) => const MainScreen()),
    GoRoute(path: '/lahan', builder: (c, s) => const DaftarLahanScreen()),
    GoRoute(path: '/lahan/tambah', builder: (c, s) => const TambahLahanScreen()),
    GoRoute(path: '/lahan/:id', builder: (c, s) => DetailLahanScreen(lahanId: int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/lahan/:id/panen', builder: (c, s) => InputPanenScreen(lahanId: int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/analisa', builder: (c, s) => HasilAnalisaScreen(panen: s.extra as dynamic)),
  ],
);
```

- [ ] **Step 2: Update lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lahan_provider.dart';
import 'providers/panen_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SawitKuApp());
}

class SawitKuApp extends StatelessWidget {
  const SawitKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => LahanProvider()),
        ChangeNotifierProvider(create: (_) => PanenProvider()),
      ],
      child: Builder(builder: (context) {
        final auth = context.watch<AuthProvider>();
        return MaterialApp.router(
          title: 'SawitKu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          routerConfig: createRouter(auth),
        );
      }),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/main.dart frontend/lib/router.dart
git commit -m "feat: add go_router and MultiProvider setup"
```

---

## Task 5: Auth Screens

**Files:**
- Create: `lib/screens/auth/login_screen.dart`
- Create: `lib/screens/auth/register_screen.dart`
- Update: `lib/screens/splash_screen.dart`

- [ ] **Step 1: Create lib/screens/auth/login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) { context.go('/'); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Login gagal'), backgroundColor: AppColors.danger)); }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 48),
            Text('Selamat Datang', style: AppTextStyles.display(32)),
            const SizedBox(height: 8),
            Text('Masuk ke akun SawitKu Anda', style: AppTextStyles.body(14, color: AppColors.textMuted)),
            const SizedBox(height: 40),
            AppInputField(label: '📧  Email', hint: 'petani@email.com', controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            AppInputField(label: '🔒  Password', hint: '••••••••', controller: _passCtrl,
                obscureText: _obscure,
                suffix: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: AppColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure))),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Masuk', onTap: _login, loading: loading),
            const SizedBox(height: 16),
            Center(child: GestureDetector(
              onTap: () => context.go('/register'),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: 'Belum punya akun? ', style: AppTextStyles.body(13, color: AppColors.textMuted)),
                TextSpan(text: 'Daftar sekarang', style: AppTextStyles.body(13, color: AppColors.primary, weight: FontWeight.w600)),
              ])),
            )),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create lib/screens/auth/register_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text, phone: _phoneCtrl.text.trim());
    if (!mounted) return;
    if (ok) { context.go('/'); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Gagal'), backgroundColor: AppColors.danger)); }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Akun'), backgroundColor: Colors.transparent, foregroundColor: AppColors.primary, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            AppInputField(label: '👤  Nama Lengkap', hint: 'Budi Santoso', controller: _nameCtrl),
            const SizedBox(height: 20),
            AppInputField(label: '📧  Email', hint: 'budi@email.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            AppInputField(label: '📱  No. HP (opsional)', hint: '08123456789', controller: _phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            AppInputField(label: '🔒  Password', hint: 'Min. 6 karakter', controller: _passCtrl, obscureText: true),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Daftar Sekarang', onTap: _register, loading: loading),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text('Sudah punya akun? Masuk', style: AppTextStyles.body(13, color: AppColors.primary, weight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update lib/screens/splash_screen.dart** (tambah auth check)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.go(auth.isLoggedIn ? '/' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('🌴', style: TextStyle(fontSize: 80)),
      const SizedBox(height: 16),
      Text('SawitKu', style: AppTextStyles.display(36, color: Colors.white)),
      const SizedBox(height: 8),
      Text('Kelola Kebun, Optimalkan Panen', style: AppTextStyles.body(14, color: Colors.white70)),
    ])),
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/screens/auth/ frontend/lib/screens/splash_screen.dart
git commit -m "feat: add login/register screens and update splash with auth routing"
```

---

## Task 6: Lahan Screens

**Files:**
- Create: `lib/screens/lahan/daftar_lahan_screen.dart`
- Create: `lib/screens/lahan/tambah_lahan_screen.dart`
- Create: `lib/screens/lahan/detail_lahan_screen.dart`
- Create: `lib/widgets/lahan_card.dart`

- [ ] **Step 1: Create lib/widgets/lahan_card.dart**

```dart
import 'package:flutter/material.dart';
import '../models/lahan_model.dart';
import '../theme/app_theme.dart';

class LahanCard extends StatelessWidget {
  final LahanModel lahan;
  final VoidCallback onTap;

  const LahanCard({super.key, required this.lahan, required this.onTap});

  Color get _statusColor {
    switch (lahan.statusTerkini) {
      case 'NORMAL': return AppColors.primary3;
      case 'WARN': return AppColors.warn;
      case 'DANGER': return AppColors.danger;
      default: return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (lahan.statusTerkini) {
      case 'NORMAL': return '✅ Normal';
      case 'WARN': return '⚠️ Perlu Perhatian';
      case 'DANGER': return '🚨 Kritis';
      default: return '📊 Belum ada data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('🌴', style: TextStyle(fontSize: 24)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lahan.namaLahan, style: AppTextStyles.body(15, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${lahan.luasHa} ha · Usia ${lahan.usiaPohon} thn · ${lahan.faseProduksi ?? ""}',
                style: AppTextStyles.body(12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel, style: AppTextStyles.body(11, color: _statusColor, weight: FontWeight.w600))),
          ])),
          Icon(Icons.chevron_right, color: AppColors.textLight),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Create lib/screens/lahan/daftar_lahan_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/lahan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lahan_card.dart';

class DaftarLahanScreen extends StatefulWidget {
  const DaftarLahanScreen({super.key});
  @override State<DaftarLahanScreen> createState() => _DaftarLahanScreenState();
}

class _DaftarLahanScreenState extends State<DaftarLahanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LahanProvider>().fetchLahans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LahanProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kebun Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/lahan/tambah'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Lahan', style: AppTextStyles.body(13, color: Colors.white, weight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<LahanProvider>().fetchLahans(),
        color: AppColors.primary,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : provider.lahans.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('🌱', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text('Belum ada lahan', style: AppTextStyles.body(16, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Tambah lahan pertama Anda', style: AppTextStyles.body(13, color: AppColors.textMuted)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.lahans.length,
                    itemBuilder: (_, i) => LahanCard(
                      lahan: provider.lahans[i],
                      onTap: () => context.push('/lahan/${provider.lahans[i].id}'),
                    ),
                  ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create lib/screens/lahan/tambah_lahan_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/lahan_provider.dart';
import '../../services/analisa_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TambahLahanScreen extends StatefulWidget {
  const TambahLahanScreen({super.key});
  @override State<TambahLahanScreen> createState() => _TambahLahanScreenState();
}

class _TambahLahanScreenState extends State<TambahLahanScreen> {
  final _namaCtrl = TextEditingController();
  final _luasCtrl = TextEditingController();
  final _usiaCtrl = TextEditingController();
  final _pohonCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  ({double min, double max, double mid, String fase})? get _preview {
    final luas = double.tryParse(_luasCtrl.text);
    final usia = int.tryParse(_usiaCtrl.text);
    if (luas == null || usia == null) return null;
    return AnalisaService.getTarget(luas, usia);
  }

  Future<void> _submit() async {
    if (_namaCtrl.text.isEmpty || _luasCtrl.text.isEmpty || _usiaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama, luas, dan usia wajib diisi')));
      return;
    }
    final ok = await context.read<LahanProvider>().createLahan({
      'namaLahan': _namaCtrl.text.trim(),
      'luasHa': double.parse(_luasCtrl.text),
      'usiaPohon': int.parse(_usiaCtrl.text),
      'jumlahPohon': _pohonCtrl.text.isNotEmpty ? int.parse(_pohonCtrl.text) : null,
      'lokasi': _lokasiCtrl.text.trim(),
      'catatan': _catatanCtrl.text.trim(),
    });
    if (!mounted) return;
    if (ok) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lahan berhasil ditambahkan'))); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<LahanProvider>().error ?? 'Gagal'), backgroundColor: AppColors.danger)); }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final loading = context.watch<LahanProvider>().loading;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tambah Lahan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          AppCard(child: Column(children: [
            AppInputField(label: '🌴  Nama Lahan', hint: 'Lahan A / Kebun Utara', controller: _namaCtrl),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: AppInputField(label: '📐  Luas (ha)', hint: '2.0', controller: _luasCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: AppInputField(label: '🌳  Usia (tahun)', hint: '8', controller: _usiaCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 20),
            if (preview != null) ...[
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Target Normal:', style: AppTextStyles.body(12, color: AppColors.primary3)),
                  Text('${preview.min.toStringAsFixed(1)}–${preview.max.toStringAsFixed(1)} ton/bln', style: AppTextStyles.body(13, color: AppColors.primary, weight: FontWeight.w700)),
                ])),
              const SizedBox(height: 20),
            ],
            AppInputField(label: '🔢  Jumlah Pohon (opsional)', hint: '50', controller: _pohonCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            AppInputField(label: '📍  Lokasi', hint: 'Padang Pariaman, Sumbar', controller: _lokasiCtrl),
            const SizedBox(height: 20),
            AppInputField(label: '📝  Catatan', hint: 'Dekat sungai, dll...', controller: _catatanCtrl),
          ])),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Simpan Lahan', onTap: _submit, loading: loading),
        ]),
      ),
    );
  }

  @override
  void dispose() { _namaCtrl.dispose(); _luasCtrl.dispose(); _usiaCtrl.dispose(); _pohonCtrl.dispose(); _lokasiCtrl.dispose(); _catatanCtrl.dispose(); super.dispose(); }
}
```

- [ ] **Step 4: Create lib/screens/lahan/detail_lahan_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/lahan_model.dart';
import '../../providers/lahan_provider.dart';
import '../../providers/panen_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DetailLahanScreen extends StatefulWidget {
  final int lahanId;
  const DetailLahanScreen({super.key, required this.lahanId});
  @override State<DetailLahanScreen> createState() => _DetailLahanScreenState();
}

class _DetailLahanScreenState extends State<DetailLahanScreen> {
  LahanModel? _lahan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<PanenProvider>().fetchRiwayat(widget.lahanId);
  }

  Future<void> _load() async {
    try {
      _lahan = await ApiService().getLahanDetail(widget.lahanId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = context.watch<PanenProvider>().riwayat;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_lahan == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Lahan tidak ditemukan')));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_lahan!.namaLahan)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/lahan/${widget.lahanId}/panen'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Input Panen', style: AppTextStyles.body(13, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Info Lahan', style: AppTextStyles.body(13, color: AppColors.textMuted, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            _InfoRow('Luas', '${_lahan!.luasHa} hektar'),
            _InfoRow('Usia Pohon', '${_lahan!.usiaPohon} tahun (${_lahan!.faseProduksi ?? "-"})'),
            if (_lahan!.jumlahPohon != null) _InfoRow('Jumlah Pohon', '${_lahan!.jumlahPohon} pohon'),
            if (_lahan!.lokasi != null) _InfoRow('Lokasi', _lahan!.lokasi!),
          ])),
          const SizedBox(height: 16),
          Text('Riwayat Panen', style: AppTextStyles.body(15, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (riwayat.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Belum ada data panen', style: AppTextStyles.body(13, color: AppColors.textMuted))))
          else ...riwayat.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.bulan} ${p.tahun}', style: AppTextStyles.body(13, weight: FontWeight.w600)),
                Text('${p.tonAktual} ton (target ${p.targetMid.toStringAsFixed(1)})', style: AppTextStyles.body(12, color: AppColors.textMuted)),
              ]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.status == 'normal' ? AppColors.primaryTint : p.status == 'warn' ? AppColors.warnTint : AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.status.toUpperCase(), style: AppTextStyles.body(10, color: p.status == 'normal' ? AppColors.primary : p.status == 'warn' ? AppColors.warn : AppColors.danger, weight: FontWeight.w700))),
            ]),
          )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body(13, color: AppColors.textMuted)),
      Text(value, style: AppTextStyles.body(13, weight: FontWeight.w600)),
    ]),
  );
}
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/lahan/ frontend/lib/widgets/lahan_card.dart
git commit -m "feat: add lahan screens (daftar, tambah, detail)"
```

---

## Task 7: Update Panen & Analisa Screens

**Files:**
- Modify: `lib/screens/panen/input_panen_screen.dart`
- Modify: `lib/screens/panen/hasil_analisa_screen.dart`
- Modify: `lib/screens/main_screen.dart`
- Modify: `lib/screens/beranda_screen.dart`

- [ ] **Step 1: Update input_panen_screen.dart** (terima lahanId parameter, kirim ke backend)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/panen_provider.dart';
import '../../services/analisa_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class InputPanenScreen extends StatefulWidget {
  final int lahanId;
  const InputPanenScreen({super.key, required this.lahanId});
  @override State<InputPanenScreen> createState() => _InputPanenScreenState();
}

class _InputPanenScreenState extends State<InputPanenScreen> {
  final _tonCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String _bulan = 'April';
  int _tahun = 2025;
  int _bulanAngka = 4;
  bool _loading = false;

  final _bulanList = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];

  Future<void> _submit() async {
    if (_tonCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final panen = await context.read<PanenProvider>().inputPanen(widget.lahanId, {
      'bulan': _bulan, 'tahun': _tahun, 'bulanAngka': _bulanAngka,
      'tonAktual': double.parse(_tonCtrl.text),
      'catatan': _catatanCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (panen != null) { context.push('/analisa', extra: panen); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<PanenProvider>().error ?? 'Gagal'), backgroundColor: AppColors.danger)); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Input Panen')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        AppCard(child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📅  BULAN', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bulan,
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border))),
                items: _bulanList.asMap().entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.value))).toList(),
                onChanged: (v) { if (v != null) setState(() { _bulan = v; _bulanAngka = _bulanList.indexOf(v) + 1; }); },
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: AppInputField(label: '📅  TAHUN', hint: '2025', controller: TextEditingController(text: '$_tahun'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          AppInputField(label: '⚖️  Hasil Panen Aktual', hint: 'Contoh: 3.8', suffix: 'Ton', controller: _tonCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), highlight: true),
          const SizedBox(height: 20),
          AppInputField(label: '📝  Catatan', hint: 'Hujan lebat, dll...', controller: _catatanCtrl),
        ])),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Analisa Sekarang →', onTap: _tonCtrl.text.isNotEmpty ? _submit : null, loading: _loading),
      ]),
    ),
  );

  @override void dispose() { _tonCtrl.dispose(); _catatanCtrl.dispose(); super.dispose(); }
}
```

- [ ] **Step 2: Update hasil_analisa_screen.dart** (tampilkan analisa dari backend + polling jika PROCESSING)**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/analisa_model.dart';
import '../../models/panen_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HasilAnalisaScreen extends StatefulWidget {
  final PanenModel panen;
  const HasilAnalisaScreen({super.key, required this.panen});
  @override State<HasilAnalisaScreen> createState() => _HasilAnalisaScreenState();
}

class _HasilAnalisaScreenState extends State<HasilAnalisaScreen> {
  AnalisaModel? _analisa;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analisa = widget.panen.analisa;
    if (_analisa == null || _analisa!.status == 'PROCESSING') {
      _pollAnalisa();
    } else {
      _loading = false;
    }
  }

  void _pollAnalisa() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (widget.panen.id == null || widget.panen.lahanId == null) return;
      final result = await ApiService().getAnalisa(widget.panen.lahanId!, widget.panen.id!);
      if (result.status == 'DONE') {
        _timer?.cancel();
        if (mounted) setState(() { _analisa = result; _loading = false; });
      }
    });
  }

  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Color _severityColor(String s) => s == 'high' ? AppColors.danger : s == 'medium' ? AppColors.warn : AppColors.primary3;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Hasil Analisa AI')),
    body: _loading
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('AI sedang menganalisa...', style: AppTextStyles.body(14, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text('Biasanya 5–15 detik', style: AppTextStyles.body(12, color: AppColors.textLight)),
          ]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_analisa?.ringkasan != null) ...[
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary2]), borderRadius: BorderRadius.circular(16)),
                  child: Text(_analisa!.ringkasan!, style: AppTextStyles.body(14, color: Colors.white))),
                const SizedBox(height: 16),
              ],
              Text('Penyebab Utama', style: AppTextStyles.display(20)),
              const SizedBox(height: 12),
              ...(_analisa?.penyebab ?? []).map((p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: _severityColor(p.severity).withOpacity(0.3)), borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(p.title, style: AppTextStyles.body(13, weight: FontWeight.w700)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _severityColor(p.severity).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(p.severity.toUpperCase(), style: AppTextStyles.body(9, color: _severityColor(p.severity), weight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 6),
                    Text(p.detail, style: AppTextStyles.body(12, color: AppColors.textMid)),
                    if (p.estimasiDampak != null) ...[const SizedBox(height: 4), Text('Estimasi dampak: ${p.estimasiDampak}', style: AppTextStyles.body(11, color: AppColors.textMuted))],
                  ])),
                ]),
              )),
              if (_analisa?.prioritasTindakan != null) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.warnTint, border: Border.all(color: AppColors.warn.withOpacity(0.3)), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🎯 Prioritas Tindakan', style: AppTextStyles.body(13, color: AppColors.warn, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(_analisa!.prioritasTindakan!, style: AppTextStyles.body(13, color: AppColors.text)),
                  ])),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Kembali ke Lahan', onTap: () => context.pop()),
            ]),
          ),
  );
}
```

- [ ] **Step 3: Update main_screen.dart** (tambah tab Lahan)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'beranda_screen.dart';
import 'lahan/daftar_lahan_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _screens = const [BerandaScreen(), DaftarLahanScreen(), RiwayatScreen(), ProfilScreen()];
  final _labels = ['Beranda', 'Lahan', 'Riwayat', 'Profil'];
  final _icons = [Icons.home_outlined, Icons.terrain_outlined, Icons.history, Icons.person_outline];
  final _activeIcons = [Icons.home, Icons.terrain, Icons.history, Icons.person];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryTint,
      destinations: List.generate(4, (i) => NavigationDestination(
        icon: Icon(_icons[i], color: AppColors.textMuted),
        selectedIcon: Icon(_activeIcons[i], color: AppColors.primary),
        label: _labels[i],
      )),
    ),
  );
}
```

- [ ] **Step 4: Create lib/screens/profil_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userData;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          CircleAvatar(radius: 40, backgroundColor: AppColors.primaryTint, child: Text(user?['user']?['name']?.substring(0,1) ?? 'P', style: AppTextStyles.display(32, color: AppColors.primary))),
          const SizedBox(height: 12),
          Text(user?['user']?['name'] ?? '-', style: AppTextStyles.display(20)),
          Text(user?['user']?['email'] ?? '-', style: AppTextStyles.body(13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(20)),
            child: Text('Paket ${user?['subscription']?['paket'] ?? 'GRATIS'}', style: AppTextStyles.body(13, color: AppColors.primary, weight: FontWeight.w700))),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: Text('Keluar', style: AppTextStyles.body(14, color: AppColors.danger, weight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          )),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 5: Flutter analyze**

```bash
cd /d/sawit_app/frontend
flutter analyze
```

Expected: No issues (atau hanya warnings minor)

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/screens/ frontend/lib/widgets/
git commit -m "feat: update all Flutter screens for multi-lahan + backend integration"
```

---

## Checklist Flutter Complete

- [ ] `flutter pub get` sukses
- [ ] `flutter analyze` no errors
- [ ] Splash → Login/Register routing bekerja
- [ ] Login dengan akun backend berhasil
- [ ] Daftar Lahan tampil dari API
- [ ] Tambah Lahan berhasil (dengan preview target)
- [ ] Input Panen per lahan berhasil
- [ ] Hasil Analisa tampil (polling jika PROCESSING)
- [ ] Bottom nav 4 tab: Beranda / Lahan / Riwayat / Profil
- [ ] Logout bersih
