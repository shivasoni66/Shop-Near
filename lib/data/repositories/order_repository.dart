import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/order.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<List<Order>> getOrders() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.orders);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Order.fromMap(item)).toList();
      }
      throw Exception('Failed to load orders');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getBuyerOrders() => getOrders();

  Future<Order> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.orders, data: orderData);
      if (response.statusCode == 201) {
        return Order.fromMap(response.data);
      }
      throw Exception('Failed to place order');
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> updateOrderStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch('${ApiEndpoints.orders}/$id/status', data: {'status': status});
      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      }
      throw Exception('Failed to update order status');
    } catch (e) {
      rethrow;
    }
  }
}
