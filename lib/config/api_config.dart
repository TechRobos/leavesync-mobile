class ApiConfig {
  static const bool isDev = true;

  static const String devUrl = "http://127.0.0.1:8000";
  static const String prodUrl = "https://api.enetech.com.my";

  static String get baseUrl => isDev ? devUrl : prodUrl;
  static String get storageUrl => "$baseUrl/storage";
}
