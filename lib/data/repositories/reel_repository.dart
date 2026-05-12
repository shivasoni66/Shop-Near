import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> uploadReel(XFile videoFile, String caption) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.name,
        ),
        'caption': caption,
      });

      final response = await _apiClient.post(ApiEndpoints.reels, data: formData);
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to upload reel: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      }
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeReel(String reelId) async {
    try {
      await _apiClient.post('${ApiEndpoints.reels}/$reelId/like');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> commentOnReel(String reelId, String text) async {
    try {
      await _apiClient.post('${ApiEndpoints.reels}/$reelId/comment', data: {'text': text});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getReelComments(String reelId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.reels}/$reelId/comments');
      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
