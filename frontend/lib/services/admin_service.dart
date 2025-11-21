import 'package:dio/dio.dart';
import 'api_service.dart';

class AdminService {
  final Dio _dio = ApiService().dio;

  // Users
  Future<List<dynamic>> getUsers() async {
    final resp = await _dio.get('/api/admin/users');
    return resp.data as List<dynamic>;
  }

  Future<dynamic> createUser(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/api/admin/users', data: payload);
    return resp.data;
  }

  Future<dynamic> updateUser(String id, Map<String, dynamic> payload) async {
    final resp = await _dio.put('/api/admin/users/$id', data: payload);
    return resp.data;
  }

  Future<dynamic> deleteUser(String id) async {
    final resp = await _dio.delete('/api/admin/users/$id');
    return resp.data;
  }

  // Products
  Future<List<dynamic>> getProducts() async {
    final resp = await _dio.get('/api/admin/products');
    return resp.data as List<dynamic>;
  }

  Future<dynamic> createProduct(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/api/admin/products', data: payload);
    return resp.data;
  }

  Future<dynamic> updateProduct(String id, Map<String, dynamic> payload) async {
    final resp = await _dio.put('/api/admin/products/$id', data: payload);
    return resp.data;
  }

  Future<dynamic> deleteProduct(String id) async {
    final resp = await _dio.delete('/api/admin/products/$id');
    return resp.data;
  }

  // Stocks
  Future<List<dynamic>> getStocks() async {
    final resp = await _dio.get('/api/admin/stocks');
    return resp.data as List<dynamic>;
  }

  /// Alias that returns all stocks (keeps naming per feature request)
  Future<List<dynamic>> getAllStocks() async => await getStocks();

  /// Update stock. This method accepts either:
  /// - (String productId, Map payload) as before, or
  /// - (int productId, int newQty) to set absolute quantity.
  Future<dynamic> updateStock(dynamic productId, dynamic payloadOrQty) async {
    Object payload;
    String pid = productId.toString();
    if (payloadOrQty is int) {
      payload = {'quantity': payloadOrQty};
    } else if (payloadOrQty is Map<String, dynamic>) {
      payload = payloadOrQty;
    } else {
      throw ArgumentError('payloadOrQty must be int or Map<String, dynamic>');
    }

    final resp = await _dio.put('/api/admin/stocks/$pid', data: payload);
    return resp.data;
  }

  // Sells
  Future<List<dynamic>> getSells() async {
    final resp = await _dio.get('/api/admin/sells');
    return resp.data as List<dynamic>;
  }

  // Dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final resp = await _dio.get('/api/admin/dashboard-summary');
    return (resp.data ?? {}) as Map<String, dynamic>;
  }
}
