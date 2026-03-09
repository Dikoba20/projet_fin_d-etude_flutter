import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';

class SouscriptionService {
  final _api = ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // ══════════════════════════════════════════════════════
  // 1. Créer le véhicule
  // POST /vehicules/
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> creerVehicule({
    required String marque,
    required String modele,
    required int annee,
    required String immatriculation,
    required String numeroChassis,
    String? energie,
    double? valeurVenale,
    Uint8List? carteGriseBytes,
    String? carteGriseNom,
    Uint8List? photoVehiculeBytes,
    String? photoVehiculeNom,
  }) async {
    final token  = await _getToken();
    final userId = await _getUserId();

    final fields = {
      'utilisateur_id':  userId ?? '',
      'marque':          marque,
      'modele':          modele,
      'annee':           annee.toString(),
      'immatriculation': immatriculation,
      'numero_chassis':  numeroChassis,
      if (energie != null)      'energie':       energie,
      if (valeurVenale != null) 'valeur_venale': valeurVenale.toString(),
    };

    final filesBytes = <String, Uint8List>{};
    final filesNames = <String, String>{};

    if (carteGriseBytes != null) {
      filesBytes['carte_grise'] = carteGriseBytes;
      filesNames['carte_grise'] = carteGriseNom ?? 'carte_grise.jpg';
    }
    if (photoVehiculeBytes != null) {
      filesBytes['photo_vehicule'] = photoVehiculeBytes;
      filesNames['photo_vehicule'] = photoVehiculeNom ?? 'photo_vehicule.jpg';
    }

    return await _api.postMultipartBytes(
      '/vehicules/',
      fields: fields,
      filesBytes: filesBytes.isEmpty ? null : filesBytes,
      filesNames: filesNames.isEmpty ? null : filesNames,
      token: token,
    );
  }

  // ══════════════════════════════════════════════════════
  // 2. Upload permis de conduire
  // POST /documents/upload/
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> uploadPermis({
    required Uint8List permisBytes,
    required String permisNom,
    required String vehiculeId,
  }) async {
    final token  = await _getToken();
    final userId = await _getUserId();

    return await _api.postMultipartBytes(
      '/documents/upload/',
      fields: {
        'utilisateur_id': userId ?? '',
        'vehicule_id':    vehiculeId,
        'type_document':  'PERMIS_CONDUIRE',
      },
      filesBytes: {'fichier': permisBytes},
      filesNames: {'fichier': permisNom},
      token: token,
    );
  }

  // ══════════════════════════════════════════════════════
  // 3. Calculer la prime automatiquement
  // POST /contrats/calculer-prime/
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> calculerPrime({
    required String typeAssurance,
    required String vehiculeId,
    required int dureeMois,
  }) async {
    final token = await _getToken();
    return await _api.post('/contrats/calculer-prime/', {
      'type_assurance': typeAssurance,
      'vehicule_id':    vehiculeId,
      'duree_mois':     dureeMois,
    }, token: token);
  }

  // ══════════════════════════════════════════════════════
  // 4. Créer le contrat + signature électronique
  // POST /contrats/
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> creerContrat({
    required String vehiculeId,
    required String typeAssurance,
    required int dureeMois,
    required double primeMontant,
    required Uint8List signatureBytes,
  }) async {
    final token  = await _getToken();
    final userId = await _getUserId();

    return await _api.postMultipartBytes(
      '/contrats/',
      fields: {
        'utilisateur_id': userId ?? '',
        'vehicule_id':    vehiculeId,
        'type_assurance': typeAssurance,
        'duree_mois':     dureeMois.toString(),
        'prime_montant':  primeMontant.toString(),
      },
      filesBytes: {
        'signature': signatureBytes,
      },
      filesNames: {
        'signature': 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
      },
      token: token,
    );
  }

  // ══════════════════════════════════════════════════════
  // Récupérer les véhicules de l'utilisateur
  // GET /vehicules/?utilisateur_id=X
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getMesVehicules() async {
    final token  = await _getToken();
    final userId = await _getUserId();
    return await _api.get('/vehicules/?utilisateur_id=$userId', token: token);
  }

  // ══════════════════════════════════════════════════════
  // Récupérer les contrats de l'utilisateur
  // GET /contrats/?utilisateur_id=X
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getMesContrats() async {
    final token  = await _getToken();
    final userId = await _getUserId();
    return await _api.get('/contrats/?utilisateur_id=$userId', token: token);
  }

  // ══════════════════════════════════════════════════════
  // 5. Récupérer attestation PDF + QR Code
  // GET /contrats/{id}/attestation/
  // ══════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getAttestation(String contratId) async {
    final token = await _getToken();
    return await _api.get('/contrats/$contratId/attestation/', token: token);
  }
}