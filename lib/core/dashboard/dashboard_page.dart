// lib/core/dashboard/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/souscription_service.dart';
import '../services/paiement_service.dart';
import '../services/sinistre_service.dart';
import '../../core/api_client.dart';
import '../../features/auth/souscription_page.dart';
import '../../features/paiement/nouveau_paiement_page.dart';
import '../../features/sinistre/declaration_sinistre_page.dart';
import '../../features/profil/espace_personnel_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService         = AuthService();
  final _souscriptionService = SouscriptionService();
  late final _paiementService = PaiementService(ApiClient());
  final _sinistreService     = SinistreService();

  Map<String, String> _userInfo    = {};
  List<dynamic>       _vehicules   = [];
  List<dynamic>       _contrats    = [];
  List<dynamic>       _activites   = [];
  List<dynamic>       _paiements   = [];
  List<dynamic>       _sinistres   = [];
  bool                _loadingData = true;
  String?             _erreurReseau;
  int                 _currentIndex = 0;

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _bleu1  = Color(0xFF1535A8);
  static const _bleu2  = Color(0xFF1A56DB);
  static const _bleu3  = Color(0xFF3B82F6);
  static const _vert   = Color(0xFF16A34A);
  static const _rouge  = Color(0xFFDC2626);
  static const _orange = Color(0xFFEA580C);
  static const _violet = Color(0xFF7C3AED);
  static const _fond   = Color(0xFFF5F7FF);
  static const _texte  = Color(0xFF111827);
  static const _gris   = Color(0xFF6B7280);
  static const _card   = Color(0xFFFFFFFF);

  // ── Logique statuts ───────────────────────────────────────────────────────

  bool _estActif(dynamic statut) {
    final s = statut?.toString().toUpperCase() ?? '';
    return s == 'ACTIF' || s == 'ACTIVE';
  }

  bool _estAccepte(dynamic statut) {
    final s = statut?.toString().toUpperCase() ?? '';
    return s == 'ACCEPTE' || s == 'ACCEPTED' || s == 'APPROUVE';
  }

  bool _peutEtrePaye(Map<String, dynamic> contrat) {
    if (_estAccepte(contrat['statut'])) return true;
    if (_estActif(contrat['statut'])) {
      final aUnPaiement = _paiements.any((p) {
        final contratNum    = p['contrat_numero']?.toString() ?? p['contrat']?.toString() ?? '';
        final numeroContrat = contrat['numero_contrat']?.toString() ?? '';
        return contratNum == numeroContrat &&
            p['statut']?.toString().toUpperCase() == 'CONFIRME';
      });
      return !aUnPaiement;
    }
    return false;
  }

  List<dynamic> _extraireList(Map<String, dynamic> res, List<String> cles) {
    if (res['network_error'] == true) return [];
    for (final cle in cles) {
      if (res[cle] is List) return res[cle] as List;
    }
    if (res['results'] is List) return res['results'] as List;
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingData  = true;
      _erreurReseau = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final results = await Future.wait([
        _authService.getUserInfo(),
        _souscriptionService.getMesVehicules(),
        _souscriptionService.getMesContrats(),
        _paiementService.getPaiements(),
        _sinistreService.getSinistres(token: token),
      ]);

      final info  = results[0] as Map<String, String>;
      final resV  = results[1] as Map<String, dynamic>;
      final resC  = results[2] as Map<String, dynamic>;
      final resP  = results[3];
      final resS  = results[4] as Map<String, dynamic>;

      final hasNetworkError = [resV, resC, resS].any((r) => r['network_error'] == true);
      if (hasNetworkError) {
        final errMsg = [resV, resC, resS]
            .firstWhere((r) => r['network_error'] == true, orElse: () => {})['message'] as String?;
        setState(() => _erreurReseau = errMsg ?? 'Serveur inaccessible.');
      }

      final vehicules = _extraireList(resV, ['vehicules', 'results', 'data']);
      final contrats  = _extraireList(resC, ['contrats',  'results', 'data']);
      final sinistres = _extraireList(resS, ['sinistres', 'results', 'data']);
      final paiements = resP is List
          ? resP
          : _extraireList(resP as Map<String, dynamic>, ['paiements', 'results', 'data']);

      debugPrint('=== ${contrats.length} contrat(s) chargé(s)');
      for (final c in contrats) {
        debugPrint('  → ${c['numero_contrat']} | statut: ${c['statut']}');
      }

      setState(() {
        _userInfo  = info;
        _vehicules = vehicules;
        _contrats  = contrats;
        _paiements = paiements;
        _sinistres = sinistres;
        _activites = [];
        for (final c in _contrats.take(3)) {
          _activites.add({
            'icon':   'contrat',
            'titre':  'Contrat ${c['numero_contrat'] ?? ''}',
            'detail': c['statut'] ?? '',
            'date':   c['date_souscription'] ?? '',
          });
        }
      });
    } catch (e) {
      debugPrint('=== ERREUR _loadAll: $e');
      setState(() => _erreurReseau = 'Erreur inattendue : $e');
    } finally {
      setState(() => _loadingData = false);
    }
  }

  void _deconnecter() async {
    await _authService.deconnecter();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  void _allerSouscription() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SouscriptionPage()));
    _loadAll();
  }

  void _allerPaiement(Map<String, dynamic> contrat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NouveauPaiementPage(
          contratInitial: Map<String, dynamic>.from(contrat),
        ),
      ),
    );
    if (result == true) _loadAll();
  }

  void _allerDeclarerSinistre(Map<String, dynamic> contrat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeclarationSinistrePage(contrat: contrat)),
    );
    if (result == true) _loadAll();
  }

  void _allerEspacePersonnel() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EspacePersonnelPage()));
  }

  void _choisirContratPourSinistre(List<dynamic> contratsActifs) {
    if (contratsActifs.length == 1) {
      _allerDeclarerSinistre(Map<String, dynamic>.from(contratsActifs.first));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Choisir un contrat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _bleu1)),
          const SizedBox(height: 4),
          const Text('Selectionnez le contrat concerne par le sinistre',
              style: TextStyle(fontSize: 13, color: _gris)),
          const SizedBox(height: 16),
          ...contratsActifs.map((c) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _allerDeclarerSinistre(Map<String, dynamic>.from(c));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _fond,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _bleu2.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _bleu2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, color: _bleu2, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['numero_contrat'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _texte)),
                  Text(
                    '${c['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers'} - Expire le ${c['date_fin'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: _gris),
                  ),
                ])),
                const Icon(Icons.chevron_right_rounded, color: _gris),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  // ── BANNIÈRE ERREUR RÉSEAU ─────────────────────────────────────────────────
  Widget _buildErreurBanner() {
    if (_erreurReseau == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFC107)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFFB45309), size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Serveur inaccessible',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E))),
          const SizedBox(height: 3),
          Text(_erreurReseau!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF78350F))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loadAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ])),
      ]),
    );
  }

  // ── PAGE ACCUEIL ──────────────────────────────────────────────────────────
  Widget _buildAccueil() {
    final prenom = _userInfo['prenom'] ?? '';

    final contratActifPaye = _contrats.firstWhere(
      (c) => _estActif(c['statut']) && !_peutEtrePaye(c),
      orElse: () => null,
    );

    final enAttente = _contrats
        .where((c) => c['statut']?.toString().toUpperCase() == 'EN_ATTENTE')
        .length;

    final aPayerList = _contrats.where((c) => _peutEtrePaye(c)).toList();
    final aPayer = aPayerList.length;

    return RefreshIndicator(
      onRefresh: _loadAll, color: _bleu2,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── HEADER GRADIENT AVEC VOITURE ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bleu1, _bleu2, _bleu3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Ligne utilisateur
              Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bonjour, $prenom !',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Text('Espace assuré',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ])),
                GestureDetector(
                  onTap: _deconnecter,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // Alertes en attente
              if (enAttente > 0) ...[
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('$enAttente contrat(s) en cours de validation',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Alerte paiement
              if (aPayer > 0) ...[
                GestureDetector(
                  onTap: () => _allerPaiement(Map<String, dynamic>.from(aPayerList.first)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: _vert.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          aPayer == 1
                              ? 'Votre contrat est prêt — Appuyez pour payer'
                              : '$aPayer contrats prêts à payer',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Carte contrat actif
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: contratActifPaye != null
                      ? Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(contratActifPaye['numero_contrat'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Expire : ${contratActifPaye['date_fin'] ?? ''}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _vert, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Actif',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ])
                      : Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Aucun contrat actif',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Souscrire maintenant',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ])),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ]),
                ),
              ),
            ]),
          ),

          _buildErreurBanner(),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Actions rapides',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _texte)),
              const SizedBox(height: 14),
              Row(children: [
                _quickAction(Icons.add_circle_rounded, 'Souscrire', _bleu2, onTap: _allerSouscription),
                const SizedBox(width: 10),
                _quickAction(Icons.credit_card_rounded, 'Paiements', _orange, onTap: () => setState(() => _currentIndex = 3)),
                const SizedBox(width: 10),
                _quickAction(Icons.car_crash_rounded, 'Sinistres', _rouge, onTap: () => setState(() => _currentIndex = 4)),
                const SizedBox(width: 10),
                _quickAction(Icons.article_rounded, 'Contrats', _violet, onTap: () => setState(() => _currentIndex = 2)),
              ]),
            ]),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Mes vehicules',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _texte)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _bleu2.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Voir tout',
                        style: TextStyle(color: _bleu2, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (_loadingData)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _bleu2),
                ))
              else if (_vehicules.isEmpty)
                _emptyCard('Aucun vehicule enregistre', 'Souscrivez pour ajouter votre premier vehicule.', Icons.directions_car_rounded)
              else
                ..._vehicules.take(2).map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _vehiculeCard(v),
                )),
              const SizedBox(height: 10),
              _addCard('Nouvelle souscription', onTap: _allerSouscription),
            ]),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dernieres activites',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _texte)),
              const SizedBox(height: 14),
              if (_loadingData)
                const SizedBox()
              else if (_activites.isEmpty)
                _emptyCard('Aucune activite', 'Vos actions apparaitront ici.', Icons.history_rounded)
              else
                ..._activites.map((a) => _activiteItem(a)),
            ]),
          ),

          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  // ── PAGE VEHICULES ────────────────────────────────────────────────────────
  Widget _buildVehiclesPage() {
    return RefreshIndicator(
      onRefresh: _loadAll, color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader('Mes vehicules', Icons.directions_car_rounded, _bleu1, _bleu3)),
          SliverToBoxAdapter(child: _buildErreurBanner()),
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _bleu2),
            )))
          else if (_vehicules.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: _emptyCard('Aucun vehicule', 'Vos vehicules apparaitront ici apres souscription.', Icons.directions_car_rounded),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _vehiculeCard(_vehicules[i])),
                childCount: _vehicules.length,
              )),
            ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _addCard('Nouvelle souscription', onTap: _allerSouscription),
          )),
        ],
      ),
    );
  }

  // ── PAGE CONTRATS ─────────────────────────────────────────────────────────
  Widget _buildContratsPage() {
    return RefreshIndicator(
      onRefresh: _loadAll, color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader('Mes contrats', Icons.article_rounded, _bleu1, _bleu3)),
          SliverToBoxAdapter(child: _buildErreurBanner()),
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _bleu2),
            )))
          else if (_contrats.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: _emptyCard('Aucun contrat', 'Souscrivez votre premiere assurance.', Icons.article_rounded),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _contratCard(_contrats[i]),
                ),
                childCount: _contrats.length,
              )),
            ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _addCard('Nouvelle souscription', onTap: _allerSouscription),
          )),
        ],
      ),
    );
  }

  // ── PAGE PAIEMENTS ────────────────────────────────────────────────────────
  Widget _buildPaiementsPage() {
    final contratsAPayer = _contrats.where((c) => _peutEtrePaye(c)).toList();

    return RefreshIndicator(
      onRefresh: _loadAll, color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader(
            'Mes paiements',
            Icons.credit_card_rounded,
            const Color(0xFFB45309),
            const Color(0xFFF59E0B),
          )),
          SliverToBoxAdapter(child: _buildErreurBanner()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.06),
                  border: Border.all(color: _orange.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: _orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Contrats à payer",
                        style: TextStyle(fontWeight: FontWeight.w700, color: _orange, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      contratsAPayer.isNotEmpty
                          ? '${contratsAPayer.length} contrat(s) prêt(s) à être payé(s). Payez pour obtenir votre attestation.'
                          : 'Aucun contrat en attente de paiement.',
                      style: const TextStyle(fontSize: 12, color: _texte),
                    ),
                    if (contratsAPayer.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _allerPaiement(Map<String, dynamic>.from(contratsAPayer.first)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Payer maintenant',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ])),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Historique des paiements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _texte),
              ),
            ),
          ),

          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _bleu2),
            )))
          else if (_paiements.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _emptyCard('Aucun paiement', 'Vos paiements apparaitront ici.', Icons.receipt_long_rounded),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _paiementCard(_paiements[i]),
                ),
                childCount: _paiements.length,
              )),
            ),

          if (contratsAPayer.isNotEmpty) ...[
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Contrats prêts à payer',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _texte)),
            )),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _contratCard(contratsAPayer[i]),
                ),
                childCount: contratsAPayer.length,
              )),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── PAGE SINISTRES ────────────────────────────────────────────────────────
  Widget _buildSinistresPage() {
    final contratsActifs = _contrats.where((c) => _estActif(c['statut'])).toList();

    return RefreshIndicator(
      onRefresh: _loadAll, color: _rouge,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.car_crash_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Mes sinistres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                GestureDetector(
                  onTap: contratsActifs.isNotEmpty
                      ? () => _choisirContratPourSinistre(contratsActifs)
                      : () => _snackWarning('Aucun contrat actif disponible pour déclarer un sinistre.'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Row(children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Declarer',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: _buildErreurBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _rouge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: _rouge, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Declaration de sinistre',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _rouge, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(
                      contratsActifs.isEmpty
                          ? 'Aucun contrat actif trouve. Verifiez vos contrats ou contactez votre assureur.'
                          : 'Vous avez ${contratsActifs.length} contrat(s) actif(s). Appuyez sur "Declarer" pour signaler un accident.',
                      style: const TextStyle(fontSize: 12, color: _texte),
                    ),
                  ])),
                ]),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Historique des sinistres',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _texte)),
            ),
          ),
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _rouge),
            )))
          else if (_sinistres.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _emptyCard('Aucun sinistre declare',
                    'Vos declarations de sinistre apparaitront ici.', Icons.shield_rounded),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _sinistreCard(_sinistres[i]),
                ),
                childCount: _sinistres.length,
              )),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _snackWarning(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── PAGE PROFIL ───────────────────────────────────────────────────────────
  Widget _buildProfilPage() {
    final prenom  = _userInfo['prenom']  ?? '';
    final nom     = _userInfo['nom']     ?? '';
    final tel     = _userInfo['tel']     ?? '';
    final nni     = _userInfo['nni']     ?? '';
    final email   = _userInfo['email']   ?? '';
    final adresse = _userInfo['adresse'] ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_bleu1, _bleu2, _bleu3],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 12),
            Text('$prenom $nom',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(tel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _statProfil('${_vehicules.length}', 'Vehicules'),
              Container(width: 1, height: 30, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 24)),
              _statProfil('${_contrats.length}', 'Contrats'),
              Container(width: 1, height: 30, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 24)),
              _statProfil('${_sinistres.length}', 'Sinistres'),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            GestureDetector(
              onTap: _allerEspacePersonnel,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _bleu2.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Espace personnel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Resume, sinistres, documents, alertes',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            _profileItem(Icons.person_outline_rounded, 'Nom complet', '$prenom $nom'),
            _profileItem(Icons.phone_outlined, 'Telephone', tel),
            _profileItem(Icons.badge_outlined, 'NNI', nni.isNotEmpty ? nni : 'Non renseigne'),
            _profileItem(Icons.location_on_outlined, 'Adresse', adresse.isNotEmpty ? adresse : 'Non renseignee'),
            _profileItem(Icons.email_outlined, 'Email', email.isNotEmpty ? email : 'Non renseigne'),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _deconnecter,
              child: Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(
                  color: _rouge,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _rouge.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Se deconnecter',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 48),
      ]),
    );
  }

  // ── WIDGETS UTILITAIRES ───────────────────────────────────────────────────

  Widget _pageHeader(String titre, IconData icon, Color c1, Color c2) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Text(titre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _texte),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _vehiculeCard(Map<String, dynamic> v) {
    final estAssure = _contrats.any(
      (c) =>
          c['vehicule_id'].toString() == v['id'].toString() &&
          _estActif(c['statut']),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bleu2.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.directions_car_rounded, color: _bleu2, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${v['marque'] ?? ''} ${v['modele'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _texte)),
          const SizedBox(height: 3),
          Text('${v['immatriculation'] ?? ''}  •  ${v['annee'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: _gris)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: estAssure ? _vert.withOpacity(0.1) : _rouge.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            estAssure ? 'Assure' : 'Non assure',
            style: TextStyle(
              color: estAssure ? _vert : _rouge,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _contratCard(Map<String, dynamic> c) {
    final statut      = c['statut']?.toString().toUpperCase() ?? '';
    final isActif     = _estActif(c['statut']);
    final isEnAttente = statut == 'EN_ATTENTE';
    final isAccepte   = _estAccepte(c['statut']);
    final peutPayer   = _peutEtrePaye(c);

    Color color;
    String label;
    if (isActif && !peutPayer) {
      color = _vert;
      label = 'Actif';
    } else if (isAccepte || (isActif && peutPayer)) {
      color = _bleu2;
      label = isAccepte ? 'Accepté' : 'À payer';
    } else if (isEnAttente) {
      color = _orange;
      label = 'En attente';
    } else {
      color = _rouge;
      label = c['statut'] ?? '';
    }

    final type = c['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.article_rounded, color: _violet, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['numero_contrat'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _texte)),
            Text(type, style: const TextStyle(fontSize: 12, color: _gris)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0F4FF)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _infoChip('Prime', '${c['prime_montant'] ?? ''} MRU'),
          _infoChip('Debut', c['date_debut'] ?? ''),
          _infoChip('Fin', c['date_fin'] ?? ''),
        ]),
        if (isEnAttente) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _orange.withOpacity(0.4)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_time_rounded, color: _orange, size: 18),
              SizedBox(width: 8),
              Text("En attente de validation par l'assureur",
                  style: TextStyle(color: _orange, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ],
        if (peutPayer) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _allerPaiement(Map<String, dynamic>.from(c)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _bleu2.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Payer maintenant',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
        ],
        if (isActif && !peutPayer) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _vert.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _vert.withOpacity(0.4)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_rounded, color: _vert, size: 18),
              SizedBox(width: 8),
              Text('Contrat actif — Attestation disponible',
                  style: TextStyle(color: _vert, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _paiementCard(Map<String, dynamic> p) {
    final statut = (p['statut'] ?? '').toString().toUpperCase();
    final color  = statut == 'CONFIRME' ? _vert : _orange;
    final label  = statut == 'CONFIRME' ? 'Confirme' : 'En attente';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['reference'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _texte)),
            Text(p['contrat_numero'] ?? p['contrat']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: _gris)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0F4FF)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _infoChip('Montant', '${p['montant'] ?? ''} MRU'),
          _infoChip('Methode', p['methode'] ?? ''),
          _infoChip('Date', (p['date_paiement'] ?? '').toString().split('T').first),
        ]),
      ]),
    );
  }

  Widget _sinistreCard(Map<String, dynamic> s) {
    final statut = s['statut'] ?? 'DECLARE';
    Color color; String label;
    switch (statut.toString().toUpperCase()) {
      case 'DECLARE':  color = _orange; label = 'Declare';  break;
      case 'EN_COURS': color = _bleu2;  label = 'En cours'; break;
      case 'CLOTURE':  color = _vert;   label = 'Resolu';   break;
      case 'REJETE':   color = _rouge;  label = 'Rejete';   break;
      default:         color = _gris;   label = statut;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _rouge.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.car_crash_rounded, color: _rouge, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['numero_sinistre'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _texte)),
            Text((s['date_accident'] ?? '').toString().split('T').first,
                style: const TextStyle(fontSize: 12, color: _gris)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F4FF)),
        const SizedBox(height: 10),
        Text(s['description'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _texte)),
        if (s['lieu_accident'] != null && s['lieu_accident'].toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_rounded, color: _gris, size: 14),
            const SizedBox(width: 4),
            Expanded(child: Text(s['lieu_accident'],
                style: const TextStyle(fontSize: 12, color: _gris),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ]),
    );
  }

  Widget _infoChip(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _texte)),
    ],
  );

  Widget _activiteItem(Map<String, dynamic> a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _bleu2.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.article_rounded, color: _bleu2, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['titre'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _texte)),
        Text(a['detail'] ?? '',
            style: const TextStyle(fontSize: 11, color: _gris)),
      ])),
      Text((a['date'] ?? '').toString().split('T').first,
          style: const TextStyle(fontSize: 11, color: _gris)),
    ]),
  );

  Widget _addCard(String label, {required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bleu2.withOpacity(0.3), width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: _bleu2.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.add_rounded, color: _bleu2, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: _bleu2, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );

  Widget _emptyCard(String titre, String sous, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _bleu2.withOpacity(0.06), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFFADBDD8), size: 32),
      ),
      const SizedBox(height: 12),
      Text(titre,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF374151))),
      const SizedBox(height: 4),
      Text(sous,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _gris)),
    ]),
  );

  Widget _statProfil(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  ]);

  Widget _profileItem(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _bleu2.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _bleu2, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _texte)),
      ])),
    ]),
  );

  // ── BUILD PRINCIPAL ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildAccueil(),
      _buildVehiclesPage(),
      _buildContratsPage(),
      _buildPaiementsPage(),
      _buildSinistresPage(),
      _buildProfilPage(),
    ];

    return Scaffold(
      backgroundColor: _fond,
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _bleu2,
            unselectedItemColor: const Color(0xFFADBDD8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car_outlined),
                activeIcon: Icon(Icons.directions_car_rounded),
                label: 'Vehicules',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article_rounded),
                label: 'Contrats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.credit_card_outlined),
                activeIcon: Icon(Icons.credit_card_rounded),
                label: 'Paiements',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.car_crash_outlined),
                activeIcon: Icon(Icons.car_crash_rounded),
                label: 'Sinistres',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


