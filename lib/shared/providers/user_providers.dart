import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'repository_providers.dart';
import '../../features/auth/providers/auth_notifier.dart';

final userProfileProvider = FutureProvider<User>((ref) async {
  // Watch auth status to re-fetch profile when user changes
  final authState = ref.watch(authControllerProvider);
  
  if (authState.status != AuthStatus.authenticated) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(userRepositoryProvider);
  return await repository.getProfile();
});

final userOrdersProvider = FutureProvider((ref) {
  ref.watch(authControllerProvider);
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getBuyerOrders();
});

final userWishlistProvider = AsyncNotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});

class WishlistNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(userRepositoryProvider);
    return await repository.getWishlist();
  }

  Future<void> toggle(String productId) async {
    final repository = ref.read(userRepositoryProvider);
    final isAdded = await repository.toggleWishlist(productId);
    
    // Refresh the list from the server to ensure consistency
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getWishlist());
  }

  bool isWishlisted(String productId) {
    if (state.asData == null) return false;
    return state.asData!.value.any((p) => p.id == productId);
  }
}

final userReviewsProvider = FutureProvider((ref) async {
  ref.watch(authControllerProvider);
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/profile/reviews');
  return response.data as List;
});
