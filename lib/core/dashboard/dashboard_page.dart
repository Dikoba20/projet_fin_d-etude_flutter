// lib/core/dashboard/dashboard_page.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/souscription_service.dart';
import '../services/paiement_service.dart';
import '../../core/api_client.dart';
import '../../features/auth/souscription_page.dart';
import '../../features/paiement/nouveau_paiement_page.dart';   // ✅ CORRIGÉ

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService         = AuthService();
  final _souscriptionService = SouscriptionService();
  late final _paiementService = PaiementService(ApiClient());

  Map<String, String> _userInfo    = {};
  List<dynamic>       _vehicules   = [];
  List<dynamic>       _contrats    = [];
  List<dynamic>       _activites   = [];
  List<dynamic>       _paiements   = [];
  bool                _loadingData = true;
  int                 _currentIndex = 0;

  static const _bleu1  = Color(0xFF1535A8);
  static const _bleu2  = Color(0xFF1A56DB);
  static const _bleu3  = Color(0xFF3B82F6);
  static const _vert   = Color(0xFF22C55E);
  static const _rouge  = Color(0xFFEF4444);
  static const _orange = Color(0xFFEA580C);
  static const _violet = Color(0xFF8B5CF6);
  static const _fond   = Color(0xFFF0F4FF);
  static const _texte  = Color(0xFF1A1A2E);
  static const _gris   = Color(0xFF8492A6);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loadingData = true);
    try {
      final info = await _authService.getUserInfo();
      final resV = await _souscriptionService.getMesVehicules();
      final resC = await _souscriptionService.getMesContrats();
      final resP = await _paiementService.getPaiements();
      setState(() {
        _userInfo  = info;
        _vehicules = resV['vehicules'] ?? [];
        _contrats  = resC['contrats']  ?? [];
        _paiements = resP;
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
    } catch (_) {
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SouscriptionPage()),
    );
    _loadAll();
  }

  // ✅ CORRIGÉ — navigue vers NouveauPaiementPage avec contratInitial
  void _allerPaiement(Map<String, dynamic> contrat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NouveauPaiementPage(
          contratInitial: Map<String, dynamic>.from(contrat),
        ),
      ),
    );
    // Recharge si paiement effectué
    if (result == true) _loadAll();
  }

  // ✅ NOUVEAU — ouvre la page paiement sans contrat pré-sélectionné
  void _allerNouveauPaiement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NouveauPaiementPage()),
    );
    if (result == true) _loadAll();
  }

  Widget _pageHeader(String titre, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bleu1, _bleu2, _bleu3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Text(titre,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ── PAGE ACCUEIL ───────────────────────────────────────────────────────────
  Widget _buildAccueil() {
    final prenom = _userInfo['prenom'] ?? '';
    final contratActif = _contrats.firstWhere(
      (c) => c['statut'] == 'ACTIF',
      orElse: () => null,
    );
    final enAttente = _contrats.where((c) => c['statut'] == 'EN_ATTENTE').length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _bleu2,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bleu1, _bleu2, _bleu3],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour, $prenom !',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                            const Text('Espace assuré',
                                style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _deconnecter,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (enAttente > 0) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 3),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$enAttente contrat(s) en attente de paiement',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: contratActif != null
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(contratActif['numero_contrat'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Expire : ${contratActif['date_fin'] ?? '—'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: _vert, borderRadius: BorderRadius.circular(20)),
                                child: const Text('Actif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ])
                          : Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Aucun contrat actif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                  SizedBox(height: 2),
                                  Text('Souscrire maintenant →', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ]),
                              ),
                            ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actions rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bleu1)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _quickAction(Icons.add_circle_rounded, 'Souscrire', _bleu2, onTap: _allerSouscription),
                    const SizedBox(width: 10),
                    _quickAction(Icons.payment_rounded, 'Paiements', _orange, onTap: () => setState(() => _currentIndex = 3)),
                    const SizedBox(width: 10),
                    _quickAction(Icons.warning_amber_rounded, 'Sinistres', _rouge, onTap: () => setState(() => _currentIndex = 4)),
                    const SizedBox(width: 10),
                    _quickAction(Icons.description_rounded, 'Contrats', _violet, onTap: () => setState(() => _currentIndex = 2)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mes véhicules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bleu1)),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 1),
                        child: const Text('Voir tout', style: TextStyle(color: _bleu2, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingData)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _bleu2)))
                  else if (_vehicules.isEmpty)
                    _emptyCard('Aucun véhicule enregistré', 'Souscrivez pour ajouter votre premier véhicule.', Icons.directions_car_outlined)
                  else
                    ..._vehicules.take(2).map((v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _vehiculeCard(v))),
                  const SizedBox(height: 8),
                  _addCard('Nouvelle souscription', onTap: _allerSouscription),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dernières activités', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bleu1)),
                  const SizedBox(height: 12),
                  if (_loadingData)
                    const SizedBox()
                  else if (_activites.isEmpty)
                    _emptyCard('Aucune activité', 'Vos actions apparaîtront ici.', Icons.history_rounded)
                  else
                    ..._activites.map((a) => _activiteItem(a)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── PAGE VÉHICULES ─────────────────────────────────────────────────────────
  Widget _buildVehiclesPage() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader('Mes véhicules', Icons.directions_car_rounded)),
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _bleu2))))
          else if (_vehicules.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: _emptyCard('Aucun véhicule', 'Vos véhicules apparaîtront ici après souscription.', Icons.directions_car_outlined)))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _vehiculeCard(_vehicules[i])),
                  childCount: _vehicules.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _addCard('Nouvelle souscription', onTap: _allerSouscription),
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE CONTRATS ──────────────────────────────────────────────────────────
  Widget _buildContratsPage() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader('Mes contrats', Icons.description_rounded)),
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _bleu2))))
          else if (_contrats.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: _emptyCard('Aucun contrat', 'Souscrivez votre première assurance.', Icons.description_outlined)))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _contratCard(_contrats[i])),
                  childCount: _contrats.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _addCard('Nouvelle souscription', onTap: _allerSouscription),
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE PAIEMENTS ─────────────────────────────────────────────────────────
  Widget _buildPaiementsPage() {
    final enAttente = _contrats.where((c) => c['statut'] == 'EN_ATTENTE').toList();

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _bleu2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _pageHeader('Mes paiements', Icons.payment_rounded)),

          // Bannière rappel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_orange.withOpacity(0.08), _orange.withOpacity(0.04)]),
                  border: Border.all(color: _orange.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.access_time_rounded, color: _orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rappel d\'expiration',
                              style: TextStyle(fontWeight: FontWeight.w700, color: _orange, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            enAttente.isNotEmpty
                                ? '${enAttente.length} contrat(s) en attente de paiement.'
                                : 'Aucun contrat en attente de paiement.',
                            style: const TextStyle(fontSize: 12, color: _texte),
                          ),
                          if (enAttente.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _allerPaiement(enAttente.first),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
                                child: const Text('🔄 Renouveler maintenant',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Titre historique + bouton Nouveau
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Historique des paiements',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bleu1)),
                  // ✅ Bouton Nouveau → ouvre NouveauPaiementPage sans contrat pré-sélectionné
                  GestureDetector(
                    onTap: _allerNouveauPaiement,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Nouveau', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste paiements depuis le backend
          if (_loadingData)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _bleu2))))
          else if (_paiements.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _emptyCard('Aucun paiement', 'Vos paiements apparaîtront ici.', Icons.receipt_long_outlined),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _paiementCard(_paiements[i])),
                  childCount: _paiements.length,
                ),
              ),
            ),

          // Contrats à payer
          if (enAttente.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text('Contrats à payer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _bleu1)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _contratCard(enAttente[i])),
                  childCount: enAttente.length,
                ),
              ),
            ),
          ],

          // Renouvellement en un clic
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_violet.withOpacity(0.12), _violet.withOpacity(0.06)]),
                  border: Border.all(color: _violet.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _violet.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.autorenew_rounded, color: _violet, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Renouvellement en un clic',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _violet, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        enAttente.isNotEmpty
                            ? '${enAttente.first['numero_contrat']} — ${enAttente.first['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers'}'
                            : 'Aucun contrat à renouveler.',
                        style: const TextStyle(fontSize: 12, color: _gris),
                      ),
                      if (enAttente.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Expire le ${enAttente.first['date_fin'] ?? '—'}',
                            style: const TextStyle(fontSize: 11, color: _gris)),
                      ],
                    ]),
                  ),
                  if (enAttente.isNotEmpty)
                    GestureDetector(
                      onTap: () => _allerPaiement(enAttente.first),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: _violet, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Renouveler',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinistresPage() => _comingSoon(
      Icons.warning_amber_rounded, 'Sinistres', 'Déclaration de sinistre bientôt disponible.');

  // ── PAGE PROFIL ────────────────────────────────────────────────────────────
  Widget _buildProfilPage() {
    final prenom  = _userInfo['prenom']  ?? '';
    final nom     = _userInfo['nom']     ?? '';
    final tel     = _userInfo['tel']     ?? '';
    final nni     = _userInfo['nni']     ?? '—';
    final email   = _userInfo['email']   ?? '—';
    final adresse = _userInfo['adresse'] ?? '—';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_bleu1, _bleu2, _bleu3]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
              Text('$prenom $nom', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(tel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statProfil('${_vehicules.length}', 'Véhicules'),
                Container(width: 1, height: 30, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 20)),
                _statProfil('${_contrats.length}', 'Contrats'),
                Container(width: 1, height: 30, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 20)),
                _statProfil('${_contrats.where((c) => c['statut'] == 'ACTIF').length}', 'Actifs'),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              _profileItem(Icons.person_outline_rounded, 'Nom complet', '$prenom $nom'),
              _profileItem(Icons.phone_outlined, 'Téléphone', tel),
              _profileItem(Icons.badge_outlined, 'NNI', nni),
              _profileItem(Icons.location_on_outlined, 'Adresse', adresse),
              _profileItem(Icons.email_outlined, 'Email', email),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _deconnecter,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _rouge,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: _rouge.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Se déconnecter', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── WIDGETS UTILITAIRES ────────────────────────────────────────────────────

  Widget _quickAction(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _texte)),
          ]),
        ),
      ),
    );
  }

  Widget _vehiculeCard(Map<String, dynamic> v) {
    final estAssure = _contrats.any((c) =>
        c['vehicule_id'].toString() == v['id'].toString() && c['statut'] == 'ACTIF');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _bleu2.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bleu3.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.directions_car_rounded, color: _bleu2, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${v['marque'] ?? ''} ${v['modele'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _texte)),
          const SizedBox(height: 2),
          Text('${v['immatriculation'] ?? ''} · ${v['annee'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: _gris)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: estAssure ? _vert.withOpacity(0.1) : _rouge.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(estAssure ? 'Assuré' : 'Non assuré',
              style: TextStyle(color: estAssure ? _vert : _rouge, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _contratCard(Map<String, dynamic> c) {
    final statut      = c['statut'] ?? '';
    final isActif     = statut == 'ACTIF';
    final isEnAttente = statut == 'EN_ATTENTE';
    final color       = isActif ? _vert : (isEnAttente ? _orange : _rouge);
    final type        = c['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _violet.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.description_rounded, color: _violet, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['numero_contrat'] ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _texte)),
            Text(type, style: const TextStyle(fontSize: 12, color: _gris)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(statut, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F4FF)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _contratInfo('Prime', '${c['prime_montant'] ?? '—'} MRU'),
          _contratInfo('Début', c['date_debut'] ?? '—'),
          _contratInfo('Fin', c['date_fin'] ?? '—'),
        ]),
        // ✅ Bouton "Payer maintenant" → ouvre NouveauPaiementPage
        if (isEnAttente) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _allerPaiement(c),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _bleu2.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('💳 Payer maintenant',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _paiementCard(Map<String, dynamic> p) {
    final statut = (p['statut'] ?? '').toString();
    final color  = statut == 'CONFIRME' ? _vert : _orange;
    final label  = statut == 'CONFIRME' ? 'Confirmé' : 'En attente';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['reference'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _texte)),
            Text(p['contrat_numero'] ?? p['contrat']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: _gris)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF0F4FF)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _contratInfo('Montant', '${p['montant'] ?? '—'} MRU'),
          _contratInfo('Méthode', p['methode'] ?? '—'),
          _contratInfo('Date', (p['date_paiement'] ?? '').toString().split('T').first),
        ]),
      ]),
    );
  }

  Widget _contratInfo(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: _gris)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _texte)),
    ],
  );

  Widget _activiteItem(Map<String, dynamic> a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _bleu2.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.description_rounded, color: _bleu2, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _texte)),
        Text(a['detail'] ?? '', style: const TextStyle(fontSize: 11, color: _gris)),
      ])),
      Text(a['date']?.toString().split('T').first ?? '', style: const TextStyle(fontSize: 11, color: _gris)),
    ]),
  );

  Widget _addCard(String label, {required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bleu2.withOpacity(0.3), width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_circle_outline_rounded, color: _bleu2, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _bleu2, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    ),
  );

  Widget _emptyCard(String titre, String sous, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E8F5), width: 1),
    ),
    child: Column(children: [
      Icon(icon, color: const Color(0xFFADBDD8), size: 36),
      const SizedBox(height: 10),
      Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF4A5568))),
      const SizedBox(height: 4),
      Text(sous, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _gris)),
    ]),
  );

  Widget _statProfil(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  ]);

  Widget _profileItem(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Icon(icon, color: _bleu2, size: 20),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _texte)),
      ])),
    ]),
  );

  Widget _comingSoon(IconData icon, String title, String subtitle) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _bleu2.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: _bleu2, size: 48),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _bleu1)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _gris)),
      ]),
    ),
  );

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
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car_rounded), label: 'Véhicules'),
              BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description_rounded), label: 'Contrats'),
              BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), activeIcon: Icon(Icons.payment_rounded), label: 'Paiements'),
              BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined), activeIcon: Icon(Icons.warning_amber_rounded), label: 'Sinistres'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}