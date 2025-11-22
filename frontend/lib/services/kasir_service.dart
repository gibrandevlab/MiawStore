import 'package:dio/dio.dart';
import 'api_service.dart';

class KasirService {
  final Dio _dio = ApiService().dio;

  Future<List<dynamic>> getDashboard() async {
    final resp = await _dio.get('/api/kasir/dashboard');
    return (resp.data ?? []) as List<dynamic>;
  }

  Future<List<dynamic>> getStocks() async {
    final resp = await _dio.get('/api/kasir/stocks');
    return (resp.data ?? []) as List<dynamic>;
  }

  Future<dynamic> updateStock(dynamic productId, int newQty) async {
    final pid = productId.toString();
    final resp =
        await _dio.put('/api/kasir/stocks/$pid', data: {'quantity': newQty});
    return resp.data;
  }
}
