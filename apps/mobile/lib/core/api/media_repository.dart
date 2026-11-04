import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class MediaRepository {
  final ApiClient _api;

  MediaRepository(this._api);

  Future<Map<String, dynamic>> uploadMaterialPhoto({
    required String materialId,
    required File file,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final res = await _api.dio.post(
        '/media/materials/$materialId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<dynamic>> listForMaterial(String materialId) async {
    try {
      final res = await _api.dio.get('/media/materials/$materialId');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> delete(String mediaId) async {
    try {
      await _api.dio.delete('/media/$mediaId');
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
    return 'Erreur upload';
  }
}
