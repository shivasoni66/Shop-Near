import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/reel.dart';

class ReelRepository {
  final ApiClient _apiClient;

  ReelRepository(this._apiClient);

  Future<List<Reel>> getAllReels() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.reels);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Reel.fromMap(item)).toList();
      }
      throw Exception('Failed to load reels');
    } catch (e) {
      rethrow;
    }
  }
}
