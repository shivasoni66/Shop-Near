import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/repository_providers.dart';

enum ProductStatus { initial, loading, loaded, error, creating, created }

class ProductState {
  final ProductStatus status;
  final List<Product> products;
  final String? errorMessage;

  ProductState({
    required this.status,
    this.products = const [],
    this.errorMessage,
  });

  factory ProductState.initial() => ProductState(status: ProductStatus.initial);
  factory ProductState.loading() => ProductState(status: ProductStatus.loading);
  factory ProductState.loaded(List<Product> products) => ProductState(status: ProductStatus.loaded, products: products);
  factory ProductState.error(String message) => ProductState(status: ProductStatus.error, errorMessage: message);
  factory ProductState.creating(List<Product> currentProducts) => ProductState(status: ProductStatus.creating, products: currentProducts);
  factory ProductState.created(List<Product> updatedProducts) => ProductState(status: ProductStatus.created, products: updatedProducts);
}

class ProductNotifier extends StateNotifier<ProductState> {
  final Ref _ref;

  ProductNotifier(this._ref) : super(ProductState.initial()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = ProductState.loading();
    try {
      final products = await _ref.read(productRepositoryProvider).getAllProducts();
      state = ProductState.loaded(products);
    } on DioException catch (e) {
      state = ProductState.error(_handleDioError(e));
    } catch (e) {
      state = ProductState.error(e.toString());
    }
  }

  Future<void> createProduct(Map<String, dynamic> data, List<String> imagePaths) async {
    final currentProducts = state.products;
    state = ProductState.creating(currentProducts);
    try {
      final newProduct = await _ref.read(productRepositoryProvider).createProduct(data, imagePaths);
      state = ProductState.created([newProduct, ...currentProducts]);
    } on DioException catch (e) {
      state = ProductState.error(_handleDioError(e));
    } catch (e) {
      state = ProductState.error(e.toString());
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Server Error: ${e.response?.statusCode}';
      }
    }
    return e.message ?? 'An unknown network error occurred';
  }
}

final productControllerProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref);
});
