// lib/core/services/expert_service.dart

import '../api_client.dart';
import 'auth_service.dart';

class ExpertService {
  final _api  = ApiClient();
  final _auth = AuthService();

  Future<String?> get _token => _auth.getToken();

  Future<Map<String, dynamic>> getSinistres({String? statut}) async {
    final token = await _token;
    String ep = '/agent/sinistres/';
    if (statut != null && statut != 'TOUS') ep += '?statut=$statut';
    return await _api.get(ep, token: token);
  }

  Future<Map<String, dynamic>> updateSinistre(int id, {
    String? statut, String? rapportExpert,
    double? montantEstime, double? montantIndemnise,
  }) async {
    final token = await _token;
    final body = <String, dynamic>{};
    if (statut           != null) body['statut']            = statut;
    if (rapportExpert    != null) body['rapport_expert']    = rapportExpert;
    if (montantEstime    != null) body['montant_estime']    = montantEstime;
    if (montantIndemnise != null) body['montant_indemnise'] = montantIndemnise;
    return await _api.put('/agent/sinistres/$id/', body, token: token);
  }

  Future<Map<String, dynamic>> getDocumentsSinistre(int sinistreId) async {
    final token = await _token;
    return await _api.get('/documents/?sinistre_id=$sinistreId', token: token);
  }

  Future<Map<String, dynamic>> envoyerMessage({
    required int clientId, required String message,
    String sujet = 'Message de votre expert', int? contratId,
  }) async {
    final token = await _token;
    return await _api.post('/agent/messages/envoyer/', {
      'client_id': clientId, 'message': message, 'sujet': sujet,
      if (contratId != null) 'contrat_id': contratId,
    }, token: token);
  }

  Future<Map<String, String>> getUserInfo() => _auth.getUserInfo();
}