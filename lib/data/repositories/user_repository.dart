import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/user.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      if (response.statusCode == 200) {
        return User.fromMap(response.data);
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data, {String? imagePath}) async {
    try {
      dynamic requestData;
      if (imagePath != null) {
        requestData = FormData.fromMap({
          ...data,
          'avatar': await MultipartFile.fromFile(imagePath),
        });
      } else {
        requestData = data;
      }

      final response = await _apiClient.put(ApiEndpoints.profile, data: requestData);
      if (response.statusCode == 200) {
        return User.fromMap(response.data);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }
}
