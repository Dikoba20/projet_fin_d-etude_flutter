import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../../core/services/paiement_service.dart';
import '../../core/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants.dart';

// ── Apps bancaires mauritaniennes ─────────────────────────────────────────────
class _AppBancaire {
  final String   key;
  final String   label;
  final String   desc;
  final Color    color;
  final Color    colorLight;
  final IconData icon;
  final String   logoUrl;

  const _AppBancaire({
    required this.key,
    required this.label,
    required this.desc,
    required this.color,
    required this.colorLight,
    required this.icon,
    required this.logoUrl,
  });
}

const _apps = [
  _AppBancaire(
    key: 'bankily',
    label: 'Bankily',
    desc: 'Banque Populaire de Mauritanie',
    color: Color(0xFF16A34A),
    colorLight: Color(0xFFDCFCE7),
    icon: Icons.account_balance_wallet_rounded,
    logoUrl: 'https://play-lh.googleusercontent.com/vvnJCU-dShmVadoCTJLbmVAcmLMtUb2_v6jJqMWEgK-qE1R67soRrL2zRCRTW2ntX3E=w120-h120-rw',
  ),
  _AppBancaire(
    key: 'masrvi',
    label: 'Masrvi',
    desc: 'Paiement mobile mauritanien',
    color: Color(0xFF1A56DB),
    colorLight: Color(0xFFDBEAFE),
    icon: Icons.phone_android_rounded,
    logoUrl: 'https://play-lh.googleusercontent.com/gFn8gTa3q8ICH3BXjC40Hv503gbfqdhG0bg6LwvZemJ5Y5coUnM1XqyvgZjb3z5zOg=w120-h120-rw',
  ),
  _AppBancaire(
    key: 'sedad',
    label: 'Sedad',
    desc: "Banque d'investissement mauritanienne",
    color: Color(0xFF166534),
    colorLight: Color(0xFFDCFCE7),
    icon: Icons.credit_card_rounded,
    logoUrl: 'https://play-lh.googleusercontent.com/A6y8kFPFnpnAMOiq9vFKFBkMHMQxLNGsNqHZCqKOgVhRm7a3Qhkze2IG3H_9TXYpnp0=w120-h120-rw',
  ),
  _AppBancaire(
    key: 'bimbank',
    label: 'Bimbank',
    desc: 'Banque Islamique de Mauritanie',
    color: Color(0xFF1E3A5F),
    colorLight: Color(0xFFDBEAFE),
    icon: Icons.account_balance_rounded,
    logoUrl: 'https://play-lh.googleusercontent.com/YMzGMJSjHJeOyHkUn3BqfEN5tU2kQ5TbAXEXYJqmIdRCiE0HVFoKI6wPc3s5KFJXRQ=w120-h120-rw',
  ),
  _AppBancaire(
    key: 'click',
    label: 'Click',
    desc: 'Banque Nationale de Mauritanie',
    color: Color(0xFF0E7490),
    colorLight: Color(0xFFE0F2FE),
    icon: Icons.touch_app_rounded,
    logoUrl: 'https://play-lh.googleusercontent.com/Rl8gPJuQRkJZhFRZqFEhFGIQKe8QkKpGiWvLBzpw3Bq2Yf9l3kXyQhTlcpvQNqxoLQ=w120-h120-rw',
  ),
];

Widget _logoWidget(_AppBancaire app, {double size = 40, double iconSize = 20}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      app.logoUrl,
      width: size, height: size, fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(width: size, height: size,
            child: Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: app.color,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            )));
      },
      errorBuilder: (_, __, ___) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: app.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(app.icon, color: app.color, size: iconSize),
      ),
    ),
  );
}

// ── Page principale ───────────────────────────────────────────────────────────
class NouveauPaiementPage extends StatefulWidget {
  final Map<String, dynamic>? contratInitial;
  const NouveauPaiementPage({super.key, this.contratInitial});

  @override
  State<NouveauPaiementPage> createState() => _NouveauPaiementPageState();
}

