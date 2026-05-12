import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.products);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      throw Exception('Failed to load products');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.products}/$id');
      if (response.statusCode == 200) {
        return Product.fromMap(response.data);
      }
      throw Exception('Failed to load product');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.categoryProducts}/$category');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      throw Exception('Failed to load category products');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.searchProducts, queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      throw Exception('Failed to search products');
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data, List<String> imagePaths) async {
    try {
      final Map<String, dynamic> formDataMap = {...data};
      
      final List<MultipartFile> files = [];
      for (String path in imagePaths) {
        files.add(await MultipartFile.fromFile(path));
      }
      formDataMap['images'] = files;

      final formData = FormData.fromMap(formDataMap);
      
      final response = await _apiClient.post(ApiEndpoints.products, data: formData);
      if (response.statusCode == 201) {
        return Product.fromMap(response.data);
      }
      throw Exception('Failed to create product');
    } catch (e) {
      rethrow;
    }
  }
}
