import 'package:local_auth/local_auth.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  /// Vérifie si l'appareil supporte la biométrie
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Retourne les types disponibles (empreinte, Face ID...)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Lance l'authentification biométrique
  /// Retourne true si succès, false sinon
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Connectez-vous à AssurAncy avec votre biométrie',
        options: const AuthenticationOptions(
          biometricOnly: true,   // empreinte ou Face ID uniquement
          stickyAuth: true,      // reste actif si l'app passe en arrière-plan
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}