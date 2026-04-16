import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import 'nouveau_pin_page.dart';

class OtpResetPage extends StatefulWidget {
  final String telephone;
  final String? otpDebug;
  const OtpResetPage({super.key, required this.telephone, this.otpDebug});
  @override
  State<OtpResetPage> createState() => _OtpResetPageState();
}

class _OtpResetPageState extends State<OtpResetPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    if (widget.otpDebug != null && widget.otpDebug!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = widget.otpDebug![i];
      }
    }
  }

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) _otpFocusNodes[index + 1].requestFocus();
    else if (value.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
    setState(() {});
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _verifier() async {
    if (_otpCode.length < 6) {
      _showError('Entrez le code à 6 chiffres.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.post('/verifier-otp-reset/', {
        'telephone': widget.telephone,
        'otp_code':  _otpCode,
      });

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NouveauPinPage(
              resetToken: res['reset_token'],
              isWeb: kIsWeb, // ✅ passer la plateforme
            ),
          ),
        );
      } else {
        _showError(res['message'] ?? 'Code incorrect.');
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _renvoyer() async {
    try {
      final res = await _api.post('/mot-de-passe-oublie/', {
        'telephone': widget.telephone,
      });
      if (!mounted) return;
      final nouveauOtp = res['otp_debug']?.toString();
      if (nouveauOtp != null && nouveauOtp.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = nouveauOtp[i];
        }
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nouveauOtp != null
              ? 'Nouveau code : $nouveauOtp'
              : 'Nouveau code envoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Erreur lors du renvoi.');
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
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
                      child: const Center(
                          child: Icon(Icons.sms_outlined,
                              color: Color(0xFF1A56DB), size: 34)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Vérification',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1535A8))),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'Code envoyé à\n${widget.telephone}'
                          : 'Code envoyé au\n${widget.telephone}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8492A6),
                          height: 1.5),
                    ),

                    // ── BANDEAU DEV
                    if (widget.otpDebug != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bug_report,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text('DEV — Code : ${widget.otpDebug}',
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(flex: 2),

                    // ── 6 CASES OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final filled =
                            _otpControllers[index].text.isNotEmpty;
                        return Container(
                          width: 46, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A3DB5)),
                              onChanged: (v) => _onOtpChanged(v, index),
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

                    GestureDetector(
                      onTap: _isLoading ? null : _verifier,
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
                              : const Text('Vérifier',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _renvoyer,
                      child: const Text('Renvoyer le code',
                          style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF1A56DB),
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}