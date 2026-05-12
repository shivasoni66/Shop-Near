import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/repository_providers.dart';
import '../../core/network/socket_service.dart';
import '../../data/repositories/product_repository.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final Ref _ref;
  final ProductRepository _repository;

  ProductNotifier(this._ref, this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await fetchAll();
    _setupSocket();
  }

  Future<void> fetchAll() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getAllProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createProduct(Map<String, dynamic> data, List<String> imagePaths) async {
    try {
      final newProduct = await _repository.createProduct(data, imagePaths);
      state.whenData((products) {
        if (!products.any((p) => p.id == newProduct.id)) {
          state = AsyncValue.data([newProduct, ...products]);
        }
      });
    } catch (e) {
      rethrow; 
    }
  }

  void _setupSocket() {
    final socketService = _ref.read(socketServiceProvider);
    socketService.on('product_update', (data) {
      if (data['action'] == 'created') {
        final newProduct = Product.fromMap(data['product']);
        state.whenData((products) {
          if (!products.any((p) => p.id == newProduct.id)) {
            state = AsyncValue.data([newProduct, ...products]);
          }
        });
      }
    });
  }
}

final productsProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(ref, repository);
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProductById(id);
});

final categoryProductsProvider = FutureProvider.family<List<Product>, String>((ref, category) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProductsByCategory(category);
});

final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(productRepositoryProvider);
  return await repository.searchProducts(query);
});

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getAllCategories();
});
