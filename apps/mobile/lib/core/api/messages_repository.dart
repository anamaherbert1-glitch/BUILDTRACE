import 'package:dio/dio.dart';
import 'api_client.dart';

class MessagesRepository {
  final ApiClient _api;

  MessagesRepository(this._api);

  Future<List<dynamic>> getConversations() async {
    try {
      final res = await _api.dio.get('/messages/conversations');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<List<dynamic>> getThread(String partnerId) async {
    try {
      final res = await _api.dio.get('/messages/thread/$partnerId');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<Map<String, dynamic>> send({
    required String receiverId,
    required String content,
    String? materialId,
  }) async {
    try {
      final res = await _api.dio.post('/messages', data: {
        'receiverId': receiverId,
        'content': content,
        if (materialId != null) 'materialId': materialId,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _api.dio.get('/messages/unread-count');
      return (res.data as num).toInt();
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
