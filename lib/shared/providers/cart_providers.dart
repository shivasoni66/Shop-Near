import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import 'repository_providers.dart';

class CartNotifier extends AsyncNotifier<List<CartItem>> {
  @override
  Future<List<CartItem>> build() async {
    final repository = ref.watch(cartRepositoryProvider);
    return await repository.getCart();
  }

  Future<void> addItem(String productId, int quantity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cartRepositoryProvider);
      await repository.addToCart(productId, quantity);
      return await repository.getCart();
    });
  }

  Future<void> updateQty(String itemId, int quantity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cartRepositoryProvider);
      if (quantity <= 0) {
        await repository.removeFromCart(itemId);
      } else {
        await repository.updateQuantity(itemId, quantity);
      }
      return await repository.getCart();
    });
  }

  Future<void> removeItem(String itemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cartRepositoryProvider);
      await repository.removeFromCart(itemId);
      return await repository.getCart();
    });
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cartRepositoryProvider);
      await repository.clearCart();
      return [];
    });
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
