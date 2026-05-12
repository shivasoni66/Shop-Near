import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/seller.dart';
import '../../shared/models/product.dart';

class SellerRepository {
  final ApiClient _apiClient;

  SellerRepository(this._apiClient);

  Future<List<Seller>> getAllSellers() async {
    try {
      final response = await _apiClient.get('/sellers');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Seller.fromMap(item)).toList();
      }
      throw Exception('Failed to load sellers');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await _apiClient.get('/sellers/analytics');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load analytics');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getSellerProducts() async {
    try {
      final response = await _apiClient.get('/sellers/products');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      throw Exception('Failed to load seller products');
    } catch (e) {
      rethrow;
    }
  }
}
