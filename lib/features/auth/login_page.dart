import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import 'inscription_page.dart';
import 'mot_de_passe_oublie_page.dart';
import '../../core/dashboard/dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';
import '../agent/agent_dashboard_page.dart';
import '../expert/expert_dashboard_page.dart';

// ═══════════════════════════════════════════════════════
// LOGO SVG ASSURANCY — dessiné avec CustomPainter
// ═══════════════════════════════════════════════════════
class AssurancyLogo extends StatelessWidget {
  final double size;
  const AssurancyLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AssurancyLogoPainter()),
    );
  }
}

class _AssurancyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1A56DB), const Color(0xFF0D3A9E)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: cx));
    canvas.drawCircle(Offset(cx, cy), cx, bgPaint);

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy * 0.55), cx * 0.55, glowPaint);

    final shieldPath = Path();
    final double sw = size.width * 0.52;
    final double sh = size.height * 0.56;
    final double sx = cx - sw / 2;
    final double sy = cy - sh / 2 - size.height * 0.04;

    shieldPath.moveTo(cx, sy);
    shieldPath.lineTo(sx + sw, sy + sh * 0.22);
    shieldPath.lineTo(sx + sw, sy + sh * 0.58);
    shieldPath.quadraticBezierTo(sx + sw, sy + sh, cx, sy + sh + sh * 0.08);
    shieldPath.quadraticBezierTo(sx, sy + sh, sx, sy + sh * 0.58);
    shieldPath.lineTo(sx, sy + sh * 0.22);
    shieldPath.close();

    final shieldPaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    final checkPaint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final checkPath = Path();
    checkPath.moveTo(cx - sw * 0.22, cy + sh * 0.01);
    checkPath.lineTo(cx - sw * 0.04, cy + sh * 0.18);
    checkPath.lineTo(cx + sw * 0.24, cy - sh * 0.14);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
