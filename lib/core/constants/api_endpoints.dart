class ApiEndpoints {
  // static const String baseUrl = 'http://10.216.51.201:5000/api'; // Local IP for development
  static const String baseUrl = 'https://shop-near.onrender.com/api'; // Production (Render)
  // static const String baseUrl = 'http://localhost:5000/api'; // For iOS/Web
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String live = '/live';
  static const String reels = '/reels';
  static const String chat = '/chat';
  static const String profile = '/profile';
}
