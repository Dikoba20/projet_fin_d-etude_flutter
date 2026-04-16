import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

// ═══════════════════════════════════════════════════════
// PAGE NOUVEAU PIN / NOUVEAU MOT DE PASSE
// ── Mobile (client/agent) → PIN 4 chiffres
// ── Web    (admin/agent)  → Mot de passe fort (maj+min+chiffre, 6-8 car)
// ═══════════════════════════════════════════════════════
class NouveauPinPage extends StatefulWidget {
  final String resetToken;
  final bool   isWeb;
  const NouveauPinPage({
    super.key,
    required this.resetToken,
    this.isWeb = false,
  });
  @override
  State<NouveauPinPage> createState() => _NouveauPinPageState();
}

class _NouveauPinPageState extends State<NouveauPinPage> {

  // ── MOBILE : PIN 4 cases
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _confirmControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _confirmFocusNodes =
      List.generate(4, (_) => FocusNode());

  // ── WEB : champs mot de passe texte
  final _mdpController     = TextEditingController();
  final _mdpConfirmController = TextEditingController();
  bool _obscureMdp        = true;
  bool _obscureConfirm    = true;

  // ── Indicateurs force mot de passe (web)
  bool _hasUpper    = false;
  bool _hasLower    = false;
  bool _hasDigit    = false;
  bool _hasValidLen = false;

  bool _isLoading = false;
  final _api = ApiClient();

  bool get _isWeb => widget.isWeb || kIsWeb;

  @override
  void dispose() {
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    for (var c in _confirmControllers) c.dispose();
    for (var f in _confirmFocusNodes) f.dispose();
    _mdpController.dispose();
    _mdpConfirmController.dispose();
    super.dispose();
  }

