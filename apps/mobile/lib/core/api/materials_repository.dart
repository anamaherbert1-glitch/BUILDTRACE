import 'package:dio/dio.dart';
import 'api_client.dart';

class MaterialsRepository {
  final ApiClient _api;

  MaterialsRepository(this._api);

  Future<List<dynamic>> list({String? category, String? city, int skip = 0, int take = 20}) async {
    try {
      final res = await _api.dio.get('/materials', queryParameters: {
        if (category != null) 'category': category,
        if (city != null) 'city': city,
        'skip': skip,
        'take': take,
      });
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }


  Future<List<dynamic>> findMine() async {
    try {
      final res = await _api.dio.get('/materials/mine');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    try {
      final res = await _api.dio.get('/materials/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/materials', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> publish(String id) async {
    try {
      final res = await _api.dio.patch('/materials/$id/publish');
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
