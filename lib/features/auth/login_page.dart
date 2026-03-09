import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart'; // ✅ BIOMÉTRIE
import 'inscription_page.dart';
import 'mot_de_passe_oublie_page.dart';
import '../../core/dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _biometricAvailable = false; // ✅ BIOMÉTRIE
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _authService = AuthService();
  final _biometricService = BiometricService(); // ✅ BIOMÉTRIE

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkBiometric(); // ✅ BIOMÉTRIE
  }

  // ✅ BIOMÉTRIE : vérifier disponibilité au démarrage
  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  // ✅ BIOMÉTRIE : icône selon le type disponible (Face ID ou empreinte)
  Future<IconData> _getBiometricIcon() async {
    final types = await _biometricService.getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return Icons.face_rounded;
    return Icons.fingerprint_rounded;
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  void _onPinChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _pinFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _handleLogin() async {
    final telephone = _phoneController.text.trim();
    final pin = _pinControllers.map((c) => c.text).join();

    if (telephone.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez le téléphone et le code PIN.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _authService.connecter(
        telephone: telephone,
        codePin: pin,
      );
      if (res['success'] == true) {
        await _authService.sauvegarderSession(res['token'], res['user']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Erreur de connexion.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de joindre le serveur.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ BIOMÉTRIE : authentification par empreinte / Face ID
  void _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _biometricService.authenticate();
      if (!mounted) return;

      if (success) {
        // Récupérer la session sauvegardée et aller au dashboard
        final hasSession = await _authService.hasSession();
        if (hasSession) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune session. Connectez-vous d\'abord avec votre PIN.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification biométrique échouée.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biométrie non disponible.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── LOGO ──────────────────────────────
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF1A56DB).withOpacity(0.13),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )],
                        ),
                        child: const Center(
                          child: Icon(Icons.shield_rounded,
                              color: Color(0xFF1A56DB), size: 46),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('AssurAncy',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1535A8),
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      const Text('ASSURANCE AUTO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B8DEF),
                              letterSpacing: 2)),
                      const SizedBox(height: 2),
                      const Text('BY MAURITANIE',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8EA8D8),
                              letterSpacing: 1.5)),

                      const Spacer(flex: 2),

                      // ── TÉLÉPHONE ─────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )],
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                          decoration: const InputDecoration(
                            hintText: 'Numéro de téléphone',
                            hintStyle: TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: Color(0xFFADBDD8), size: 21),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 4 CASES PIN ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          final filled = _pinControllers[index].text.isNotEmpty;
                          return Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: filled ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0),
                                width: filled ? 2 : 1.2,
                              ),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _pinControllers[index],
                                focusNode: _pinFocusNodes[index],
                                obscureText: true,
                                maxLength: 1,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A3DB5)),
                                onChanged: (v) => _onPinChanged(v, index),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // ── BOUTON CONNEXION ──────────────────
                      GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: double.infinity, height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A56DB),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF1A56DB).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            )],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Text('Connexion',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ BIOMÉTRIE : bouton empreinte / Face ID
                      if (_biometricAvailable) ...[
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFD0DCF0))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFD0DCF0))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _isLoading ? null : _handleBiometricLogin,
                          child: Container(
                            width: double.infinity, height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFF1A56DB), width: 1.5),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )],
                            ),
                            child: FutureBuilder<IconData>(
                              future: _getBiometricIcon(),
                              builder: (context, snapshot) {
                                final icon = snapshot.data ?? Icons.fingerprint_rounded;
                                final label = icon == Icons.face_rounded
                                    ? 'Connexion avec Face ID'
                                    : 'Connexion avec empreinte';
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon,
                                        color: const Color(0xFF1A56DB), size: 26),
                                    const SizedBox(width: 10),
                                    Text(label,
                                        style: const TextStyle(
                                            color: Color(0xFF1A56DB),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      const SizedBox(height: 14),

                      // ── MOT DE PASSE OUBLIÉ ───────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MotDePasseOubliePage()),
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF1A56DB),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF1A56DB),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── INSCRIPTION ───────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InscriptionPage()),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Nouvel utilisateur ? ',
                            style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5568)),
                            children: [
                              TextSpan(
                                text: "S'inscrire maintenant",
                                style: TextStyle(
                                    color: Color(0xFF1A56DB),
                                    fontWeight: FontWeight.w700),
                              )
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ── CONTACTS ──────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E8F5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mail_outline_rounded,
                                color: Color(0xFF4A5568), size: 18),
                            SizedBox(width: 8),
                            Text('Contacts',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF4A5568),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}