/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();
  
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  
  // Example endpoints - replace with your actual API
  static const String posts = '/posts';
  static String postDetail(int id) => '/posts/$id';
}

