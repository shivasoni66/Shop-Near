import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../shared/models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> getAllProducts({String? category, String? query}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.products,
        queryParameters: {
          if (category != null) 'category': category,
          if (query != null) 'query': query,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromMap(item)).toList();
      }
      throw Exception('Failed to load products');
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

  Future<Product> createProduct(
      Map<String, dynamic> data, List<String> imagePaths) async {
    try {
      final List<MapEntry<String, MultipartFile>> files = [];
      for (String path in imagePaths) {
        final fileName = path.split('/').last;
        files.add(MapEntry(
          'images', 
          await MultipartFile.fromFile(path, filename: fileName)
        ));
      }

      final formData = FormData();
      
      // Add regular fields
      data.forEach((key, value) {
        if (value is List) {
          // Join lists (like tags) into comma-separated strings for the backend
          formData.fields.add(MapEntry(key, value.join(',')));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      
      // Add images
      formData.files.addAll(files);

      final response =
          await _apiClient.post(ApiEndpoints.products, data: formData);
      if (response.statusCode == 201) {
        return Product.fromMap(response.data);
      }
      throw Exception('Failed to create product');
    } catch (e) {
      rethrow;
    }
  }
}