// PAGE LOGIN
// ═══════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading          = false;
  bool _obscurePassword    = true;
  bool _biometricAvailable = false;
  String? _selectedRole;

  // ── Indicateurs de force du mot de passe (web uniquement)
  bool _hasUpper    = false;
  bool _hasLower    = false;
  bool _hasDigit    = false;
  bool _hasValidLen = false;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  final _authService      = AuthService();
  final _biometricService = BiometricService();

  final List<Map<String, dynamic>> _roles = [
    {'value': 'CLIENT', 'label': 'Client',              'icon': Icons.person_rounded},
    {'value': 'AGENT',  'label': "Agent d'assurance",   'icon': Icons.badge_rounded},
    {'value': 'EXPERT', 'label': 'Expert en sinistres', 'icon': Icons.manage_search_rounded},
    {'value': 'ADMIN',  'label': 'Administrateur',      'icon': Icons.admin_panel_settings_rounded},
  ];

  // Web : AGENT + ADMIN utilisent email + password fort
  bool get _isWebRole =>
      kIsWeb && (_selectedRole == 'AGENT' || _selectedRole == 'ADMIN');

  // ════════════════════════════════════════════════
  // VALIDATION MOT DE PASSE FORT (web uniquement)
  // Règles : majuscule + minuscule + chiffre + 6-8 caractères
  // ════════════════════════════════════════════════
  void _onPasswordChanged(String val) {
    if (!_isWebRole) return;
    setState(() {
      _hasUpper    = val.contains(RegExp(r'[A-Z]'));
      _hasLower    = val.contains(RegExp(r'[a-z]'));
      _hasDigit    = val.contains(RegExp(r'[0-9]'));
      _hasValidLen = val.length >= 6 && val.length <= 8;
    });
  }

  bool get _passwordValide =>
      !_isWebRole || (_hasUpper && _hasLower && _hasDigit && _hasValidLen);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<IconData> _getBiometricIcon() async {
    final types = await _biometricService.getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return Icons.face_rounded;
    return Icons.fingerprint_rounded;
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════
  // REDIRECTION SELON LE RÔLE
  // ADMIN  → AdminDashboardPage
  // AGENT  → AgentDashboardPage
  // EXPERT → ExpertDashboardPage
  // CLIENT → DashboardPage
  // ════════════════════════════════════════════════
  void _redirecterSelonRole(String role) {
    if (!mounted) return;
    Widget destination;
    switch (role) {
      case 'ADMIN':
        destination = const AdminDashboardPage();
        break;
      case 'AGENT':
        destination = const AgentDashboardPage();
        break;
      case 'EXPERT':
        destination = const ExpertDashboardPage();
        break;
      default:
        destination = const DashboardPage();
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => destination));
  }

  // ════════════════════════════════════════════════
  // VÉRIFICATION PLATEFORME SELON RÔLE
  // Web    : AGENT, ADMIN
  // Mobile : CLIENT, AGENT (EXPERT retiré mobile)
  // ════════════════════════════════════════════════
  bool _rolePlatformeAutorisee(String role) {
    if (kIsWeb) return role == 'AGENT' || role == 'ADMIN';
    return role == 'CLIENT' || role == 'AGENT';
  }

  // ════════════════════════════════════════════════
  // LOGIN PRINCIPAL
  // Web  + AGENT/ADMIN → POST /connexion-agent/ (email + password fort)
  // Mobile + tout rôle → POST /connexion/       (telephone + code_pin)
  // ════════════════════════════════════════════════
  void _handleLogin() async {
    final input    = _emailController.text.trim();
    final password = _passwordController.text;

    if (_selectedRole == null) {
      _showSnack('Veuillez sélectionner votre rôle.', Colors.orange);
      return;
    }

    if (!_rolePlatformeAutorisee(_selectedRole!)) {
      final roleLabel =
          _roles.firstWhere((r) => r['value'] == _selectedRole)['label'] as String;
      _showPlatformeDialog(roleLabel);
      return;
    }

    if (input.isEmpty || password.isEmpty) {
      _showSnack('Veuillez remplir tous les champs.', Colors.red);
      return;
    }

    if (_isWebRole && !input.contains('@')) {
      _showSnack('Adresse email invalide.', Colors.red);
      return;
    }

    // ✅ Validation mot de passe fort côté web
    if (_isWebRole && !_passwordValide) {
      _showSnack(
          'Mot de passe invalide : majuscule, minuscule, chiffre requis (6-8 caractères).',
          Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> res;

      if (_isWebRole) {
        res = await _authService.connecterAgent(
          email:    input,
          password: password,
        );
      } else {
        res = await _authService.connecter(
          telephone: input,
          codePin:   password,
        );
      }

      if (res['success'] == true) {
        await _authService.sauvegarderSession(res['token'], res['user']);
        if (!mounted) return;
        final role = res['user']['role'] ?? _selectedRole!;
        _redirecterSelonRole(role);
      } else {
        _showSnack(res['message'] ?? 'Identifiants incorrects.', Colors.red);
      }
    } catch (e) {
      _showSnack('Impossible de joindre le serveur.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Login biométrique
  void _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _biometricService.authenticate();
      if (!mounted) return;
      if (success) {
        final hasSession = await _authService.hasSession();
        if (hasSession) {
          final role = await _authService.getRole();
          _redirecterSelonRole(role);
        } else {
          _showSnack("Aucune session. Connectez-vous d'abord.", Colors.orange);
        }
      } else {
        _showSnack('Authentification biométrique échouée.', Colors.red);
      }
    } catch (e) {
      _showSnack('Biométrie non disponible.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPlatformeDialog(String roleLabel) {
    final isWeb = kIsWeb;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          isWeb ? Icons.phone_android_rounded : Icons.computer_rounded,
          color: const Color(0xFF1A56DB),
          size: 48,
        ),
        title: const Text('Accès non autorisé',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF1535A8))),
        content: Text(
          isWeb
              ? 'Le rôle "$roleLabel" n\'est pas disponible sur le web.\nVeuillez utiliser l\'application mobile.'
              : 'Le rôle "$roleLabel" est accessible uniquement depuis l\'interface web.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris',
                style: TextStyle(
                    color: Color(0xFF1A56DB), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Rôles filtrés selon la plateforme
  // Web    : AGENT + ADMIN
  // Mobile : CLIENT + AGENT (EXPERT retiré)
  List<Map<String, dynamic>> get _rolesDisponibles {
    return _roles.where((r) {
      final v = r['value'] as String;
      if (kIsWeb) return v == 'AGENT' || v == 'ADMIN';
      return v == 'CLIENT' || v == 'AGENT';
    }).toList();
  }

  String get _inputHint =>
      _isWebRole ? 'Adresse email' : 'Numéro de téléphone';

  IconData get _inputIcon =>
      _isWebRole ? Icons.email_outlined : Icons.phone_outlined;

  TextInputType get _inputKeyboardType =>
      _isWebRole ? TextInputType.emailAddress : TextInputType.phone;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ── LOGO
                      const AssurancyLogo(size: 92),
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

                      const SizedBox(height: 36),

                      // ── SÉLECTION DU RÔLE
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedRole != null
                                ? const Color(0xFF1A56DB)
                                : const Color(0xFFD0DCF0),
                            width: _selectedRole != null ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Row(children: [
                                Icon(Icons.group_rounded,
                                    color: Color(0xFFADBDD8), size: 21),
                                SizedBox(width: 12),
                                Text('Sélectionner votre rôle',
                                    style: TextStyle(
                                        color: Color(0xFFADBDD8),
                                        fontSize: 14)),
                              ]),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            borderRadius: BorderRadius.circular(14),
                            items: _rolesDisponibles
                                .map((role) => DropdownMenuItem<String>(
                                      value: role['value'] as String,
                                      child: Row(children: [
                                        Icon(role['icon'] as IconData,
                                            color: const Color(0xFF1A56DB),
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Text(role['label'] as String,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1A1A2E),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                                _emailController.clear();
                                _passwordController.clear();
                                _hasUpper    = false;
                                _hasLower    = false;
                                _hasDigit    = false;
                                _hasValidLen = false;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── CHAMP IDENTIFIANT (email ou téléphone)
                      _buildTextField(
                        controller: _emailController,
                        hint: _inputHint,
                        icon: _inputIcon,
                        keyboardType: _inputKeyboardType,
                      ),

                      const SizedBox(height: 14),

                      // ── MOT DE PASSE / CODE PIN
                      _buildTextField(
                        controller: _passwordController,
                        hint: _isWebRole ? 'Mot de passe' : 'Code PIN',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        onChanged: _onPasswordChanged,
                        maxLength: _isWebRole ? 8 : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFADBDD8),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      // ── INDICATEURS MOT DE PASSE FORT (web uniquement)
                      if (_isWebRole &&
                          _passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFD0DCF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Exigences du mot de passe :',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4A5568))),
                              const SizedBox(height: 6),
                              _PasswordRule(
                                  'Au moins une majuscule (A-Z)', _hasUpper),
                              _PasswordRule(
                                  'Au moins une minuscule (a-z)', _hasLower),
                              _PasswordRule(
                                  'Au moins un chiffre (0-9)', _hasDigit),
                              _PasswordRule(
                                  'Entre 6 et 8 caractères', _hasValidLen),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── BOUTON CONNEXION
                      GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A56DB),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF1A56DB)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7))
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                : const Text('Se connecter',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── BIOMÉTRIE (mobile uniquement)
                      if (_biometricAvailable && !kIsWeb) ...[
                        Row(children: [
                          const Expanded(
                              child: Divider(color: Color(0xFFD0DCF0))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12)),
                          ),
                          const Expanded(
                              child: Divider(color: Color(0xFFD0DCF0))),
                        ]),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _isLoading ? null : _handleBiometricLogin,
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFF1A56DB),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: FutureBuilder<IconData>(
                              future: _getBiometricIcon(),
                              builder: (context, snapshot) {
                                final icon = snapshot.data ??
                                    Icons.fingerprint_rounded;
                                final label = icon == Icons.face_rounded
                                    ? 'Connexion avec Face ID'
                                    : 'Connexion avec empreinte';
                                return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(icon,
                                          color: const Color(0xFF1A56DB),
                                          size: 26),
                                      const SizedBox(width: 10),
                                      Text(label,
                                          style: const TextStyle(
                                              color: Color(0xFF1A56DB),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                    ]);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      const SizedBox(height: 16),

                      // ── MOT DE PASSE OUBLIÉ
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MotDePasseOubliePage())),
                        child: const Text('Mot de passe oublié ?',
                            style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF1A56DB),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF1A56DB))),
                      ),

                      const SizedBox(height: 28),

                      // ── INSCRIPTION (mobile uniquement)
                      if (!kIsWeb)
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const InscriptionPage())),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Nouvel utilisateur ? ',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF4A5568)),
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

                      const SizedBox(height: 28),

                      // ── CONTACTS
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE0E8F5)),
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
                            ]),
                      ),

                      const SizedBox(height: 32),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    int? maxLength,
  }) {
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
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFFADBDD8), size: 21),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '', // masquer le compteur maxLength
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ── Widget indicateur de règle de mot de passe
class _PasswordRule extends StatelessWidget {
  final String label;
  final bool valid;
  const _PasswordRule(this.label, this.valid);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(
          valid
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: valid
              ? const Color(0xFF16A34A)
              : const Color(0xFFADBDD8),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: valid
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF8EA8D8))),
      ]),
    );
  }
}