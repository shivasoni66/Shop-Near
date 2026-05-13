class ApiEndpoints {
  // STEP 1: For Local Dev, use your laptop's IP (e.g. 192.168.1.15)
  // static const String baseUrl = 'http://192.168.1.15:5000/api'; 
  
  // STEP 2: For Production, use your Render URL
  static const String baseUrl = 'https://shop-near.onrender.com/api'; 

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String live = '/live';
  static const String reels = '/reels';
  static const String chat = '/chat';
  static const String profile = '/profile';
}
