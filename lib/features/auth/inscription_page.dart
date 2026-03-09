import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/auth_service.dart';
import 'otp_page.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});
  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _nomController       = TextEditingController();
  final _prenomController    = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nniController       = TextEditingController();
  final _emailController     = TextEditingController();
  final _adresseController   = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());

  File? _photoFile;
  bool _isLoading = false;
  final _authService = AuthService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _nniController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // VALIDATIONS
  // ══════════════════════════════════════════════════════

  // ✅ Téléphone mauritanien : 8 chiffres, commence par 2, 3 ou 4
  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^[234]\d{7}$').hasMatch(cleaned);
  }

  // ✅ PIN : 4 chiffres, pas tous identiques, pas séquentiels
  bool _isValidPin(String pin) {
    if (pin.length != 4) return false;
    if (pin.split('').toSet().length == 1) return false;
    final d = pin.codeUnits;
    if (d[1] == d[0]+1 && d[2] == d[1]+1 && d[3] == d[2]+1) return false;
    if (d[1] == d[0]-1 && d[2] == d[1]-1 && d[3] == d[2]-1) return false;
    return true;
  }

  // ✅ Email valide
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  // ✅ NNI mauritanien : exactement 10 chiffres
  bool _isValidNni(String nni) {
    return RegExp(r'^\d{10}$').hasMatch(nni);
  }

  // ══════════════════════════════════════════════════════
  // PHOTO
  // ══════════════════════════════════════════════════════

  void _choisirPhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1A56DB)),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _photoFile = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1A56DB)),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _photoFile = File(picked.path));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PIN
  // ══════════════════════════════════════════════════════

  void _onPinChanged(String value, int index) {
    if (value.length == 1 && index < 3) _pinFocusNodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) _pinFocusNodes[index - 1].requestFocus();
    setState(() {});
  }

  String get _pinCode => _pinControllers.map((c) => c.text).join();

  // ══════════════════════════════════════════════════════
  // INSCRIPTION
  // ══════════════════════════════════════════════════════

  void _inscrire() async {
    final nom       = _nomController.text.trim();
    final prenom    = _prenomController.text.trim();
    final telephone = _telephoneController.text.trim();
    final nni       = _nniController.text.trim();
    final email     = _emailController.text.trim();
    final pin       = _pinCode;

    if (nom.isEmpty || prenom.isEmpty || telephone.isEmpty || pin.length < 4) {
      _showError('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (!_isValidPhone(telephone)) {
      _showError('Numéro invalide.\nDoit contenir 8 chiffres et commencer par 2, 3 ou 4.\nEx : 22123456');
      return;
    }

    if (!_isValidPin(pin)) {
      _showError('Code PIN trop faible.\n• Pas 4 chiffres identiques (ex: 4444)\n• Pas de séquence (ex: 1234 ou 4321)');
      return;
    }

    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showError('Adresse email invalide.\nEx : exemple@gmail.com');
      return;
    }

    if (nni.isNotEmpty && !_isValidNni(nni)) {
      _showError('NNI invalide.\nDoit contenir exactement 10 chiffres.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _authService.inscrire(
        nom:       nom,
        prenom:    prenom,
        telephone: telephone,
        codePin:   pin,
        nni:       nni,
        email:     email,
        adresse:   _adresseController.text.trim(),
        photo:     _photoFile,
      );

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              telephone: telephone,
              otpDebug: res['otp_debug']?.toString(),
            ),
          ),
        );
      } else {
        _showError(res['errors']?.toString() ?? res['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur.');
    } finally {
      setState(() => _isLoading = false);
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

  // ══════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── PHOTO ────────────────────────────
                    GestureDetector(
                      onTap: _choisirPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1A56DB), width: 2),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF1A56DB).withOpacity(0.13),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )],
                              image: _photoFile != null
                                  ? DecorationImage(
                                      image: FileImage(_photoFile!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _photoFile == null
                                ? const Center(
                                    child: Icon(Icons.person_outline_rounded,
                                        color: Color(0xFF1A56DB), size: 40))
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1A56DB), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _photoFile == null ? 'Ajouter une photo' : 'Modifier la photo',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A56DB),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    const Text('Créer un compte',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1535A8))),
                    const SizedBox(height: 4),
                    const Text('Rejoignez AssurAncy',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8EA8D8))),
                    const SizedBox(height: 28),

                    _buildField(_prenomController, 'Prénom *', Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _buildField(_nomController, 'Nom *', Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _buildField(_telephoneController, 'Téléphone * (ex: 22123456)',
                        Icons.phone_outlined,
                        type: TextInputType.phone, maxLength: 8),
                    const SizedBox(height: 14),
                    _buildField(_nniController, 'NNI (optionnel)',
                        Icons.badge_outlined,
                        type: TextInputType.number, maxLength: 10),
                    const SizedBox(height: 14),
                    _buildField(_emailController, 'Email (optionnel)',
                        Icons.email_outlined,
                        type: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _buildField(_adresseController, 'Adresse (optionnel)',
                        Icons.location_on_outlined),
                    const SizedBox(height: 24),

                    // ── PIN ──────────────────────────────
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Choisissez votre code PIN *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1535A8))),
                    ),
                    const SizedBox(height: 12),
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
                              color: filled
                                  ? const Color(0xFF1A56DB)
                                  : const Color(0xFFD0DCF0),
                              width: filled ? 2 : 1.2,
                            ),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))],
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
                                  contentPadding: EdgeInsets.zero),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // ── BOUTON S'INSCRIRE ────────────────
                    GestureDetector(
                      onTap: _isLoading ? null : _inscrire,
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFF1A56DB).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 7))],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text("S'inscrire",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5568)),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                  color: Color(0xFF1A56DB),
                                  fontWeight: FontWeight.w700),
                            )
                          ],
                        ),
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
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? type,
    int? maxLength,
  }) {
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
        maxLength: maxLength,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFADBDD8), size: 21),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}