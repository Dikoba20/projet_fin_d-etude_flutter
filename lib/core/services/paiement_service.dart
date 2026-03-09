import 'package:assurancy/core/api_client.dart';
import 'package:assurancy/core/services/auth_service.dart';

class PaiementService {
  final ApiClient   _apiClient;
  final AuthService _authService = AuthService();

  PaiementService(this._apiClient);

  Future<String?> get _token => _authService.getToken();

  Future<List<Map<String, dynamic>>> getPaiements() async {
    final res = await _apiClient.get('/paiements/', token: await _token);
    final data = res['paiements'] ?? res['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getPaiementById(String id) async {
    final res = await _apiClient.get('/paiements/$id/', token: await _token);
    return Map<String, dynamic>.from(res['data'] ?? res);
  }

  Future<Map<String, dynamic>> payerMobile({
    required String contratId,
    required String telephone,
    required double montant,
    required String appPaiement,
  }) async {
    final res = await _apiClient.post(
      '/paiements/mobile/', // ✅ slash ajouté
      {
        'contrat_id':   contratId,
        'telephone':    telephone,
        'montant':      montant,
        'app_paiement': appPaiement,
      },
      token: await _token,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> renouvelerContrat({
    required String contratId,
    required String appPaiement,
    String? telephone,
  }) async {
    final res = await _apiClient.post(
      '/contrats/$contratId/renouveler/', // ✅ slash ajouté
      {
        'app_paiement': appPaiement,
        if (telephone != null) 'telephone': telephone,
      },
      token: await _token,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<String> getAttestationUrl(String contratId) async {
    final res = await _apiClient.get(
        '/contrats/$contratId/attestation/', token: await _token); // ✅ slash ajouté
    return res['data']['url'] as String;
  }

  Future<List<Map<String, dynamic>>> getRappels() async {
    final res = await _apiClient.get('/paiements/rappels/', token: await _token); // ✅ slash ajouté
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }
}