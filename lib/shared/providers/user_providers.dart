import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../providers/repository_providers.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../core/network/api_client.dart';

final userProfileProvider = FutureProvider<User>((ref) async {
  ref.watch(authControllerProvider);
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getProfile();
});

final userOrdersProvider = FutureProvider((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getBuyerOrders();
});

final userWishlistProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/profile/wishlist');
  return (response.data as List).map((p) => Product.fromMap(p)).toList();
});

final userReviewsProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/profile/reviews');
  return response.data as List;
});
