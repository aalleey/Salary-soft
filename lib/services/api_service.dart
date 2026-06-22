import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  final http.Client _client = http.Client();
  String? _token;

  Future<void> _loadToken() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConfig.tokenKey);
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    await _loadToken();
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');

    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    await _loadToken();
    var url = Uri.parse('${AppConfig.baseUrl}/$endpoint');

    if (queryParams != null) {
      url = url.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(
        url,
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    await _loadToken();
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');

    try {
      final response = await _client.put(
        url,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    await _loadToken();
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');

    try {
      final response = await _client.delete(
        url,
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final errorMsg = body is Map ? (body['message'] ?? 'Request failed with status: ${response.statusCode}') : 'Request failed with status: ${response.statusCode}';
      final errorDetail = (body is Map && body['error'] != null) ? ' - ${body['error']}' : '';
      throw Exception('$errorMsg$errorDetail');
    }
  }
}