class _NouveauPaiementPageState extends State<NouveauPaiementPage> {
  static const _bleu1  = Color(0xFF1535A8);
  static const _bleu2  = Color(0xFF1A56DB);
  static const _bleu3  = Color(0xFF3B82F6);
  static const _vert   = Color(0xFF16A34A);
  static const _fond   = Color(0xFFF0F4FF);
  static const _border = Color(0xFFE2E8F0);
  static const _gris   = Color(0xFF8492A6);

  final _paiementService = PaiementService(ApiClient());
  final _authService     = AuthService();

  int                   _etape   = 1;
  Map<String, dynamic>? _contrat;
  _AppBancaire?         _app;
  bool                  _loading = false;
  String?               _erreur;
  Map<String, dynamic>? _resultat;

  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contratInitial != null) {
      _contrat = widget.contratInitial;
      _etape   = 2;
    }
  }

  @override
  void dispose() { _telCtrl.dispose(); super.dispose(); }

  Future<void> _payer() async {
    if (_contrat == null || _app == null || _telCtrl.text.length < 8) return;
    setState(() { _loading = true; _erreur = null; });
    try {
      final contratId = _contrat!['id']?.toString() ?? '';
      final montant   = double.tryParse(_contrat!['prime_montant']?.toString() ?? '0') ?? 0.0;

      final res = await _paiementService.payerMobile(
        contratId:   contratId,
        telephone:   _telCtrl.text.trim(),
        montant:     montant,
        appPaiement: _app!.key,
      );

      if (res['success'] == true || res['data'] != null) {
        setState(() { _resultat = res['data'] ?? res; _etape = 4; });
      } else {
        setState(() => _erreur = res['message'] ?? 'Erreur lors du paiement.');
      }
    } catch (e) {
      setState(() => _erreur = 'Erreur réseau : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fond,
      body: Column(children: [
        _header(context),
        if (_etape < 4) _indicateur(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _contenu(),
        )),
      ]),
    );
  }

  Widget _header(BuildContext context) {
    final titres = {1: 'Sélection du contrat', 2: 'Méthode de paiement', 3: 'Confirmer le paiement', 4: 'Paiement confirmé'};
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_bleu1, _bleu2, _bleu3], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Color(0x4D1A56DB), blurRadius: 20, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 18, left: 20, right: 20),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            if (_etape > 1 && _etape < 4) setState(() => _etape--);
            else Navigator.pop(context, _etape == 4);
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(titres[_etape] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _indicateur() {
    const etapes = ['Contrat', 'Méthode', 'Paiement'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: List.generate(etapes.length, (i) {
        final num = i + 1; final actif = _etape == num; final fait = _etape > num;
        return Expanded(child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fait ? _vert : actif ? _bleu2 : _border),
            child: Center(child: fait
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('$num', style: TextStyle(color: actif ? Colors.white : _gris, fontSize: 12, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 6),
          Text(etapes[i], style: TextStyle(fontSize: 12, fontWeight: actif ? FontWeight.w700 : FontWeight.normal, color: actif ? _bleu2 : _gris)),
          if (i < etapes.length - 1) ...[
            const SizedBox(width: 6),
            Expanded(child: Container(height: 2, color: fait ? _vert : _border)),
            const SizedBox(width: 6),
          ],
        ]));
      })),
    );
  }

  Widget _contenu() {
    switch (_etape) {
      case 1: return _StepContrat(authService: _authService, onSelect: (c) => setState(() { _contrat = c; _etape = 2; }));
      case 2: return _StepMethode(contrat: _contrat!, appChoisie: _app, onApp: (a) => setState(() => _app = a), onSuivant: () => setState(() => _etape = 3));
      case 3: return _StepPaiement(contrat: _contrat!, app: _app!, telCtrl: _telCtrl, loading: _loading, erreur: _erreur, onPayer: _payer);
      case 4: return _StepSucces(contrat: _contrat!, app: _app!, resultat: _resultat, authService: _authService, onTerminer: () => Navigator.pop(context, true));
      default: return const SizedBox();
    }
  }
}

// ── ÉTAPE 1 ───────────────────────────────────────────────────────────────────
class _StepContrat extends StatefulWidget {
  final AuthService authService;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _StepContrat({required this.authService, required this.onSelect});
  @override State<_StepContrat> createState() => _StepContratState();
}

