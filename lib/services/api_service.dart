import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiService extends GetxService {
  static ApiService get to => Get.find();

  final RxString _baseUrl = ''.obs;
  final Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  String get baseUrl => _baseUrl.value;
  Map<String, String> get headers => _headers;

  void setBaseUrl(String url) {
    // Ensure no trailing slash
    _baseUrl.value = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void setSessionCookie(String cookie) {
    _headers['Cookie'] = cookie;
  }

  /// Generic GET helper
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    if (_baseUrl.isEmpty) throw Exception('Server URL not configured');

    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    return http.get(uri, headers: _headers);
  }

  /// Generic POST helper
  Future<http.Response> post(String endpoint, {Object? body}) async {
    if (_baseUrl.isEmpty) throw Exception('Server URL not configured');

    final uri = Uri.parse('$_baseUrl$endpoint');
    return http.post(uri, headers: _headers, body: body);
  }

  /// Generic PUT helper for Updates
  Future<http.Response> put(String endpoint, {Object? body}) async {
    if (_baseUrl.isEmpty) throw Exception('Server URL not configured');

    final uri = Uri.parse('$_baseUrl$endpoint');
    return http.put(uri, headers: _headers, body: body);
  }

  /// Generic DELETE helper
  Future<http.Response> delete(String endpoint) async {
    if (_baseUrl.isEmpty) throw Exception('Server URL not configured');

    final uri = Uri.parse('$_baseUrl$endpoint');
    return http.delete(uri, headers: _headers);
  }
}