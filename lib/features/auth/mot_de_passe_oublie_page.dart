import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import 'otp_reset_page.dart';

// ═══════════════════════════════════════════════════════
// PAGE MOT DE PASSE OUBLIÉ
// ── Web    (admin/agent)  → champ EMAIL uniquement
// ── Mobile (client/agent) → champ TÉLÉPHONE uniquement
// ═══════════════════════════════════════════════════════
class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});
  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  int  _cooldown  = 0;
  Timer? _cooldownTimer;
  final _api = ApiClient();

  // ── true = web (email), false = mobile (téléphone)
  bool get _isWeb => kIsWeb;

  @override
  void dispose() {
    _inputController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Validations format
  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    return RegExp(r'^\d{8,15}$').hasMatch(cleaned);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  // ── Cooldown 60s anti-spam
  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  void _envoyer() async {
    if (_cooldown > 0) return;

    final input = _inputController.text.trim();

    if (input.isEmpty) {
      _showError(_isWeb
          ? 'Veuillez entrer votre adresse email.'
          : 'Veuillez entrer votre numéro de téléphone.');
      return;
    }

    // ── Validation format selon plateforme
    if (_isWeb && !_isValidEmail(input)) {
      _showError('Adresse email invalide.');
      return;
    }
    if (!_isWeb && !_isValidPhone(input)) {
      _showError('Numéro de téléphone invalide (8 à 15 chiffres).');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _api.post('/mot-de-passe-oublie/', {
        if (_isWeb)  'email':     input,
        if (!_isWeb) 'telephone': input,
      });

      if (!mounted) return;

      if (res['success'] == true) {
        _startCooldown();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpResetPage(
              telephone: res['telephone'] ?? input,
              otpDebug:  res['otp_debug']?.toString(),
            ),
          ),
        );
      } else {
        // Message neutre — ne révèle pas si le compte existe
        _showNeutral();
        _startCooldown();
      }
    } catch (e) {
      if (!mounted) return;
      _showNeutral();
      _startCooldown();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Message neutre (sécurité : ne révèle pas si le compte existe)
  void _showNeutral() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Si un compte est associé à ces informations, un code vous sera envoyé.'),
        backgroundColor: const Color(0xFF1A56DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _cooldown == 0 && !_isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDEEBFA), Color(0xFFF0F6FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── ICONE
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF1A56DB).withOpacity(0.13),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_reset_rounded,
                            color: Color(0xFF1A56DB), size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Mot de passe oublié',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1535A8))),
                    const SizedBox(height: 8),

                    // ── Sous-titre adapté selon plateforme
                    Text(
                      _isWeb
                          ? 'Entrez votre adresse email pour\nrecevoir un code de réinitialisation.'
                          : 'Entrez votre numéro de téléphone pour\nrecevoir un code de vérification.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8EA8D8),
                          height: 1.5),
                    ),
                    const SizedBox(height: 36),

                    // ── BADGE plateforme
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFBDD6F5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isWeb
                                ? Icons.computer_rounded
                                : Icons.phone_android_rounded,
                            color: const Color(0xFF1A56DB),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isWeb
                                ? 'Réinitialisation via email (Admin/Agent)'
                                : 'Réinitialisation via SMS (Client/Agent)',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1A56DB),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── CHAMP UNIQUE selon plateforme
                    _buildField(
                      controller: _inputController,
                      hint: _isWeb
                          ? 'Adresse email'
                          : 'Numéro de téléphone',
                      icon: _isWeb
                          ? Icons.email_outlined
                          : Icons.phone_outlined,
                      type: _isWeb
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                    ),

                    const SizedBox(height: 36),

                    // ── BOUTON ENVOYER avec cooldown
                    GestureDetector(
                      onTap: canSend ? _envoyer : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: canSend
                              ? const Color(0xFF1A56DB)
                              : const Color(0xFFADBDD8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: canSend
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF1A56DB)
                                          .withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7))
                                ]
                              : [],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5))
                              : Text(
                                  _cooldown > 0
                                      ? 'Patienter $_cooldown s...'
                                      : 'Envoyer le code',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Retour à la connexion',
                          style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF1A56DB),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF1A56DB))),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFFADBDD8), size: 21),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}