class _StepContratState extends State<_StepContrat> {
  static const _violet      = Color(0xFF8B5CF6);
  static const _violetLight = Color(0xFFEDE9FE);
  static const _orange      = Color(0xFFEA580C);
  static const _orangeLight = Color(0xFFFFF0E6);
  static const _bleu2       = Color(0xFF1A56DB);
  static const _texte       = Color(0xFF1A1A2E);
  static const _gris        = Color(0xFF8492A6);
  static const _border      = Color(0xFFE2E8F0);
  static const _vert        = Color(0xFF22C55E);

  List<dynamic> _contrats = [];
  bool          _loading  = true;
  String?       _erreur;

  @override void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    try {
      final token = await widget.authService.getToken();
      final res   = await ApiClient().get('/contrats/', token: token);
      final liste = res['contrats'] ?? res['data'] ?? [];
      setState(() {
        _contrats = (liste as List).where((c) => c['statut'] == 'EN_ATTENTE').toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() { _erreur = 'Impossible de charger les contrats.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _bleu2)));
    if (_erreur != null) return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFF0E6), borderRadius: BorderRadius.circular(16), border: Border.all(color: _orange.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: _orange),
        const SizedBox(width: 12),
        Expanded(child: Text(_erreur!, style: const TextStyle(color: _orange))),
        TextButton(onPressed: () { setState(() { _loading = true; _erreur = null; }); _charger(); }, child: const Text('Réessayer')),
      ]),
    );
    if (_contrats.isEmpty) return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: const Column(children: [
        Icon(Icons.check_circle_outline, color: _vert, size: 48),
        SizedBox(height: 12),
        Text('Aucun contrat en attente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _texte)),
        SizedBox(height: 6),
        Text('Tous vos contrats sont à jour.', style: TextStyle(fontSize: 13, color: _gris)),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sélectionnez le contrat à payer :', style: TextStyle(fontSize: 13, color: _gris)),
      const SizedBox(height: 14),
      ..._contrats.map((c) {
        final type = c['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';
        return GestureDetector(
          onTap: () => widget.onSelect(Map<String, dynamic>.from(c)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border),
                boxShadow: const [BoxShadow(color: Color(0x0F1535A8), blurRadius: 12, offset: Offset(0, 2))]),
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: _violetLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.description_rounded, color: _violet, size: 22)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['numero_contrat'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, color: _texte, fontSize: 14)),
                    Text(type, style: const TextStyle(fontSize: 12, color: _gris)),
                  ]),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: _orangeLight, borderRadius: BorderRadius.circular(20)),
                  child: const Text('EN_ATTENTE', style: TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F4FF)),
              const SizedBox(height: 12),
              Row(children: [
                _col('Prime', '${c['prime_montant'] ?? '—'} MRU'),
                _col('Début', c['date_debut'] ?? '—'),
                _col('Fin', c['date_fin'] ?? '—'),
              ]),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _col(String label, String val) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: _gris)),
    const SizedBox(height: 2),
    Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _texte)),
  ]));
}

// ── ÉTAPE 2 ───────────────────────────────────────────────────────────────────
class _StepMethode extends StatelessWidget {
  final Map<String, dynamic>   contrat;
  final _AppBancaire?          appChoisie;
  final ValueChanged<_AppBancaire> onApp;
  final VoidCallback           onSuivant;

  static const _bleu1     = Color(0xFF1535A8);
  static const _bleu2     = Color(0xFF1A56DB);
  static const _blueLight = Color(0xFFDBEAFE);
  static const _texte     = Color(0xFF1A1A2E);
  static const _gris      = Color(0xFF8492A6);
  static const _border    = Color(0xFFE2E8F0);
  static const _grayLight = Color(0xFFF1F5F9);

  const _StepMethode({required this.contrat, required this.appChoisie, required this.onApp, required this.onSuivant});

