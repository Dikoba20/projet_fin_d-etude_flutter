import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';

class AuthService {
  final _api = ApiClient();

  // ── INSCRIPTION ──────────────────────────────────────
  Future<Map<String, dynamic>> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    required String codePin,
    String? nni,
    String? email,
    String? adresse, // ✅ ADRESSE
    File? photo,     // ✅ PHOTO
  }) async {
    return await _api.post('/inscription/', {
      'nom':       nom,
      'prenom':    prenom,
      'telephone': telephone,
      'code_pin':  codePin,
      if (nni != null && nni.isNotEmpty)         'nni':     nni,
      if (email != null && email.isNotEmpty)     'email':   email,
      if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      // La photo est envoyée séparément via multipart si nécessaire
    });
  }

  // ── VERIFICATION OTP ──────────────────────────────────
  Future<Map<String, dynamic>> verifierOtp({
    required String telephone,
    required String otpCode,
  }) async {
    return await _api.post('/verifier-otp/', {
      'telephone': telephone,
      'otp_code':  otpCode,
    });
  }

  // ── CONNEXION ─────────────────────────────────────────
  Future<Map<String, dynamic>> connecter({
    required String telephone,
    required String codePin,
  }) async {
    return await _api.post('/connexion/', {
      'telephone': telephone,
      'code_pin':  codePin,
    });
  }

  // ── RENVOYER OTP ──────────────────────────────────────
  Future<Map<String, dynamic>> renvoyerOtp(String telephone) async {
    return await _api.post('/renvoyer-otp/', {'telephone': telephone});
  }

  // ── SAUVEGARDER SESSION ───────────────────────────────
  Future<void> sauvegarderSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token',        token);
    await prefs.setString('user_id',      user['id'].toString());
    await prefs.setString('user_nom',     user['nom']);
    await prefs.setString('user_prenom',  user['prenom']);
    await prefs.setString('user_tel',     user['telephone']);
    await prefs.setString('user_role',    user['role']);
  }

  // ── RECUPERER TOKEN ───────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── VERIFIER SI CONNECTE ──────────────────────────────
  Future<bool> estConnecte() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ BIOMÉTRIE : alias de estConnecte()
  Future<bool> hasSession() async => estConnecte();

  // ── DECONNEXION ───────────────────────────────────────
  Future<void> deconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── RECUPERER INFOS USER ──────────────────────────────
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id':     prefs.getString('user_id')     ?? '',
      'nom':    prefs.getString('user_nom')    ?? '',
      'prenom': prefs.getString('user_prenom') ?? '',
      'tel':    prefs.getString('user_tel')    ?? '',
      'role':   prefs.getString('user_role')   ?? '',
    };
  }
}