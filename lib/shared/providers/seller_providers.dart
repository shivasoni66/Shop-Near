import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../models/seller.dart';
import '../models/product.dart';

final sellersProvider = FutureProvider<List<Seller>>((ref) async {
  final repository = ref.watch(sellerRepositoryProvider);
  return await repository.getAllSellers();
});

final selectedAnalyticsPeriodProvider = StateProvider<String>((ref) => 'Week');

final sellerAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(authControllerProvider); // Re-fetch on login/logout
  final period = ref.watch(selectedAnalyticsPeriodProvider);
  final repository = ref.watch(sellerRepositoryProvider);
  return await repository.getAnalytics(period: period.toLowerCase());
});

final sellerProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(authControllerProvider); // Re-fetch on login/logout
  final repository = ref.watch(sellerRepositoryProvider);
  return await repository.getSellerProducts();
});