  @override
  Widget build(BuildContext context) {
    final type = contrat['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _bleu2.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.description_rounded, color: _bleu2, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Contrat sélectionné', style: TextStyle(fontSize: 11, color: _bleu2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(contrat['numero_contrat'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, color: _bleu1, fontSize: 15)),
            Text('$type — ${contrat['prime_montant'] ?? '—'} MRU', style: const TextStyle(fontSize: 12, color: _texte)),
          ])),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('Choisissez votre application bancaire :', style: TextStyle(fontSize: 13, color: _gris, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55,
        children: _apps.map((app) {
          final sel = appChoisie?.key == app.key;
          return GestureDetector(
            onTap: () => onApp(app),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: sel ? app.colorLight : Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? app.color : _border, width: sel ? 2 : 1),
                boxShadow: [BoxShadow(color: sel ? app.color.withOpacity(0.15) : Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _logoWidget(app, size: 40, iconSize: 20),
                  if (sel) Container(width: 20, height: 20,
                      decoration: BoxDecoration(color: app.color, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 13)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: sel ? app.color : _texte)),
                  Text(app.desc, style: const TextStyle(fontSize: 10, color: _gris), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: appChoisie != null ? onSuivant : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _bleu2, disabledBackgroundColor: _grayLight, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
          ),
          child: const Text('Continuer →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

// ── ÉTAPE 3 ───────────────────────────────────────────────────────────────────
class _StepPaiement extends StatefulWidget {
  final Map<String, dynamic>  contrat;
  final _AppBancaire          app;
  final TextEditingController telCtrl;
  final bool                  loading;
  final String?               erreur;
  final VoidCallback          onPayer;

  const _StepPaiement({required this.contrat, required this.app, required this.telCtrl, required this.loading, required this.erreur, required this.onPayer});

  @override State<_StepPaiement> createState() => _StepPaiementState();
}

class _StepPaiementState extends State<_StepPaiement> {
  static const _gris      = Color(0xFF8492A6);
  static const _grayLight = Color(0xFFF1F5F9);
  static const _rouge     = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [widget.app.color.withOpacity(0.85), widget.app.color], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: widget.app.color.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        padding: const EdgeInsets.all(26),
        child: Column(children: [
          Container(
            width: 72, height: 72, padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ClipOval(child: Image.network(widget.app.logoUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(widget.app.icon, color: widget.app.color, size: 36))),
          ),
          const SizedBox(height: 12),
          const Text('Paiement via', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(widget.app.label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('${widget.contrat['prime_montant'] ?? '—'} MRU', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Réf : ${widget.contrat['numero_contrat'] ?? '—'}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 24),
      Text('Numéro de téléphone ${widget.app.label}', style: const TextStyle(fontSize: 13, color: _gris, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: widget.telCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Ex : 22 00 00 00',
          prefixIcon: Icon(Icons.phone_rounded, color: widget.app.color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.app.color, width: 2)),
          filled: true, fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: widget.app.colorLight, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(Icons.sms_rounded, color: widget.app.color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Un code de confirmation sera envoyé sur votre numéro ${widget.app.label}.', style: TextStyle(fontSize: 12, color: widget.app.color))),
        ]),
      ),
      if (widget.erreur != null) ...[
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.error_outline, color: _rouge, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.erreur!, style: const TextStyle(fontSize: 12, color: _rouge))),
          ]),
        ),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.telCtrl.text.length >= 8 && !widget.loading ? widget.onPayer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.app.color, disabledBackgroundColor: _grayLight, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
          ),
          child: widget.loading
              ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Traitement en cours...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ])
              : const Text('Payer maintenant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

// ── ÉTAPE 4 : Succès ──────────────────────────────────────────────────────────
class _StepSucces extends StatefulWidget {
  final Map<String, dynamic>  contrat;
  final _AppBancaire          app;
  final Map<String, dynamic>? resultat;
  final AuthService           authService;
  final VoidCallback          onTerminer;

  const _StepSucces({required this.contrat, required this.app, required this.resultat, required this.authService, required this.onTerminer});

  @override State<_StepSucces> createState() => _StepSuccesState();
}

class _StepSuccesState extends State<_StepSucces> {
  static const _bleu1       = Color(0xFF1535A8);
  static const _bleu2       = Color(0xFF1A56DB);
  static const _vert        = Color(0xFF16A34A);
  static const _vertLight   = Color(0xFFDCFCE7);
  static const _violet      = Color(0xFF8B5CF6);
  static const _violetLight = Color(0xFFEDE9FE);
  static const _texte       = Color(0xFF1A1A2E);
  static const _gris        = Color(0xFF8492A6);
  static const _border      = Color(0xFFE2E8F0);

  bool _downloadLoading = false;

  // ── Télécharger le PDF depuis Django ──────────────────────────────────────
  Future<void> _telechargerPDF() async {
    setState(() => _downloadLoading = true);
    try {
      final token     = await widget.authService.getToken();
      final contratId = widget.resultat?['contrat']?['id']
          ?? widget.contrat['id'];
      final url = '${AppConstants.baseUrl}/contrats/$contratId/attestation/';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // ✅ Téléchargement web via dart:html
        final blob   = html.Blob([response.bodyBytes], 'application/pdf');
        final anchor = html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
          ..setAttribute('download', 'attestation_${widget.contrat['numero_contrat'] ?? 'contrat'}.pdf')
          ..click();
        html.Url.revokeObjectUrl(anchor.href!);
      } else {
        _showError('Erreur lors du téléchargement (${response.statusCode})');
      }
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      setState(() => _downloadLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final num = widget.contrat['numero_contrat'] ?? '—';
    return Column(children: [
      const SizedBox(height: 24),
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(color: _vertLight, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _vertLight, spreadRadius: 12)]),
        child: const Icon(Icons.check_circle, color: _vert, size: 52),
      ),
      const SizedBox(height: 20),
      const Text('Paiement enregistré !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texte)),
      const SizedBox(height: 8),
      const Text('Votre paiement pour le contrat', style: TextStyle(fontSize: 14, color: _gris)),
      const SizedBox(height: 4),
      Text(num, style: const TextStyle(fontWeight: FontWeight.w800, color: _bleu2, fontSize: 16)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('a été enregistré via ', style: TextStyle(fontSize: 14, color: _gris)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: widget.app.colorLight, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 20, height: 20,
                child: ClipOval(child: Image.network(widget.app.logoUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(widget.app.icon, color: widget.app.color, size: 14)))),
            const SizedBox(width: 6),
            Text(widget.app.label, style: TextStyle(fontWeight: FontWeight.w800, color: widget.app.color, fontSize: 13)),
          ]),
        ),
      ]),
      const SizedBox(height: 28),

      // ── Bloc attestation PDF ───────────────────────────────────────────────
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_violetLight, Color(0xFFDDD6FE)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC4B5FD)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.picture_as_pdf, color: _violet, size: 22),
            SizedBox(width: 8),
            Text("Attestation d'assurance", style: TextStyle(fontWeight: FontWeight.w700, color: _violet, fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          const Text('Votre attestation PDF avec QR Code est prête à télécharger.', style: TextStyle(fontSize: 13, color: _texte)),
          const SizedBox(height: 16),

          // QR Code décoratif
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(color: _bleu1, borderRadius: BorderRadius.circular(8)),
                child: GridView.count(
                  crossAxisCount: 3, padding: const EdgeInsets.all(5),
                  crossAxisSpacing: 3, mainAxisSpacing: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(9, (i) => Container(
                    decoration: BoxDecoration(
                      color: [0,2,4,6,8].contains(i) ? _bleu1 : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('QR Code unique', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _texte)),
                Text('Lié au contrat $num', style: const TextStyle(fontSize: 11, color: _gris)),
                const Text('Vérifiable en temps réel', style: TextStyle(fontSize: 11, color: _gris)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ✅ Bouton Télécharger uniquement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadLoading ? null : _telechargerPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: _violet, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _downloadLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(_downloadLoading ? 'Téléchargement...' : 'Télécharger l\'attestation PDF',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onTerminer,
          style: ElevatedButton.styleFrom(
            backgroundColor: _bleu2, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
          ),
          child: const Text('Retour aux paiements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 40),
    ]);
  }
}