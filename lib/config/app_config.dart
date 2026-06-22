class AppConfig {
  // API Configuration
  // 10.0.2.2 is the special alias to your host loopback interface in the Android Emulator
  static const String baseUrl = 'http://192.168.100.200:5000/api';
  
  // App Information
  static const String appName = 'SalarySoft';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
