// lib/core/services/agent_service.dart
// Service agent — tous les appels API du module agent
// Endpoints disponibles dans views.py

import '../api_client.dart';
import 'auth_service.dart';

class AgentService {
  final _api     = ApiClient();
  final _auth    = AuthService();

  // ─────────────────────────────────────────────────────
  // HELPER : token
  // ─────────────────────────────────────────────────────
  Future<String?> get _token => _auth.getToken();

  // ─────────────────────────────────────────────────────
  // DASHBOARD — stats (réutilise admin_dashboard)
  // GET /admin/dashboard/
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _token;
    return await _api.get('/admin/dashboard/', token: token);
  }

  // ─────────────────────────────────────────────────────
  // CONTRATS
  // GET  /agent/contrats/?statut=&search=
  // GET  /agent/contrats/<id>/
  // PUT  /agent/contrats/<id>/  { statut }
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getContrats({
    String? statut,
    String? search,
    String? typeAssurance,
  }) async {
    final token = await _token;
    String endpoint = '/agent/contrats/?';
    if (statut != null && statut != 'TOUS') endpoint += 'statut=$statut&';
    if (typeAssurance != null && typeAssurance != 'TOUS') endpoint += 'type_assurance=$typeAssurance&';
    if (search != null && search.isNotEmpty) endpoint += 'search=$search&';
    return await _api.get(endpoint, token: token);
  }

  Future<Map<String, dynamic>> getContratDetail(int id) async {
    final token = await _token;
    return await _api.get('/agent/contrats/$id/', token: token);
  }

  Future<Map<String, dynamic>> updateContratStatut(int id, String statut) async {
    final token = await _token;
    return await _api.put('/agent/contrats/$id/', {'statut': statut}, token: token);
  }

  // ─────────────────────────────────────────────────────
  // MESSAGERIE
  // POST /agent/messages/envoyer/   { client_id, message, sujet, contrat_id? }
  // GET  /agent/messages/<client_id>/
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> envoyerMessage({
    required int clientId,
    required String message,
    String sujet = 'Message de votre agent',
    int? contratId,
  }) async {
    final token = await _token;
    return await _api.post('/agent/messages/envoyer/', {
      'client_id': clientId,
      'message':   message,
      'sujet':     sujet,
      if (contratId != null) 'contrat_id': contratId,
    }, token: token);
  }

  Future<Map<String, dynamic>> getMessagesClient(int clientId) async {
    final token = await _token;
    return await _api.get('/agent/messages/$clientId/', token: token);
  }

  // ─────────────────────────────────────────────────────
  // SINISTRES
  // GET /agent/sinistres/?statut=
  // PUT /agent/sinistres/<id>/  { statut }
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSinistres({String? statut}) async {
    final token = await _token;
    String endpoint = '/agent/sinistres/';
    if (statut != null && statut != 'TOUS') endpoint += '?statut=$statut';
    return await _api.get(endpoint, token: token);
  }

  Future<Map<String, dynamic>> updateSinistreStatut(int id, String statut) async {
    final token = await _token;
    return await _api.put('/agent/sinistres/$id/', {'statut': statut}, token: token);
  }

  // ─────────────────────────────────────────────────────
  // PORTEFEUILLE CLIENTS
  // GET /admin/utilisateurs/?role=CLIENT&search=
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getClients({String? search}) async {
    final token = await _token;
    String endpoint = '/admin/utilisateurs/?role=CLIENT';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';
    return await _api.get(endpoint, token: token);
  }

  // ─────────────────────────────────────────────────────
  // RAPPORTS — stats mensuelles
  // GET /admin/stats/contrats-mois/
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStatsMois() async {
    final token = await _token;
    return await _api.get('/admin/stats/contrats-mois/', token: token);
  }
}