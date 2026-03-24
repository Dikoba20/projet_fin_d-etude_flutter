// lib/core/services/admin_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../constants.dart';

class AdminService {
  final _api = ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Exposer le token pour les téléchargements directs
  Future<String?> getTokenPublic() => _getToken();

  // URL d'export — utilise la même baseUrl que l'api_client
  String getExportUrl(String type) {
    return '${AppConstants.baseUrl}/admin/export/$type/';
  }

  // ══════════════════════════════════════════════════
  // TABLEAU DE BORD
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _getToken();
    return await _api.get('/admin/dashboard/', token: token);
  }

  // ══════════════════════════════════════════════════
  // UTILISATEURS
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getUtilisateurs({String? role, String? statut, String? search}) async {
    final token = await _getToken();
    var url = '/admin/utilisateurs/?';
    if (role != null && role != 'TOUS') url += 'role=$role&';
    if (statut != null) url += 'statut=$statut&';
    if (search != null && search.isNotEmpty) url += 'search=$search&';
    return await _api.get(url, token: token);
  }

  Future<Map<String, dynamic>> creerUtilisateur(Map<String, dynamic> data) async {
    final token = await _getToken();
    return await _api.post('/admin/utilisateurs/', data, token: token);
  }

  Future<Map<String, dynamic>> modifierUtilisateur(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    return await _api.put('/admin/utilisateurs/$id/', data, token: token);
  }

  Future<Map<String, dynamic>> suspendreUtilisateur(String id) async {
    final token = await _getToken();
    return await _api.delete('/admin/utilisateurs/$id/', token: token);
  }

  // ══════════════════════════════════════════════════
  // CONTRATS
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getContrats({String? statut, String? type, String? search}) async {
    final token = await _getToken();
    var url = '/admin/contrats/?';
    if (statut != null && statut != 'TOUS') url += 'statut=$statut&';
    if (type != null && type != 'TOUS') url += 'type_assurance=$type&';
    if (search != null && search.isNotEmpty) url += 'search=$search&';
    return await _api.get(url, token: token);
  }

  Future<Map<String, dynamic>> modifierContrat(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    return await _api.put('/admin/contrats/$id/', data, token: token);
  }

  // ══════════════════════════════════════════════════
  // SINISTRES
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getSinistres({String? statut}) async {
    final token = await _getToken();
    var url = '/admin/sinistres/?';
    if (statut != null && statut != 'TOUS') url += 'statut=$statut&';
    return await _api.get(url, token: token);
  }

  Future<Map<String, dynamic>> modifierSinistre(String id, String statut) async {
    final token = await _getToken();
    return await _api.put('/admin/sinistres/$id/', {'statut': statut}, token: token);
  }

  // ══════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> envoyerNotification({
    required String titre,
    required String message,
    String destinataires = 'TOUS',
    String? utilisateurId,
  }) async {
    final token = await _getToken();
    final body = {
      'titre':         titre,
      'message':       message,
      'destinataires': utilisateurId != null ? 'INDIVIDUEL' : destinataires,
      if (utilisateurId != null) 'utilisateur_id': utilisateurId,
    };
    return await _api.post('/admin/notifications/envoyer/', body, token: token);
  }

  Future<Map<String, dynamic>> getNotificationsHistorique() async {
    final token = await _getToken();
    return await _api.get('/admin/notifications/historique/', token: token);
  }

  // ══════════════════════════════════════════════════
  // TARIFS
  // ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> getTarifs() async {
    final token = await _getToken();
    return await _api.get('/admin/tarifs/', token: token);
  }

  Future<Map<String, dynamic>> updateTarifs(Map<String, dynamic> tarifs) async {
    final token = await _getToken();
    return await _api.put('/admin/tarifs/', tarifs, token: token);
  }
}
