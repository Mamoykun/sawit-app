import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panen_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // ganti dengan IP server production

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor — inject token JWT otomatis
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ─── AUTH ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return res.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── PANEN ───────────────────────────────────────────────────────────────

  /// Kirim data panen ke backend, dapat hasil analisa
  Future<HasilAnalisa> inputPanen(PanenModel panen) async {
    final res = await _dio.post('/panen/analisa', data: panen.toJson());
    final data = res.data;

    final panenResult = PanenModel.fromJson(data['panen']);
    final penyebab = (data['penyebab'] as List)
        .map((p) => AnalisaPenyebab.fromJson(p))
        .toList();

    return HasilAnalisa(panen: panenResult, penyebab: penyebab);
  }

  /// Ambil riwayat panen user (misal 6 bulan terakhir)
  Future<List<PanenModel>> getRiwayat({int limit = 7}) async {
    final res = await _dio.get('/panen/riwayat', queryParameters: {'limit': limit});
    return (res.data as List).map((e) => PanenModel.fromJson(e)).toList();
  }

  /// Ambil summary beranda
  Future<Map<String, dynamic>> getBeranda() async {
    final res = await _dio.get('/panen/beranda');
    return res.data;
  }
}
