import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import 'repository_providers.dart';
import '../../features/auth/providers/auth_notifier.dart';

final sellerOrdersProvider = FutureProvider<List<Order>>((ref) async {
  ref.watch(authControllerProvider);
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrders();
});

final orderDetailsProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final orders = await repository.getOrders();
  return orders.firstWhere((o) => o.id == orderId);
});
