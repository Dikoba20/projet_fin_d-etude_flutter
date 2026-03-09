import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'otp_reset_page.dart';

class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});
  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  final _telephoneController = TextEditingController();
  final _emailController     = TextEditingController();
  bool _isLoading = false;
  int _cooldown = 0;          // ✅ SÉCURITÉ 2 : cooldown
  Timer? _cooldownTimer;
  final _api = ApiClient();

  @override
  void dispose() {
    _telephoneController.dispose();
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ✅ SÉCURITÉ 1a : valider format téléphone
  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    return RegExp(r'^\d{8,15}$').hasMatch(cleaned);
  }

  // ✅ SÉCURITÉ 1b : valider format email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  // ✅ SÉCURITÉ 2 : démarrer le countdown 60s
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
    final telephone = _telephoneController.text.trim();
    final email     = _emailController.text.trim();

    // ✅ SÉCURITÉ 2 : bloquer si cooldown actif
    if (_cooldown > 0) return;

    if (telephone.isEmpty && email.isEmpty) {
      _showError('Entrez votre numéro de téléphone ou votre email.');
      return;
    }

    // ✅ SÉCURITÉ 1 : valider le format avant d'envoyer
    if (telephone.isNotEmpty && !_isValidPhone(telephone)) {
      _showError('Numéro de téléphone invalide (8 à 15 chiffres).');
      return;
    }
    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showError('Adresse email invalide.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _api.post('/mot-de-passe-oublie/', {
        if (telephone.isNotEmpty) 'telephone': telephone,
        if (email.isNotEmpty)     'email':     email,
      });

      if (!mounted) return;

      if (res['success'] == true) {
        // ✅ SÉCURITÉ 2 : démarrer cooldown après envoi réussi
        _startCooldown();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpResetPage(
              telephone: res['telephone'] ?? telephone,
              otpDebug:  res['otp_debug']?.toString(),
            ),
          ),
        );
      } else {
        // ✅ SÉCURITÉ 3 : message neutre (ne révèle pas si le compte existe)
        _showNeutral();
        _startCooldown();
      }
    } catch (e) {
      if (!mounted) return;
      // ✅ SÉCURITÉ 3 : même message neutre en cas d'erreur serveur
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

  // ✅ SÉCURITÉ 3 : message neutre
  void _showNeutral() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Si un compte est associé à ces informations, un code vous sera envoyé.',
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ICONE
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF1A56DB).withOpacity(0.13),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )],
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
                    const Text(
                      'Entrez votre téléphone ou email\npour recevoir un code de vérification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF8EA8D8), height: 1.5),
                    ),
                    const SizedBox(height: 36),

                    // CHAMP TELEPHONE
                    _buildField(_telephoneController, 'Numéro de téléphone',
                        Icons.phone_outlined, type: TextInputType.phone),
                    const SizedBox(height: 16),

                    // SEPARATEUR
                    Row(children: [
                      const Expanded(child: Divider(color: Color(0xFFD0DCF0))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OU',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFD0DCF0))),
                    ]),
                    const SizedBox(height: 16),

                    // CHAMP EMAIL
                    _buildField(_emailController, 'Adresse email',
                        Icons.email_outlined, type: TextInputType.emailAddress),
                    const SizedBox(height: 36),

                    // BOUTON ENVOYER — ✅ grisé + countdown affiché
                    GestureDetector(
                      onTap: canSend ? _envoyer : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          color: canSend
                              ? const Color(0xFF1A56DB)
                              : const Color(0xFFADBDD8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: canSend
                              ? [BoxShadow(
                                  color: const Color(0xFF1A56DB).withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7))]
                              : [],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  // ✅ SÉCURITÉ 2 : affiche le countdown
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
                              fontWeight: FontWeight.w600)),
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

  Widget _buildField(TextEditingController controller, String hint,
      IconData icon, {TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFADBDD8), size: 21),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}