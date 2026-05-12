import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/repository_providers.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getAllProducts();
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProductById(id);
});
