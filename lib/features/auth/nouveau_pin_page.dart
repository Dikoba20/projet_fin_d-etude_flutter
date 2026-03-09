import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class NouveauPinPage extends StatefulWidget {
  final String resetToken;
  const NouveauPinPage({super.key, required this.resetToken});
  @override
  State<NouveauPinPage> createState() => _NouveauPinPageState();
}

class _NouveauPinPageState extends State<NouveauPinPage> {
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _confirmControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _confirmFocusNodes =
      List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  final _api = ApiClient();

  @override
  void dispose() {
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    for (var c in _confirmControllers) c.dispose();
    for (var f in _confirmFocusNodes) f.dispose();
    super.dispose();
  }

  void _onPinChanged(String value, int index, List<TextEditingController> controllers, List<FocusNode> nodes) {
    if (value.length == 1 && index < 3) nodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) nodes[index - 1].requestFocus();
    setState(() {});
  }

  String get _pin        => _pinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmControllers.map((c) => c.text).join();

  void _reinitialiser() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN réinitialisé avec succès !'), backgroundColor: Colors.green),
        );
        // Retour à la page de connexion
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showError(res['message'] ?? 'Erreur inconnue.');
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.13), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: const Center(child: Icon(Icons.lock_outline_rounded, color: Color(0xFF1A56DB), size: 36)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nouveau PIN',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
                    const SizedBox(height: 8),
                    const Text(
                      'Choisissez un nouveau code PIN à 4 chiffres.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF8EA8D8), height: 1.5),
                    ),
                    const SizedBox(height: 36),

                    // NOUVEAU PIN
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nouveau code PIN *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1535A8))),
                    ),
                    const SizedBox(height: 12),
                    _buildPinRow(_pinControllers, _pinFocusNodes),
                    const SizedBox(height: 28),

                    // CONFIRMER PIN
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Confirmer le code PIN *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1535A8))),
                    ),
                    const SizedBox(height: 12),
                    _buildPinRow(_confirmControllers, _confirmFocusNodes),
                    const SizedBox(height: 36),

                    // BOUTON
                    GestureDetector(
                      onTap: _isLoading ? null : _reinitialiser,
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Réinitialiser le PIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildPinRow(List<TextEditingController> controllers, List<FocusNode> nodes) {
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
              color: filled ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0),
              width: filled ? 2 : 1.2,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: TextField(
              controller: controllers[index],
              focusNode: nodes[index],
              obscureText: true,
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A3DB5)),
              onChanged: (v) => _onPinChanged(v, index, controllers, nodes),
              decoration: const InputDecoration(border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.zero),
            ),
          ),
        );
      }),
    );
  }
}