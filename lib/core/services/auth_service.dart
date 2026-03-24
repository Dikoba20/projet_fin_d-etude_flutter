// lib/core/services/auth_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';

class AuthService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    required String codePin,
    String? nni,
    String? email,
    String? adresse,
    File? photo, // ✅ Ajouté — ignoré sur web
  }) async {
    return await _api.post('/inscription/', {
      'nom':       nom,
      'prenom':    prenom,
      'telephone': telephone,
      'code_pin':  codePin,
      if (nni != null && nni.isNotEmpty)         'nni':     nni,
      if (email != null && email.isNotEmpty)     'email':   email,
      if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
    });
  }

  Future<Map<String, dynamic>> verifierOtp({
    required String telephone,
    required String otpCode,
  }) async {
    return await _api.post('/verifier-otp/', {
      'telephone': telephone,
      'otp_code':  otpCode,
    });
  }

  Future<Map<String, dynamic>> connecter({
    required String telephone,
    required String codePin,
  }) async {
    return await _api.post('/connexion/', {
      'telephone': telephone,
      'code_pin':  codePin,
    });
  }

  Future<Map<String, dynamic>> renvoyerOtp(String telephone) async {
    return await _api.post('/renvoyer-otp/', {'telephone': telephone});
  }

  Future<void> sauvegarderSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token',        token);
    await prefs.setString('user_id',      user['id'].toString());
    await prefs.setString('user_nom',     user['nom']       ?? '');
    await prefs.setString('user_prenom',  user['prenom']    ?? '');
    await prefs.setString('user_tel',     user['telephone'] ?? '');
    await prefs.setString('user_role',    user['role']      ?? '');
    await prefs.setString('user_nni',     user['nni']       ?? '');
    await prefs.setString('user_email',   user['email']     ?? '');
    await prefs.setString('user_adresse', user['adresse']   ?? '');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> estConnecte() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasSession() async => estConnecte();

  Future<void> deconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id':      prefs.getString('user_id')      ?? '',
      'nom':     prefs.getString('user_nom')     ?? '',
      'prenom':  prefs.getString('user_prenom')  ?? '',
      'tel':     prefs.getString('user_tel')     ?? '',
      'role':    prefs.getString('user_role')    ?? '',
      'nni':     prefs.getString('user_nni')     ?? '',
      'email':   prefs.getString('user_email')   ?? '',
      'adresse': prefs.getString('user_adresse') ?? '',
      'token':   prefs.getString('token')        ?? '',
    };
  }

  // ✅ Récupère le rôle directement
  Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? '';
  }

  // ✅ Vérifie si l'utilisateur est admin
  Future<bool> estAdmin() async {
    final role = await getRole();
    return role == 'ADMIN';
  }

  Future<Map<String, dynamic>> rafraichirProfil() async {
    final token = await getToken();
    if (token == null) return {};
    final res = await _api.get('/profil/', token: token);
    if (res['success'] == true && res['user'] != null) {
      await sauvegarderSession(token, res['user']);
    }
    return res;
  }
}