import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'constants.dart';

class ApiClient {
  String get baseUrl => AppConstants.baseUrl;

  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers({String? token}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Parse la réponse HTTP en Map.
  /// Si le corps est vide ou invalide, retourne une map d'erreur.
  Map<String, dynamic> _parseResponse(http.Response res) {
    try {
      final body = utf8.decode(res.bodyBytes).trim();
      if (body.isEmpty) {
        return {
          'success': res.statusCode >= 200 && res.statusCode < 300,
          'status_code': res.statusCode,
          'message': 'Réponse vide du serveur',
        };
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        decoded['status_code'] = res.statusCode;
        return decoded;
      }
      // L'API retourne parfois une liste directement (ex: /contrats/)
      if (decoded is List) {
        return {
          'results': decoded,
          'contrats': decoded,
          'vehicules': decoded,
          'sinistres': decoded,
          'status_code': res.statusCode,
        };
      }
      return {
        'success': false,
        'status_code': res.statusCode,
        'message': 'Format de réponse inattendu',
      };
    } catch (e) {
      return {
        'success': false,
        'status_code': res.statusCode,
        'message': 'Erreur de décodage JSON : $e',
      };
    }
  }

  Map<String, dynamic> _networkError(String endpoint, dynamic e) {
    final msg = e.toString();
    String detail;
    if (msg.contains('No route to host') || msg.contains('Connection refused')) {
      detail = 'Serveur inaccessible ($baseUrl). Vérifiez que le serveur tourne et que le téléphone est sur le bon WiFi.';
    } else if (msg.contains('SocketException')) {
      detail = 'Pas de connexion réseau.';
    } else if (msg.contains('TimeoutException')) {
      detail = 'Le serveur ne répond pas (timeout 15s).';
    } else {
      detail = msg;
    }
    print('❌ API ERROR [$endpoint] → $detail');
    return {'success': false, 'message': detail, 'network_error': true};
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      print('🌐 GET $baseUrl$endpoint');
      final res = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers(token: token))
          .timeout(_timeout);
      print('✅ GET $endpoint → ${res.statusCode}');
      return _parseResponse(res);
    } catch (e) {
      return _networkError(endpoint, e);
    }
  }

  // ── POST JSON ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      print('🌐 POST $baseUrl$endpoint');
      final res = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print('✅ POST $endpoint → ${res.statusCode}');
      return _parseResponse(res);
    } catch (e) {
      return _networkError(endpoint, e);
    }
  }

  // ── PUT JSON ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      print('🌐 PUT $baseUrl$endpoint');
      final res = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print('✅ PUT $endpoint → ${res.statusCode}');
      return _parseResponse(res);
    } catch (e) {
      return _networkError(endpoint, e);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String endpoint, {String? token}) async {
    try {
      print('🌐 DELETE $baseUrl$endpoint');
      final res = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers(token: token))
          .timeout(_timeout);
      print('✅ DELETE $endpoint → ${res.statusCode}');
      return _parseResponse(res);
    } catch (e) {
      return _networkError(endpoint, e);
    }
  }

  // ── MULTIPART BYTES ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postMultipartBytes(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, Uint8List>? filesBytes,
    Map<String, String>? filesNames,
    String? token,
  }) async {
    try {
      print('🌐 MULTIPART POST $baseUrl$endpoint');
      final uri     = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (filesBytes != null) {
        for (final entry in filesBytes.entries) {
          final fieldName = entry.key;
          final bytes     = entry.value;
          final fileName  = filesNames?[fieldName] ?? '$fieldName.jpg';
          final mime      = _mimeFromName(fileName);
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename:    fileName,
              contentType: MediaType.parse(mime),
            ),
          );
        }
      }

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      print('✅ MULTIPART $endpoint → ${response.statusCode}');
      return _parseResponse(response);
    } catch (e) {
      return _networkError(endpoint, e);
    }
  }

  String _mimeFromName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':  return 'image/png';
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:     return 'image/jpeg';
    }
  }
}