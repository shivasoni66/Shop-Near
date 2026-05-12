import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/live_session.dart';

class LiveSessionRepository {
  final ApiClient _apiClient;

  LiveSessionRepository(this._apiClient);

  Future<List<LiveSession>> getLiveSessions() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.live);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => LiveSession.fromMap(item)).toList();
      }
      throw Exception('Failed to load live sessions');
    } catch (e) {
      rethrow;
    }
  }

  Future<LiveSession> startLiveSession(String title, String category) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.live, data: {
        'title': title,
        'category': category,
      });
      if (response.statusCode == 201) {
        return LiveSession.fromMap(response.data);
      }
      throw Exception('Failed to start live session');
    } catch (e) {
      rethrow;
    }
  }
}
