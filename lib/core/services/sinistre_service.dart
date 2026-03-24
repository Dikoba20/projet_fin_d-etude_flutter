// lib/core/services/sinistre_service.dart

import '../api_client.dart';

class SinistreService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> declarerSinistre({
    required String token,
    required int contratId,
    required String description,
    required String dateAccident,
    String? lieuAccident,
    double? latitude,
    double? longitude,
  }) async {
    return _api.post(
      '/sinistres/',
      {
        'contrat_id':    contratId,
        'description':   description,
        'date_accident': dateAccident,
        if (lieuAccident != null && lieuAccident.isNotEmpty)
          'lieu_accident': lieuAccident,
        if (latitude != null)  'latitude':  latitude,
        if (longitude != null) 'longitude': longitude,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> getSinistres({required String token}) async {
    return _api.get('/sinistres/', token: token);
  }

  Future<Map<String, dynamic>> getSinistre({
    required String token,
    required int sinistreId,
  }) async {
    return _api.get('/sinistres/$sinistreId/', token: token);
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required String token,
    required int sinistreId,
    required List<int> bytes,
    required String fileName,
  }) async {
    return _api.postMultipartBytes(
      '/documents/upload/',
      fields: {
        'type_document': 'SINISTRE',
        'sinistre_id':   sinistreId.toString(),
      },
      filesBytes: {'fichier': bytes as dynamic},
      filesNames: {'fichier': fileName},
      token: token,
    );
  }
}