import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../models/biaya_model.dart';
import '../models/diagnosa_model.dart';
import '../models/payment_model.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class ApiService {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          await prefs.remove('user_name');
          await prefs.remove('user_paket');
          await prefs.remove('selected_lahan_id');
          await appDb.clearAllData();
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        handler.next(err);
      },
    ));
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    final body = res.data['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', body['token']);
    await prefs.setString('user_name', body['user']['name'] ?? '');
    await prefs.setString('user_paket', body['subscription']?['paket'] ?? 'GRATIS');
    return body;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String? phone) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final body = res.data['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', body['token']);
    await prefs.setString('user_name', body['user']['name'] ?? '');
    await prefs.setString('user_paket', body['subscription']?['paket'] ?? 'GRATIS');
    return body;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_paket');
    await prefs.remove('selected_lahan_id');
    // Wipe local SQLite cache so the next user does not see this user's data.
    await appDb.clearAllData();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // ─── LAHAN ────────────────────────────────────────────────────────────────

  Future<List<LahanModel>> getMyLahan() async {
    final res = await _dio.get('/lahan');
    final list = res.data['data'] as List;
    return list.map((e) => LahanModel.fromJson(e)).toList();
  }

  Future<LahanModel> createLahan({
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    final res = await _dio.post('/lahan', data: {
      'namaLahan': namaLahan,
      'luasHa': luasHa,
      'tahunTanam': tahunTanam,
      if (jumlahPohon != null) 'jumlahPohon': jumlahPohon,
      if (lokasi != null && lokasi.isNotEmpty) 'lokasi': lokasi,
    });
    return LahanModel.fromJson(res.data['data']);
  }

  Future<LahanModel> updateLahan(int lahanId, {
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    final res = await _dio.put('/lahan/$lahanId', data: {
      'namaLahan': namaLahan,
      'luasHa': luasHa,
      'tahunTanam': tahunTanam,
      if (jumlahPohon != null) 'jumlahPohon': jumlahPohon,
      if (lokasi != null && lokasi.isNotEmpty) 'lokasi': lokasi,
    });
    return LahanModel.fromJson(res.data['data']);
  }

  Future<void> deleteLahan(int lahanId) async {
    await _dio.delete('/lahan/$lahanId');
  }

  // ─── PANEN ────────────────────────────────────────────────────────────────

  Future<PanenModel> inputPanen(int lahanId, {
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required int tanggal,
    required double tonAktual,
    double hargaPerTon = 2400000,
    String? catatan,
  }) async {
    final res = await _dio.post('/lahan/$lahanId/panen', data: {
      'bulan': bulan,
      'tahun': tahun,
      'bulanAngka': bulanAngka,
      'tanggal': tanggal,
      'tonAktual': tonAktual,
      'hargaPerTon': hargaPerTon,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    });
    return PanenModel.fromJson(res.data['data']);
  }

  Future<void> deletePanen(int lahanId, int panenId) async {
    await _dio.delete('/lahan/$lahanId/panen/$panenId');
  }

  Future<PanenModel> updatePanen(int lahanId, int panenId, {
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required int tanggal,
    required double tonAktual,
    double hargaPerTon = 2400000,
  }) async {
    final res = await _dio.put('/lahan/$lahanId/panen/$panenId', data: {
      'bulan': bulan,
      'tahun': tahun,
      'bulanAngka': bulanAngka,
      'tanggal': tanggal,
      'tonAktual': tonAktual,
      'hargaPerTon': hargaPerTon,
    });
    return PanenModel.fromJson(res.data['data']);
  }

  Future<List<PanenModel>> getRiwayat(int lahanId, {int limit = 7}) async {
    final res = await _dio.get('/lahan/$lahanId/panen',
        queryParameters: {'limit': limit});
    final list = res.data['data'] as List;
    return list.map((e) => PanenModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getBeranda() async {
    final res = await _dio.get('/beranda');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/users/me');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    final res = await _dio.put('/users/me', data: {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', data['name'] ?? '');
    return data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Permanently delete account (PDP — right to erasure).
  Future<void> deleteAccount({required String confirmPassword}) async {
    await _dio.delete('/users/me', data: {
      'confirmPassword': confirmPassword,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Export user data (PDP — right to data portability).
  Future<Map<String, dynamic>> exportMyData() async {
    final res = await _dio.get('/users/me/export');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ─── BIAYA OPERASIONAL ────────────────────────────────────────────────────

  Future<List<BiayaModel>> getBiaya(int lahanId, {int? tahun}) async {
    final res = await _dio.get('/lahan/$lahanId/biaya',
        queryParameters: tahun != null ? {'tahun': tahun} : null);
    final list = res.data['data'] as List;
    return list.map((e) => BiayaModel.fromJson(e)).toList();
  }

  Future<BiayaModel> createBiaya(int lahanId, {
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required String kategoriCode,
    required double jumlah,
    String? keterangan,
  }) async {
    final res = await _dio.post('/lahan/$lahanId/biaya', data: {
      'bulan': bulan,
      'tahun': tahun,
      'bulanAngka': bulanAngka,
      'kategori': kategoriCode,
      'jumlah': jumlah,
      if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
    });
    return BiayaModel.fromJson(res.data['data']);
  }

  Future<BiayaModel> updateBiaya(int lahanId, int biayaId, {
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required String kategoriCode,
    required double jumlah,
    String? keterangan,
  }) async {
    final res = await _dio.put('/lahan/$lahanId/biaya/$biayaId', data: {
      'bulan': bulan,
      'tahun': tahun,
      'bulanAngka': bulanAngka,
      'kategori': kategoriCode,
      'jumlah': jumlah,
      if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
    });
    return BiayaModel.fromJson(res.data['data']);
  }

  Future<void> deleteBiaya(int lahanId, int biayaId) async {
    await _dio.delete('/lahan/$lahanId/biaya/$biayaId');
  }

  // ─── DIAGNOSA VISUAL AI ───────────────────────────────────────────────────

  Future<DiagnosaModel> analyzeDiagnosa(int lahanId, {
    required List<int> imageBytes,
    required String filename,
    required String jenisCode,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      'jenis': jenisCode,
    });
    final res = await _dio.post(
      '/lahan/$lahanId/diagnosa/visual',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return DiagnosaModel.fromJson(res.data['data']);
  }

  Future<List<DiagnosaModel>> getDiagnosaHistory(int lahanId, {int limit = 20}) async {
    final res = await _dio.get('/lahan/$lahanId/diagnosa',
        queryParameters: {'limit': limit});
    final list = res.data['data'] as List;
    return list.map((e) => DiagnosaModel.fromJson(e)).toList();
  }

  Future<DiagnosaModel> getDiagnosaDetail(int lahanId, int diagnosaId) async {
    final res = await _dio.get('/lahan/$lahanId/diagnosa/$diagnosaId');
    return DiagnosaModel.fromJson(res.data['data']);
  }

  Future<void> deleteDiagnosa(int lahanId, int diagnosaId) async {
    await _dio.delete('/lahan/$lahanId/diagnosa/$diagnosaId');
  }

  // ─── PAYMENTS / SUBSCRIPTION ──────────────────────────────────────────────

  Future<PaymentModel> createPayment({
    required String targetPaket, // 'PETANI' | 'PRO'
    required int durationMonths,
  }) async {
    final res = await _dio.post('/payments/create', data: {
      'targetPaket': targetPaket,
      'durationMonths': durationMonths,
    });
    return PaymentModel.fromJson(res.data['data']);
  }

  Future<List<PaymentModel>> getMyPayments() async {
    final res = await _dio.get('/payments/me');
    final list = res.data['data'] as List;
    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }

  Future<PaymentModel> getPaymentByOrderId(String orderId) async {
    final res = await _dio.get('/payments/order/$orderId');
    return PaymentModel.fromJson(res.data['data']);
  }
}
