import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/cart_item.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository(this._apiClient);

  Future<List<CartItem>> getCart() async {
    try {
      final response = await _apiClient.get('/cart');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => CartItem.fromMap(item)).toList();
      }
      throw Exception('Failed to load cart');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      await _apiClient.post('/cart', data: {'productId': productId, 'quantity': quantity});
    } catch (e) {
      rethrow;
    }
  }
}
