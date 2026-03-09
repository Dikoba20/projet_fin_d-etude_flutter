import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'constants.dart';

class ApiClient {
  final String baseUrl = AppConstants.baseUrl;

  Map<String, String> _headers({String? token}) {
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ── GET ───────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token: token),
      );
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // ── POST JSON ─────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // ── PUT JSON ──────────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // ── DELETE ────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token: token),
      );
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // ── MULTIPART BYTES — compatible web + mobile ─────────
  // Utilise Uint8List au lieu de File (pas de dart:io)
  Future<Map<String, dynamic>> postMultipartBytes(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, Uint8List>? filesBytes,
    Map<String, String>? filesNames, // nom de fichier par champ
    String? token,
  }) async {
    try {
      final uri     = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Champs texte
      request.fields.addAll(fields);

      // Fichiers en bytes
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

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // ── Détecte le MIME type depuis l'extension du fichier ─
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