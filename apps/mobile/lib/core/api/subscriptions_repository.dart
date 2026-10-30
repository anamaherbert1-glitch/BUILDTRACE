import 'package:dio/dio.dart';
import 'api_client.dart';

class SubscriptionsRepository {
  final ApiClient _api;

  SubscriptionsRepository(this._api);

  Future<List<dynamic>> getPlans() async {
    try {
      final res = await _api.dio.get('/subscriptions/plans');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> getMine() async {
    try {
      final res = await _api.dio.get('/subscriptions/me');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> checkout(String plan) async {
    try {
      final res = await _api.dio.post('/subscriptions/checkout', data: {'plan': plan});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  String _err(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      return msg is List ? msg.join(', ') : msg.toString();
    }
    return 'Erreur réseau';
  }
}
