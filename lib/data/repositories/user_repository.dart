import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/user.dart';
import '../../shared/models/product.dart';

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

  Future<User> updateProfile(Map<String, dynamic> data,
      {String? imagePath}) async {
    try {
      dynamic requestData;
      if (imagePath != null) {
        requestData = FormData.fromMap({
          ...data,
          'avatar': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split(RegExp(r'[/\\]')).last,
          ),
        });
      } else {
        requestData = data;
      }

      final response =
          await _apiClient.put(ApiEndpoints.profile, data: requestData);
      if (response.statusCode == 200) {
        return User.fromMap(response.data);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getWishlist() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.profile}/wishlist');
      if (response.statusCode == 200) {
        return (response.data as List).map((p) => Product.fromMap(p)).toList();
      }
      throw Exception('Failed to load wishlist');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> toggleWishlist(String productId) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.profile}/wishlist/toggle',
        data: {'productId': productId},
      );
      if (response.statusCode == 200) {
        // Returns true if added, false if removed
        return response.data['isWishlisted'] ?? false;
      }
      throw Exception('Failed to toggle wishlist');
    } catch (e) {
      rethrow;
    }
  }
}
