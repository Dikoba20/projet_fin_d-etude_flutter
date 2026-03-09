import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Sur Flutter Web, utilisez 127.0.0.1 et NON localhost
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Headers communs
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }
  }

  // POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }
  }

  // Vérification de la réponse
  static dynamic _handleResponse(http.Response response) {
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}