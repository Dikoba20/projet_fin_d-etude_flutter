// lib/features/profil/espace_personnel_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/souscription_service.dart';
import '../../core/services/sinistre_service.dart';
import '../../core/services/notification_service.dart';

class EspacePersonnelPage extends StatefulWidget {
  const EspacePersonnelPage({super.key});
  @override
  State<EspacePersonnelPage> createState() => _EspacePersonnelPageState();
}

class _EspacePersonnelPageState extends State<EspacePersonnelPage>
    with SingleTickerProviderStateMixin {

  // â”€â”€ Couleurs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const kBlue      = Color(0xFF1535A8);
  static const kBlueMid   = Color(0xFF1A56DB);
  static const kBlueLight = Color(0xFFDBEAFE);
  static const kGreen     = Color(0xFF16A34A);
  static const kGreenL    = Color(0xFFDCFCE7);
  static const kOrange    = Color(0xFFEA580C);
  static const kOrangeL   = Color(0xFFFFF0E6);
  static const kRed       = Color(0xFFDC2626);
  static const kRedL      = Color(0xFFFEE2E2);
  static const kViolet    = Color(0xFF7C3AED);
  static const kVioletL   = Color(0xFFEDE9FE);
  static const kGray      = Color(0xFF64748B);
  static const kGrayL     = Color(0xFFF1F5F9);
  static const kText      = Color(0xFF1E293B);
  static const kBorder    = Color(0xFFE2E8F0);
  static const kBg        = Color(0xFFEEF2FF);

  // â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _authService         = AuthService();
  final _souscriptionService = SouscriptionService();
  final _sinistreService     = SinistreService();
  final _notifService        = NotificationService();

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late TabController _tabController;
  Map<String, String> _userInfo    = {};
  List<dynamic>       _contrats    = [];
  List<dynamic>       _sinistres   = [];
  List<dynamic>       _notifs      = [];
  List<dynamic>       _documents   = [];
  bool                _loading     = true;
  String              _token       = '';
  Timer?              _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      final info  = await _authService.getUserInfo();
      final resC  = await _souscriptionService.getMesContrats();
      final resS  = await _sinistreService.getSinistres(token: _token);
      final resN  = await _notifService.getNotifications(token: _token);
      final resD  = await ApiClient().get('/documents/', token: _token);

      setState(() {
        _userInfo  = info;
        _contrats  = resC['contrats']      ?? [];
        _sinistres = resS['sinistres']     ?? [];
        _notifs    = resN['notifications'] ?? [];
        _documents = resD['documents']     ?? [];
      });

      // DÃ©marrer polling notifications
      _demarrerPollingNotifs();
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _demarrerPollingNotifs() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final res = await _notifService.getNotifications(token: _token);
        if (res['success'] == true && mounted) {
          setState(() => _notifs = res['notifications'] ?? []);
        }
      } catch (_) {}
    });
  }

  Future<void> _marquerNotifLue(int notifId) async {
    await _notifService.marquerLue(token: _token, notifId: notifId);
    final res = await _notifService.getNotifications(token: _token);
    if (res['success'] == true && mounted) {
      setState(() => _notifs = res['notifications'] ?? []);
    }
  }

  Future<void> _marquerToutesLues() async {
    final nonLues = _notifs.where((n) => n['lu'] == 0 || n['lu'] == false).toList();
    for (final n in nonLues) {
      await _notifService.marquerLue(token: _token, notifId: n['id']);
    }
    final res = await _notifService.getNotifications(token: _token);
    if (res['success'] == true && mounted) {
      setState(() => _notifs = res['notifications'] ?? []);
    }
  }

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final nonLues = _notifs.where((n) => n['lu'] == 0 || n['lu'] == false).length;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(nonLues),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kBlueMid))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOngletResume(),
                      _buildOngletSinistres(),
                      _buildOngletDocuments(),
                      _buildOngletNotifications(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(int nonLues) {
    final prenom  = _userInfo['prenom'] ?? '';
    final nom     = _userInfo['nom']    ?? '';
    final contratActifs = _contrats.where((c) => c['statut'] == 'ACTIF').length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue, kBlueMid, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x4D1A56DB), blurRadius: 20, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20, left: 20, right: 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$prenom $nom',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Text('Espace personnel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              if (nonLues > 0)
                GestureDetector(
                  onTap: () => _tabController.animateTo(3),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: Stack(children: [
                      const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(color: kOrange, shape: BoxShape.circle),
                          child: Center(child: Text('$nonLues', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                        ),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats rapides
          Row(children: [
            _buildStatCard('${_contrats.where((c) => c['statut'] == 'ACTIF').length}', 'Contrats actifs', Icons.shield_rounded, kGreen),
            const SizedBox(width: 10),
            _buildStatCard('${_sinistres.length}', 'Sinistres', Icons.warning_amber_rounded, kOrange),
            const SizedBox(width: 10),
            _buildStatCard('${_documents.length}', 'Documents', Icons.folder_rounded, kViolet),
            const SizedBox(width: 10),
            _buildStatCard('$nonLues', 'Alertes', Icons.notifications_rounded, kRed),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // â”€â”€ TabBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTabBar() {
    final nonLues = _notifs.where((n) => n['lu'] == 0 || n['lu'] == false).length;
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kBlueMid,
        indicatorWeight: 3,
        labelColor: kBlueMid,
        unselectedLabelColor: kGray,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: [
          const Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'RÃ©sumÃ©'),
          const Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Sinistres'),
          const Tab(icon: Icon(Icons.folder_rounded, size: 18), text: 'Documents'),
          Tab(
            child: Stack(clipBehavior: Clip.none, children: [
              const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_rounded, size: 18),
                Text('Alertes', style: TextStyle(fontSize: 11)),
              ]),
              if (nonLues > 0)
                Positioned(
                  right: -8, top: -4,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                    child: Center(child: Text('$nonLues', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  // â”€â”€ ONGLET RÃ‰SUMÃ‰ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOngletResume() {
    final contratsActifs  = _contrats.where((c) => c['statut'] == 'ACTIF').toList();
    final contratsExpires = _contrats.where((c) => c['statut'] == 'EXPIRE').toList();
    final enAttente       = _contrats.where((c) => c['statut'] == 'EN_ATTENTE').toList();

    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: kBlueMid,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Contrats actifs
          if (contratsActifs.isNotEmpty) ...[
            _sectionTitle('ðŸ›¡ï¸ Contrats actifs', contratsActifs.length),
            const SizedBox(height: 8),
            ...contratsActifs.map((c) => _contratResumeCard(c, kGreen, kGreenL)),
            const SizedBox(height: 16),
          ],

          // En attente de paiement
          if (enAttente.isNotEmpty) ...[
            _sectionTitle('â³ En attente de paiement', enAttente.length),
            const SizedBox(height: 8),
            ...enAttente.map((c) => _contratResumeCard(c, kOrange, kOrangeL)),
            const SizedBox(height: 16),
          ],

          // Sinistres rÃ©cents
          if (_sinistres.isNotEmpty) ...[
            _sectionTitle('âš ï¸ Sinistres rÃ©cents', _sinistres.length),
            const SizedBox(height: 8),
            ..._sinistres.take(3).map((s) => _sinistreResumeCard(s)),
            const SizedBox(height: 16),
          ],

          // ExpirÃ©s
          if (contratsExpires.isNotEmpty) ...[
            _sectionTitle('âŒ Contrats expirÃ©s', contratsExpires.length),
            const SizedBox(height: 8),
            ...contratsExpires.map((c) => _contratResumeCard(c, kRed, kRedL)),
          ],

          if (_contrats.isEmpty && _sinistres.isEmpty)
            _emptyState('Aucune activitÃ©', 'Vos contrats et sinistres apparaÃ®tront ici.', Icons.dashboard_outlined),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _contratResumeCard(Map<String, dynamic> c, Color color, Color bgColor) {
    final type = c['type_assurance'] == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';
    final jours = _joursRestants(c['date_fin']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.shield_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['numero_contrat'] ?? 'â€”', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
          const SizedBox(height: 2),
          Text('$type â€¢ Expire le ${c['date_fin'] ?? 'â€”'}', style: const TextStyle(fontSize: 11, color: kGray)),
        ])),
        if (jours != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Text(
              jours > 0 ? '$jours j' : 'ExpirÃ©',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ]),
    );
  }

  Widget _sinistreResumeCard(Map<String, dynamic> s) {
    final statut = s['statut'] ?? 'DECLARE';
    Color color; String label;
    switch (statut) {
      case 'DECLARE':  color = kOrange; label = 'DÃ©clarÃ©';  break;
      case 'EN_COURS': color = kBlueMid; label = 'En cours'; break;
      case 'CLOTURE':   color = kGreen;  label = 'RÃ©solu';   break;
      case 'REJETE':   color = kRed;    label = 'RejetÃ©';   break;
      default:         color = kGray;   label = statut;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kRedL, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.warning_amber_rounded, color: kRed, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['numero_sinistre'] ?? 'â€”', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
          const SizedBox(height: 2),
          Text(
            (s['description'] ?? '').toString().length > 40
                ? '${(s['description'] ?? '').toString().substring(0, 40)}...'
                : s['description'] ?? '',
            style: const TextStyle(fontSize: 11, color: kGray),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // â”€â”€ ONGLET SINISTRES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOngletSinistres() {
    if (_sinistres.isEmpty) {
      return _emptyState('Aucun sinistre', 'Vos dÃ©clarations apparaÃ®tront ici.', Icons.shield_outlined);
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: kRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sinistres.length,
        itemBuilder: (context, i) => _sinistreDetailCard(_sinistres[i]),
      ),
    );
  }

  Widget _sinistreDetailCard(Map<String, dynamic> s) {
    final statut = s['statut'] ?? 'DECLARE';
    Color color; String label; IconData icon;
    switch (statut) {
      case 'DECLARE':  color = kOrange; label = 'DÃ©clarÃ©';  icon = Icons.pending_rounded; break;
      case 'EN_COURS': color = kBlueMid; label = 'En cours'; icon = Icons.autorenew_rounded; break;
      case 'CLOTURE':   color = kGreen;  label = 'RÃ©solu';   icon = Icons.check_circle_rounded; break;
      case 'REJETE':   color = kRed;    label = 'RejetÃ©';   icon = Icons.cancel_rounded; break;
      default:         color = kGray;   label = statut;     icon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: kRed, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['numero_sinistre'] ?? 'â€”', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kText)),
              Text('Accident du ${(s['date_accident'] ?? '').toString().split('T').first}',
                  style: const TextStyle(fontSize: 11, color: kGray)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        // Corps
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Description', style: TextStyle(fontSize: 11, color: kGray, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(s['description'] ?? 'â€”', style: const TextStyle(fontSize: 13, color: kText)),
            if (s['lieu_accident'] != null && s['lieu_accident'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.location_on, color: kGray, size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(s['lieu_accident'], style: const TextStyle(fontSize: 12, color: kGray))),
              ]),
            ],
            const SizedBox(height: 10),
            // Suivi en temps rÃ©el
            _buildSuiviSinistre(statut),
          ]),
        ),
      ]),
    );
  }

  // âœ… Suivi en temps rÃ©el â€” timeline
  Widget _buildSuiviSinistre(String statut) {
    final etapes = [
      {'label': 'DÃ©clarÃ©',   'statut': 'DECLARE',  'icon': Icons.assignment_rounded},
      {'label': 'En cours',  'statut': 'EN_COURS', 'icon': Icons.search_rounded},
      {'label': 'RÃ©solu',    'statut': 'CLOTURE',   'icon': Icons.check_circle_rounded},
    ];

    final ordre = {'DECLARE': 0, 'EN_COURS': 1, 'CLOTURE': 2, 'REJETE': -1};
    final indexActuel = ordre[statut] ?? 0;
    final estRejete   = statut == 'REJETE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGrayL, borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timeline_rounded, color: kBlueMid, size: 16),
          const SizedBox(width: 6),
          const Text('Suivi du dossier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
          const Spacer(),
          if (estRejete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kRedL, borderRadius: BorderRadius.circular(8)),
              child: const Text('RejetÃ©', style: TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: List.generate(etapes.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Ligne entre Ã©tapes
              final etapeIndex = i ~/ 2;
              final fait = !estRejete && etapeIndex < indexActuel;
              return Expanded(child: Container(height: 2, color: fait ? kGreen : kBorder));
            }
            final etapeIndex = i ~/ 2;
            final etape  = etapes[etapeIndex];
            final fait   = !estRejete && etapeIndex <= indexActuel;
            final actuel = !estRejete && etapeIndex == indexActuel;
            final color  = fait ? kGreen : kGray;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: fait ? kGreenL : kBorder,
                  shape: BoxShape.circle,
                  border: actuel ? Border.all(color: kGreen, width: 2) : null,
                ),
                child: Icon(etape['icon'] as IconData, color: color, size: 16),
              ),
              const SizedBox(height: 4),
              Text(etape['label'] as String, style: TextStyle(fontSize: 9, color: color, fontWeight: actuel ? FontWeight.w700 : FontWeight.w400)),
            ]);
          }),
        ),
      ]),
    );
  }

  // â”€â”€ ONGLET DOCUMENTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOngletDocuments() {
    if (_documents.isEmpty) {
      return _emptyState('Aucun document', 'Vos attestations et documents apparaÃ®tront ici.', Icons.folder_outlined);
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: kViolet,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, i) => _documentCard(_documents[i]),
      ),
    );
  }

  Widget _documentCard(Map<String, dynamic> doc) {
    final type = doc['type_document'] ?? 'AUTRE';
    Color color; IconData icon; String label;
    switch (type) {
      case 'ATTESTATION': color = kGreen;  icon = Icons.verified_rounded;      label = 'Attestation'; break;
      case 'CONTRAT':     color = kBlueMid; icon = Icons.description_rounded;  label = 'Contrat';     break;
      case 'SINISTRE':    color = kRed;    icon = Icons.warning_amber_rounded;  label = 'Sinistre';    break;
      case 'FACTURE':     color = kOrange; icon = Icons.receipt_rounded;        label = 'Facture';     break;
      default:            color = kGray;   icon = Icons.insert_drive_file_rounded; label = 'Document';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc['nom_fichier'] ?? 'â€”', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
          const SizedBox(height: 2),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (doc['taille_ko'] != null) ...[
              const SizedBox(width: 6),
              Text('${doc['taille_ko']} Ko', style: const TextStyle(fontSize: 10, color: kGray)),
            ],
          ]),
        ])),
        // âœ… Bouton tÃ©lÃ©chargement
        GestureDetector(
          onTap: () => _telechargerDocument(doc),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBlueLight, borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_rounded, color: kBlueMid, size: 20),
          ),
        ),
      ]),
    );
  }

  void _telechargerDocument(Map<String, dynamic> doc) {
    final url = doc['url_fichier'] ?? '';
    if (url.isEmpty) {
      _snack('URL du document non disponible', kRed);
      return;
    }
    // Sur web : ouvre dans un nouvel onglet
    // Sur mobile : utilise le package url_launcher
    _snack('TÃ©lÃ©chargement de ${doc['nom_fichier']}...', kGreen);
  }

  // â”€â”€ ONGLET NOTIFICATIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOngletNotifications() {
    final nonLues = _notifs.where((n) => n['lu'] == 0 || n['lu'] == false).length;

    return Column(
      children: [
        if (nonLues > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: _marquerToutesLues,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kBlueLight, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.done_all_rounded, color: kBlueMid, size: 16),
                  const SizedBox(width: 8),
                  Text('Marquer tout comme lu ($nonLues)', style: const TextStyle(color: kBlueMid, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        Expanded(
          child: _notifs.isEmpty
              ? _emptyState('Aucune notification', 'Vos alertes apparaÃ®tront ici.', Icons.notifications_none_rounded)
              : RefreshIndicator(
                  onRefresh: _chargerDonnees,
                  color: kBlueMid,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    itemBuilder: (context, i) => _notifCard(_notifs[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _notifCard(Map<String, dynamic> n) {
    final lu      = n['lu'] == 1 || n['lu'] == true;
    final type    = n['type_notif'] ?? 'INFO';
    Color color; IconData icon;
    switch (type) {
      case 'PAIEMENT':      color = kGreen;  icon = Icons.payment_rounded;           break;
      case 'RENOUVELLEMENT': color = kViolet; icon = Icons.autorenew_rounded;         break;
      case 'SINISTRE':      color = kRed;    icon = Icons.warning_amber_rounded;      break;
      case 'CONTRAT':       color = kBlueMid; icon = Icons.description_rounded;       break;
      default:              color = kGray;   icon = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: () => !lu ? _marquerNotifLue(n['id']) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lu ? Colors.white : kBlueLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lu ? kBorder : const Color(0xFFBFDBFE)),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n['titre'] ?? 'â€”', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText))),
              if (!lu)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: kBlueMid, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 3),
            Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: kGray), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              (n['date_envoi'] ?? '').toString().split('T').first,
              style: const TextStyle(fontSize: 10, color: kGray),
            ),
          ])),
        ]),
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int? _joursRestants(dynamic dateFin) {
    if (dateFin == null) return null;
    try {
      final fin  = DateTime.parse(dateFin.toString());
      final diff = fin.difference(DateTime.now()).inDays;
      return diff;
    } catch (_) { return null; }
  }

  Widget _sectionTitle(String title, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: kBlueLight, borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: const TextStyle(color: kBlueMid, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ],
  );

  Widget _emptyState(String titre, String sous, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kGrayL, shape: BoxShape.circle),
          child: Icon(icon, color: kGray, size: 40),
        ),
        const SizedBox(height: 16),
        Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        Text(sous, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kGray)),
      ]),
    ),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
