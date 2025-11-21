import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class AuthService {
  final Dio _dio;
  final String baseUrl;

  AuthService({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        baseUrl = baseUrl ?? API_BASE_URL;

  /// Calls POST /api/auth/login and returns the token string on success.
  /// Throws an Exception with a message on failure.
  Future<String> login(String email, String password) async {
    final url = '$baseUrl/api/auth/login';
    try {
      final resp =
          await _dio.post(url, data: {'email': email, 'password': password});
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data != null && data['token'] != null) {
          return data['token'] as String;
        }
        throw Exception('Token tidak ditemukan pada response');
      }

      throw Exception(resp.data != null && resp.data['message'] != null
          ? resp.data['message']
          : 'Login gagal');
    } on DioException catch (e) {
      if (e.response != null) {
        final r = e.response!;
        final msg = (r.data is Map && r.data['message'] != null)
            ? r.data['message']
            : r.statusMessage;
        throw Exception(msg ?? 'Login gagal (server)');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Calls POST /api/auth/logout (optional) and clears stored JWT
  Future<void> logout() async {
    final url = '$baseUrl/api/auth/logout';
    try {
      await _dio.post(url);
    } catch (_) {
      // ignore network errors on logout
    }

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt');
  }
}
