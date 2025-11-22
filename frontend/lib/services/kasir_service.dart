import 'package:dio/dio.dart';
import 'api_service.dart';

class KasirService {
  final Dio _dio = ApiService().dio;

  /// GET /api/kasir/dashboard
  Future<List<dynamic>> getDashboard() async {
    final resp = await _dio.get('/api/kasir/dashboard');
    return (resp.data ?? []) as List<dynamic>;
  }

  /// GET /api/kasir/stocks
  Future<List<dynamic>> getStocks() async {
    final resp = await _dio.get('/api/kasir/stocks');
    return (resp.data ?? []) as List<dynamic>;
  }

  /// PUT /api/kasir/stocks/:productId with body { quantity }
  Future<dynamic> updateStock(dynamic productId, int newQty) async {
    final pid = productId.toString();
    final resp =
        await _dio.put('/api/kasir/stocks/$pid', data: {'quantity': newQty});
    return resp.data;
  }
}