  // ── Navigation cases PIN mobile
  void _onPinChanged(String value, int index,
      List<TextEditingController> controllers, List<FocusNode> nodes) {
    if (value.length == 1 && index < 3) nodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) nodes[index - 1].requestFocus();
    setState(() {});
  }

  // ── Indicateurs mot de passe fort (web)
  void _onMdpChanged(String val) {
    setState(() {
      _hasUpper    = val.contains(RegExp(r'[A-Z]'));
      _hasLower    = val.contains(RegExp(r'[a-z]'));
      _hasDigit    = val.contains(RegExp(r'[0-9]'));
      _hasValidLen = val.length >= 6 && val.length <= 8;
    });
  }

  bool get _mdpValide =>
      _hasUpper && _hasLower && _hasDigit && _hasValidLen;

  String get _pin        => _pinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmControllers.map((c) => c.text).join();

  void _reinitialiser() async {
    if (_isWeb) {
      // ── Validation mot de passe fort
      final mdp     = _mdpController.text;
      final confirm = _mdpConfirmController.text;

      if (mdp.isEmpty) {
        _showError('Entrez votre nouveau mot de passe.');
        return;
      }
      if (!_mdpValide) {
        _showError(
            'Mot de passe invalide : majuscule, minuscule, chiffre requis (6-8 caractères).');
        return;
      }
      if (mdp != confirm) {
        _showError('Les mots de passe ne correspondent pas.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final res = await _api.post('/reinitialiser-mot-de-passe/', {
          'reset_token':           widget.resetToken,
          'nouveau_mot_de_passe':  mdp,     // ✅
          'confirmer_mot_de_passe': confirm, // ✅
        });

        if (res['success'] == true) {
          if (!mounted) return;
          _showSuccess('Mot de passe réinitialisé avec succès !');
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          _showError(res['message'] ?? 'Erreur inconnue.');
        }
      } catch (e) {
        _showError('Erreur de connexion au serveur.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ── Validation PIN 4 chiffres (mobile)
      if (_pin.length < 4) {
        _showError('Entrez un code PIN à 4 chiffres.');
        return;
      }
      if (_confirmPin.length < 4) {
        _showError('Confirmez votre code PIN.');
        return;
      }
      if (_pin != _confirmPin) {
        _showError('Les codes PIN ne correspondent pas.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final res = await _api.post('/reinitialiser-pin/', {
          'reset_token':   widget.resetToken,
          'nouveau_pin':   _pin,
          'confirmer_pin': _confirmPin,
        });

        if (res['success'] == true) {
          if (!mounted) return;
          _showSuccess('PIN réinitialisé avec succès !');
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          _showError(res['message'] ?? 'Erreur inconnue.');
        }
      } catch (e) {
        _showError('Erreur de connexion au serveur.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── ICONE
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: const Color(0xFF1A56DB).withOpacity(0.13),
                            blurRadius: 20,
                            offset: const Offset(0, 6))],
                      ),
                      child: Center(
                        child: Icon(
                          _isWeb
                              ? Icons.lock_person_rounded
                              : Icons.lock_outline_rounded,
                          color: const Color(0xFF1A56DB),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── TITRE
                    Text(
                      _isWeb ? 'Nouveau mot de passe' : 'Nouveau PIN',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1535A8)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isWeb
                          ? 'Choisissez un mot de passe sécurisé\n(majuscule, minuscule, chiffre, 6-8 caractères).'
                          : 'Choisissez un nouveau code PIN à 4 chiffres.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8EA8D8),
                          height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // ════════════════════════════════════════════
                    // WEB : champs mot de passe texte fort
                    // ════════════════════════════════════════════
                    if (_isWeb) ...[

                      // ── Nouveau mot de passe
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Nouveau mot de passe *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1535A8))),
                      ),
                      const SizedBox(height: 10),
                      _buildWebField(
                        controller: _mdpController,
                        hint: 'Nouveau mot de passe',
                        obscure: _obscureMdp,
                        maxLength: 8,
                        onChanged: _onMdpChanged,
                        onToggleObscure: () =>
                            setState(() => _obscureMdp = !_obscureMdp),
                      ),

                      // ── Indicateurs force
                      if (_mdpController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFD0DCF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Exigences :',
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

                      const SizedBox(height: 20),

                      // ── Confirmer mot de passe
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Confirmer le mot de passe *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1535A8))),
                      ),
                      const SizedBox(height: 10),
                      _buildWebField(
                        controller: _mdpConfirmController,
                        hint: 'Confirmer le mot de passe',
                        obscure: _obscureConfirm,
                        maxLength: 8,
                        onChanged: (_) => setState(() {}),
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),

                      // ── Vérification correspondance
                      if (_mdpConfirmController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(
                            _mdpController.text ==
                                    _mdpConfirmController.text
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 14,
                            color: _mdpController.text ==
                                    _mdpConfirmController.text
                                ? const Color(0xFF16A34A)
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _mdpController.text == _mdpConfirmController.text
                                ? 'Les mots de passe correspondent'
                                : 'Les mots de passe ne correspondent pas',
                            style: TextStyle(
                                fontSize: 11,
                                color: _mdpController.text ==
                                        _mdpConfirmController.text
                                    ? const Color(0xFF16A34A)
                                    : Colors.red),
                          ),
                        ]),
                      ],
                    ],

                    // ════════════════════════════════════════════
                    // MOBILE : PIN 4 cases
                    // ════════════════════════════════════════════
                    if (!_isWeb) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Nouveau code PIN *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1535A8))),
                      ),
                      const SizedBox(height: 12),
                      _buildPinRow(_pinControllers, _pinFocusNodes),
                      const SizedBox(height: 28),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Confirmer le code PIN *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1535A8))),
                      ),
                      const SizedBox(height: 12),
                      _buildPinRow(_confirmControllers, _confirmFocusNodes),
                    ],

                    const SizedBox(height: 36),

                    // ── BOUTON
                    GestureDetector(
                      onTap: _isLoading ? null : _reinitialiser,
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(
                              color:
                                  const Color(0xFF1A56DB).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 7))],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _isWeb
                                      ? 'Réinitialiser le mot de passe'
                                      : 'Réinitialiser le PIN',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
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

  // ── Champ texte mot de passe (web)
  Widget _buildWebField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    void Function(String)? onChanged,
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
        obscureText: obscure,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: Color(0xFFADBDD8), size: 21),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFADBDD8),
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Rangée de cases PIN (mobile)
  Widget _buildPinRow(
      List<TextEditingController> controllers, List<FocusNode> nodes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        final filled = controllers[index].text.isNotEmpty;
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
              controller: controllers[index],
              focusNode: nodes[index],
              obscureText: true,
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3DB5)),
              onChanged: (v) =>
                  _onPinChanged(v, index, controllers, nodes),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero),
            ),
          ),
        );
      }),
    );
  }
}

// ── Widget indicateur de règle
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
          color: valid ? const Color(0xFF16A34A) : const Color(0xFFADBDD8),
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