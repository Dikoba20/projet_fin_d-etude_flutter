import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_page.dart';

// ══════════════════════════════════════════════════════
// COULEURS ADMIN - Palette bleue (même que dashboard client)
// ══════════════════════════════════════════════════════
class AC {
  static const primary      = Color(0xFF1535A8);
  static const primaryMid   = Color(0xFF1A56DB);
  static const primaryLight = Color(0xFF3B82F6);
  static const accent       = Color(0xFF7C3AED);
  static const bg           = Color(0xFFEEF2FF);
  static const bgCard       = Colors.white;
  static const textDark     = Color(0xFF1E293B);
  static const textGrey     = Color(0xFF64748B);
  static const success      = Color(0xFF16A34A);
  static const successL     = Color(0xFFDCFCE7);
  static const warning      = Color(0xFFEA580C);
  static const warningL     = Color(0xFFFFF0E6);
  static const danger       = Color(0xFFDC2626);
  static const dangerL      = Color(0xFFFEE2E2);
  static const purple       = Color(0xFF7C3AED);
  static const purpleL      = Color(0xFFEDE9FE);
  static const border       = Color(0xFFE2E8F0);
  static const blueLight    = Color(0xFFDBEAFE);
}

class _MI {
  final IconData icon;
  final String label;
  const _MI(this.icon, this.label);
}

// ══════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ══════════════════════════════════════════════════════
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _svc  = AdminService();
  final _auth = AuthService();
  int _idx    = 0;

  final _menu = const [
    _MI(Icons.dashboard_rounded,     'Tableau de bord'),
    _MI(Icons.people_rounded,        'Utilisateurs'),
    _MI(Icons.description_rounded,   'Contrats'),
    _MI(Icons.price_change_rounded,  'Tarifs'),
    _MI(Icons.car_crash_rounded,     'Sinistres'),
    _MI(Icons.notifications_rounded, 'Notifications'),
    _MI(Icons.download_rounded,      'Export'),
  ];

  void _logout() async {
    await _auth.deconnecter();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: Row(children: [
      _buildSidebar(),
      Expanded(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _buildPage()),
      ])),
    ]),
  );

  Widget _buildPage() {
    switch (_idx) {
      case 0: return _DashboardTab(svc: _svc);
      case 1: return _UtilisateursTab(svc: _svc);
      case 2: return _ContratsTab(svc: _svc);
      case 3: return _TarifsTab(svc: _svc);
      case 4: return _SinistresTab(svc: _svc);
      case 5: return _NotificationsTab(svc: _svc);
      case 6: return _ExportTab(svc: _svc);
      default: return const SizedBox();
    }
  }

  Widget _buildSidebar() => Container(
    width: 240,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0F1F6B), Color(0xFF1535A8), Color(0xFF1A56DB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AssurAncy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Administration', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ]),
      ),
      const Divider(color: Colors.white24, height: 1),
      const SizedBox(height: 12),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _menu.length,
        itemBuilder: (_, i) {
          final sel = _idx == i;
          return GestureDetector(
            onTap: () => setState(() => _idx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: sel ? Border.all(color: Colors.white30) : null,
              ),
              child: Row(children: [
                Icon(_menu[i].icon, color: sel ? Colors.white : Colors.white60, size: 20),
                const SizedBox(width: 12),
                Text(_menu[i].label, style: TextStyle(
                  color: sel ? Colors.white : Colors.white70,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 14,
                )),
                if (sel) ...[const Spacer(), Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))],
              ]),
            ),
          );
        },
      )),
      GestureDetector(
        onTap: _logout,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: const Row(children: [
            CircleAvatar(radius: 18, backgroundColor: Colors.white24,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Administrateur', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('Super Admin', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ])),
            Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Text(_menu[_idx].label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AC.textDark)),
      const Spacer(),
      Container(
        width: 220, height: 38,
        decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.border)),
        child: const TextField(decoration: InputDecoration(
          hintText: 'Rechercher...', hintStyle: TextStyle(fontSize: 13, color: AC.textGrey),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AC.textGrey),
          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10))),
      ),
      const SizedBox(width: 16),
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AC.primary, AC.primaryMid]),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// ONGLET 1 : TABLEAU DE BORD
// ══════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  final AdminService svc;
  const _DashboardTab({required this.svc});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await widget.svc.getDashboard();
      if (res['success'] == true) {
        setState(() { _data = res; _loading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Erreur'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur de connexion: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AC.primaryMid));
    if (_error != null) return _ErrorWidget(msg: _error!, onRetry: _load);

    final kpis      = (_data!['kpis']              as Map<String, dynamic>?)  ?? {};
    final evolution = ((_data!['evolution']         as List?)                 ?? []).cast<Map<String, dynamic>>();
    final alertes   = ((_data!['alertes']           as List?)                 ?? []).cast<Map<String, dynamic>>();
    final derniers  = ((_data!['derniers_contrats'] as List?)                 ?? []).cast<Map<String, dynamic>>();
    final rep       = (_data!['repartition']        as Map<String, dynamic>?) ?? {};
    final maxVal    = evolution.isEmpty ? 1 : evolution.map((e) => (e['contrats'] as int? ?? 0)).reduce((a,b) => a>b?a:b);

    return RefreshIndicator(
      onRefresh: _load, color: AC.primaryMid,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GridView.count(
            crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16,
            childAspectRatio: 1.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiCard(label: 'Contrats actifs',    value: '${kpis['contrats_actifs'] ?? 0}',  icon: Icons.description_rounded,     color: AC.primaryMid),
              _KpiCard(label: 'Primes collectées',  value: _fmt(kpis['primes_total'] ?? 0),    icon: Icons.monetization_on_rounded, color: AC.success),
              _KpiCard(label: 'Sinistres en cours', value: '${kpis['sinistres_cours'] ?? 0}',  icon: Icons.car_crash_rounded,       color: AC.warning),
              _KpiCard(label: 'Clients actifs',     value: '${kpis['total_clients'] ?? 0}',    icon: Icons.people_rounded,          color: AC.accent),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16,
            childAspectRatio: 1.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiCard(label: 'En attente',  value: '${kpis['contrats_attente'] ?? 0}', icon: Icons.pending_rounded,         color: AC.warning),
              _KpiCard(label: 'Expirés',     value: '${kpis['contrats_expires'] ?? 0}', icon: Icons.timer_off_rounded,       color: AC.textGrey),
              _KpiCard(label: 'Ce mois',     value: '${kpis['contrats_mois'] ?? 0}',    icon: Icons.calendar_today_rounded,  color: AC.primaryLight),
              _KpiCard(label: 'Primes/mois', value: _fmt(kpis['primes_mois'] ?? 0),     icon: Icons.trending_up_rounded,     color: AC.primaryMid),
            ],
          ),
          const SizedBox(height: 24),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _Card(
              title: 'Evolution des contrats (6 derniers mois)',
              action: IconButton(icon: const Icon(Icons.refresh_rounded, size: 18, color: AC.textGrey), onPressed: _load),
              child: SizedBox(height: 160, child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: evolution.map((e) {
                  final nb  = e['contrats'] as int? ?? 0;
                  final pct = maxVal == 0 ? 0.0 : nb / maxVal;
                  return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('$nb', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.primaryMid)),
                    const SizedBox(height: 4),
                    Container(width: 36, height: 120 * pct + 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AC.primary, AC.primaryLight], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                        borderRadius: BorderRadius.circular(6),
                      )),
                    const SizedBox(height: 6),
                    Text(e['mois'].toString().length >= 3 ? e['mois'].toString().substring(0, 3) : e['mois'].toString(),
                        style: const TextStyle(fontSize: 10, color: AC.textGrey)),
                  ]);
                }).toList(),
              )),
            )),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _Card(
              title: 'Répartition',
              child: Column(children: [
                const SizedBox(height: 4),
                _Bar2('Tous Risques', (rep['tous_risques_pct'] as num?)?.toInt() ?? 0, AC.primaryMid),
                const SizedBox(height: 8),
                _Bar2('RC Tiers',     (rep['tiers_pct']        as num?)?.toInt() ?? 0, AC.accent),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _Bar2('12 mois', (rep['d12_pct'] as num?)?.toInt() ?? 0, AC.primaryMid),
                const SizedBox(height: 8),
                _Bar2('6 mois',  (rep['d6_pct']  as num?)?.toInt() ?? 0, AC.warning),
                const SizedBox(height: 8),
                _Bar2('3 mois',  (rep['d3_pct']  as num?)?.toInt() ?? 0, AC.accent),
              ]),
            )),
          ]),
          const SizedBox(height: 16),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _Card(
              title: 'Derniers contrats',
              child: Column(children: [
                Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Expanded(flex:2, child: Text('N° Contrat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
                    Expanded(flex:2, child: Text('Client',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
                    Expanded(child:       Text('Type',        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
                    Expanded(child:       Text('Prime',       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
                    Expanded(child:       Text('Statut',      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
                  ])),
                ...derniers.map((c) => _ContratRow(
                  num:    (c['numero'] ?? c['numero_contrat'] ?? '-').toString(),
                  client: (c['client'] ?? c['client_nom'] ?? '-').toString(),
                  type:   (c['type']   ?? c['type_assurance'] ?? '').toString(),
                  prime:  '${(double.tryParse((c['prime'] ?? c['prime_montant'] ?? 0).toString()) ?? 0.0).toStringAsFixed(0)} MRU',
                  statut: (c['statut'] ?? '-').toString(),
                )),
                if (derniers.isEmpty) const Padding(padding: EdgeInsets.all(16),
                    child: Text('Aucun contrat récent', style: TextStyle(color: AC.textGrey))),
              ]),
            )),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _Card(
              title: 'Alertes',
              child: alertes.isEmpty
                  ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucune alerte', style: TextStyle(color: AC.textGrey)))
                  : Column(children: alertes.map((a) {
                      final c = a['type'] == 'DANGER' ? AC.danger : a['type'] == 'WARNING' ? AC.warning : a['type'] == 'SUCCESS' ? AC.success : AC.primaryMid;
                      final i = a['type'] == 'DANGER' ? Icons.warning_rounded : a['type'] == 'WARNING' ? Icons.timer_rounded : a['type'] == 'SUCCESS' ? Icons.person_add_rounded : Icons.payment_rounded;
                      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [Icon(i, color: c, size: 18), const SizedBox(width: 10),
                          Expanded(child: Text(a['msg'] ?? '', style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)))]));
                    }).toList()),
            )),
          ]),
        ]),
      ),
    );
  }

  String _fmt(dynamic val) {
    final n = double.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M MRU';
    if (n >= 1000)    return '${(n/1000).toStringAsFixed(0)}K MRU';
    return '${n.toStringAsFixed(0)} MRU';
  }
}

// ══════════════════════════════════════════════════════
// ONGLET 2 : UTILISATEURS
// ══════════════════════════════════════════════════════
class _UtilisateursTab extends StatefulWidget {
  final AdminService svc;
  const _UtilisateursTab({required this.svc});
  @override
  State<_UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<_UtilisateursTab> {
  List<Map<String, dynamic>> _allUsers = []; // liste complète du backend
  bool _loading = true;
  String _filtre = 'TOUS';
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.svc.getUtilisateurs();
      if (res['success'] == true) {
        setState(() { _allUsers = (res['utilisateurs'] as List).cast<Map<String, dynamic>>(); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  // Filtre local : rôle + recherche texte
  List<Map<String, dynamic>> get _filtered {
    return _allUsers.where((u) {
      final matchRole = _filtre == 'TOUS' || (u['role'] ?? '') == _filtre;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (u['nom']       ?? '').toString().toLowerCase().contains(q) ||
          (u['prenom']    ?? '').toString().toLowerCase().contains(q) ||
          (u['email']     ?? '').toString().toLowerCase().contains(q) ||
          (u['telephone'] ?? '').toString().toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AC.primaryMid));
    final users = _filtered;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ...['TOUS','CLIENT','AGENT','EXPERT','ADMIN'].map((f) => GestureDetector(
          onTap: () => setState(() => _filtre = f),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _filtre == f ? AC.primaryMid : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _filtre == f ? AC.primaryMid : AC.border)),
            child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _filtre == f ? Colors.white : AC.textGrey))))),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 38,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.border)),
          child: TextField(onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Rechercher...', hintStyle: TextStyle(color: AC.textGrey, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AC.textGrey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10))))),
        const SizedBox(width: 12),
        _Btn(label: '+ Ajouter', icon: Icons.add_rounded, onTap: () => _showDialog(context)),
        const SizedBox(width: 8),
        _Btn(label: 'Exporter', icon: Icons.download_rounded, onTap: () {}, outline: true),
      ]),
      const SizedBox(height: 20),
      _Card(title: 'Utilisateurs (${users.length})', child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex:2, child: Text('Nom',       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Téléphone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Email',     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Rôle',      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Statut',    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
            SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.textGrey))),
          ])),
        ...users.map((u) => _UserRow(user: u, onEdit: () => _showDialog(context, user: u),
            onSuspend: () async { await widget.svc.suspendreUtilisateur(u['id'].toString()); _load(); })),
        if (users.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Aucun utilisateur trouvé', style: TextStyle(color: AC.textGrey))),
      ])),
    ]));
  }

  void _showDialog(BuildContext ctx, {Map<String, dynamic>? user}) {
    showDialog(context: ctx, builder: (_) => _UserDialog(user: user, onSave: (data) async {
      if (user == null) await widget.svc.creerUtilisateur(data);
      else await widget.svc.modifierUtilisateur(user['id'].toString(), data);
      _load();
    }));
  }
}

// ══════════════════════════════════════════════════════
// ONGLET 3 : CONTRATS
// ══════════════════════════════════════════════════════
class _ContratsTab extends StatefulWidget {
  final AdminService svc;
  const _ContratsTab({required this.svc});
  @override
  State<_ContratsTab> createState() => _ContratsTabState();
}

class _ContratsTabState extends State<_ContratsTab> {
  List<Map<String, dynamic>> _allContrats = [];
  bool _loading = true;
  String _filtre = 'TOUS';
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.svc.getContrats();
      if (res['success'] == true) {
        setState(() { _allContrats = (res['contrats'] as List).cast<Map<String, dynamic>>(); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    return _allContrats.where((c) {
      final matchStatut = _filtre == 'TOUS' || (c['statut'] ?? '') == _filtre;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (c['numero'] ?? c['numero_contrat'] ?? '').toString().toLowerCase().contains(q) ||
          (c['client'] ?? c['client_nom']     ?? '').toString().toLowerCase().contains(q) ||
          (c['type']   ?? c['type_assurance'] ?? '').toString().toLowerCase().contains(q);
      return matchStatut && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AC.primaryMid));
    final contrats = _filtered;
    final actifs  = _allContrats.where((c) => c['statut'] == 'ACTIF').length;
    final attente = _allContrats.where((c) => c['statut'] == 'EN_ATTENTE').length;
    final expires = _allContrats.where((c) => c['statut'] == 'EXPIRE').length;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _StatMini('Total',      '${_allContrats.length}', AC.primaryMid),
        const SizedBox(width: 12),
        _StatMini('Actifs',     '$actifs',  AC.success),
        const SizedBox(width: 12),
        _StatMini('En attente', '$attente', AC.warning),
        const SizedBox(width: 12),
        _StatMini('Expirés',    '$expires', AC.textGrey),
        const Spacer(),
        // Barre de recherche
        Container(width: 200, height: 36,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.border)),
          child: TextField(onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Rechercher...', hintStyle: TextStyle(color: AC.textGrey, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: AC.textGrey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 9)))),
        const SizedBox(width: 8),
        ...['TOUS','ACTIF','EN_ATTENTE','EXPIRE'].map((f) => GestureDetector(
          onTap: () => setState(() => _filtre = f),
          child: Container(margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _filtre == f ? AC.primaryMid : Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _filtre == f ? AC.primaryMid : AC.border)),
            child: Text(f, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _filtre == f ? Colors.white : AC.textGrey))))),
      ]),
      const SizedBox(height: 20),
      _Card(title: 'Contrats (${contrats.length})', child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex:2, child: Text('N° Contrat',  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(flex:2, child: Text('Client',      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Type',         style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Durée',        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Prime MRU',    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Statut',       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Date fin',     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
          ])),
        ...contrats.map((c) => _ContratFullRow(c: c, onChangeStatut: (s) async {
          await widget.svc.modifierContrat(c['id'].toString(), {'statut': s});
          _load();
        })),
        if (contrats.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Aucun contrat trouvé', style: TextStyle(color: AC.textGrey))),
      ])),
    ]));
  }
}

// ══════════════════════════════════════════════════════
// ONGLET 4 : TARIFS
// ══════════════════════════════════════════════════════
class _TarifsTab extends StatefulWidget {
  final AdminService svc;
  const _TarifsTab({required this.svc});
  @override
  State<_TarifsTab> createState() => _TarifsTabState();
}

class _TarifsTabState extends State<_TarifsTab> {
  final _cv = {'<= 7 CV': TextEditingController(text:'8000'), '8-10 CV': TextEditingController(text:'12000'), '11-15 CV': TextEditingController(text:'18000'), '> 15 CV': TextEditingController(text:'25000')};
  final _pl = {'<= 5 places': TextEditingController(text:'0'), '6-9 places': TextEditingController(text:'2000'), '> 9 places': TextEditingController(text:'5000')};
  final _ct = {'RC Tiers (x)': TextEditingController(text:'1.0'), 'Tous Risques (x)': TextEditingController(text:'2.5')};
  final _cd = {'3 mois (x)': TextEditingController(text:'0.30'), '6 mois (x)': TextEditingController(text:'0.55'), '12 mois (x)': TextEditingController(text:'1.00')};
  bool _saved = false;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AC.warningL, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.warning.withOpacity(0.3))),
      child: const Row(children: [Icon(Icons.info_outline_rounded, color: AC.warning, size: 20), SizedBox(width: 10),
        Expanded(child: Text('Toute modification affectera les nouvelles souscriptions uniquement.', style: TextStyle(fontSize: 13, color: AC.warning, fontWeight: FontWeight.w600)))])),
    const SizedBox(height: 20),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(children: [
        _TarifCard('Puissance fiscale (MRU/an)', _cv),
        const SizedBox(height: 16),
        _TarifCard('Supplément places (MRU/an)', _pl),
      ])),
      const SizedBox(width: 16),
      Expanded(child: Column(children: [
        _TarifCard('Coefficient type', _ct),
        const SizedBox(height: 16),
        _TarifCard('Coefficient durée', _cd),
        const SizedBox(height: 16),
        _Card(title: 'Simulateur', child: _PrimeSimulator()),
      ])),
    ]),
    const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AC.textGrey, side: const BorderSide(color: AC.border)), child: const Text('Réinitialiser')),
      const SizedBox(width: 12),
      ElevatedButton.icon(onPressed: () async {
        final res = await widget.svc.updateTarifs({});
        if (res['success'] == true) setState(() => _saved = true);
      },
        icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Enregistrer'),
        style: ElevatedButton.styleFrom(backgroundColor: _saved ? AC.success : AC.primaryMid, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    ]),
  ]));
}

// ══════════════════════════════════════════════════════
// ONGLET 5 : SINISTRES
// ══════════════════════════════════════════════════════
class _SinistresTab extends StatefulWidget {
  final AdminService svc;
  const _SinistresTab({required this.svc});
  @override
  State<_SinistresTab> createState() => _SinistresTabState();
}

class _SinistresTabState extends State<_SinistresTab> {
  List<Map<String, dynamic>> _allSins = [];
  bool _loading = true;
  String _filtre = 'TOUS';
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.svc.getSinistres();
      if (res['success'] == true) {
        setState(() { _allSins = (res['sinistres'] as List).cast<Map<String, dynamic>>(); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    return _allSins.where((s) {
      final matchStatut = _filtre == 'TOUS' || (s['statut'] ?? '') == _filtre;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (s['numero'] ?? s['numero_sinistre'] ?? '').toString().toLowerCase().contains(q) ||
          (s['client'] ?? s['client_nom']      ?? '').toString().toLowerCase().contains(q) ||
          (s['description']                    ?? '').toString().toLowerCase().contains(q);
      return matchStatut && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AC.primaryMid));
    final sins = _filtered;
    final d = _allSins.where((s) => s['statut'] == 'DECLARE').length;
    final c = _allSins.where((s) => s['statut'] == 'EN_COURS').length;
    final r = _allSins.where((s) => s['statut'] == 'CLOTURE').length;
    final j = _allSins.where((s) => s['statut'] == 'REJETE').length;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _StatMini('Déclarés', '$d', AC.primaryMid),
        const SizedBox(width: 12),
        _StatMini('En cours', '$c', AC.warning),
        const SizedBox(width: 12),
        _StatMini('Résolus',  '$r', AC.success),
        const SizedBox(width: 12),
        _StatMini('Rejetés',  '$j', AC.danger),
        const Spacer(),
        // Barre de recherche
        Container(width: 200, height: 36,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.border)),
          child: TextField(onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Rechercher...', hintStyle: TextStyle(color: AC.textGrey, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: AC.textGrey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 9)))),
        const SizedBox(width: 8),
        ...['TOUS','DECLARE','EN_COURS','CLOTURE','REJETE'].map((f) => GestureDetector(
          onTap: () => setState(() => _filtre = f),
          child: Container(margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: _filtre == f ? AC.primaryMid : Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _filtre == f ? AC.primaryMid : AC.border)),
            child: Text(f.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _filtre == f ? Colors.white : AC.textGrey))))),
      ]),
      const SizedBox(height: 20),
      _Card(title: 'Sinistres (${sins.length})', child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex:2, child: Text('N° Sinistre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(flex:2, child: Text('Client',      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(flex:2, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Date',         style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            Expanded(child:       Text('Statut',       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
            SizedBox(width: 80, child: Text('Actions',  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textGrey))),
          ])),
        ...sins.map((s) => _SinistreRow(s: s, onAction: (statut) async {
          await widget.svc.modifierSinistre(s['id'].toString(), statut);
          _load();
        })),
        if (sins.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Aucun sinistre trouvé', style: TextStyle(color: AC.textGrey))),
      ])),
    ]));
  }
}

// ══════════════════════════════════════════════════════
// ONGLET 6 : NOTIFICATIONS
// ══════════════════════════════════════════════════════
class _NotificationsTab extends StatefulWidget {
  final AdminService svc;
  const _NotificationsTab({required this.svc});
  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _titreCtrl  = TextEditingController();
  final _msgCtrl    = TextEditingController();
  final _searchCtrl = TextEditingController();

  // Mode : 'GROUPE' ou 'INDIVIDUEL'
  String _mode = 'GROUPE';
  String _dest = 'TOUS';

  // Pour la recherche utilisateur
  List<Map<String, dynamic>> _allUsers   = [];
  List<Map<String, dynamic>> _resultats  = [];
  Map<String, dynamic>?      _userChoisi; // personne sélectionnée

  bool _sending  = false;
  bool _loadingUsers = false;
  List<Map<String, dynamic>> _historique = [];

  @override
  void initState() {
    super.initState();
    _loadHistorique();
    _chargerUsers();
  }

  Future<void> _chargerUsers() async {
    setState(() => _loadingUsers = true);
    final res = await widget.svc.getUtilisateurs();
    if (res['success'] == true) {
      setState(() {
        _allUsers = (res['utilisateurs'] as List).cast<Map<String, dynamic>>();
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
    }
  }

  void _rechercherUser(String q) {
    if (q.isEmpty) { setState(() => _resultats = []); return; }
    final query = q.toLowerCase();
    setState(() => _resultats = _allUsers.where((u) =>
      '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.toLowerCase().contains(query) ||
      (u['telephone'] ?? '').toString().contains(query) ||
      (u['email']     ?? '').toString().toLowerCase().contains(query)
    ).take(6).toList());
  }

  Future<void> _loadHistorique() async {
    final res = await widget.svc.getNotificationsHistorique();
    if (res['success'] == true) {
      setState(() => _historique = (res['historique'] as List? ?? []).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _envoyer() async {
    if (_titreCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    // Mode individuel : il faut avoir choisi une personne
    if (_mode == 'INDIVIDUEL' && _userChoisi == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une personne'),
        backgroundColor: AC.warning, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _sending = true);
    final res = await widget.svc.envoyerNotification(
      titre:        _titreCtrl.text,
      message:      _msgCtrl.text,
      destinataires: _mode == 'GROUPE' ? _dest : 'INDIVIDUEL',
      utilisateurId: _mode == 'INDIVIDUEL' ? _userChoisi!['id'].toString() : null,
    );
    setState(() => _sending = false);
    if (res['success'] == true) {
      _titreCtrl.clear();
      _msgCtrl.clear();
      _searchCtrl.clear();
      setState(() { _userChoisi = null; _resultats = []; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_mode == 'INDIVIDUEL'
            ? 'Notification envoyée à ${_userChoisi?['prenom'] ?? ''} avec succès'
            : 'Envoyée à ${res['count'] ?? 0} utilisateur(s)'),
        backgroundColor: AC.success, behavior: SnackBarBehavior.floating));
      _loadHistorique();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Erreur lors de l\'envoi'),
        backgroundColor: AC.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _Card(title: 'Envoyer une notification', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Choix du mode ──────────────────────────────
      const Text('Type d\'envoi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.textDark)),
      const SizedBox(height: 8),
      Row(children: [
        _ModeBtn(label: 'Groupe', icon: Icons.group_rounded,
          selected: _mode == 'GROUPE',
          onTap: () => setState(() { _mode = 'GROUPE'; _userChoisi = null; _resultats = []; _searchCtrl.clear(); })),
        const SizedBox(width: 10),
        _ModeBtn(label: 'Personne précise', icon: Icons.person_rounded,
          selected: _mode == 'INDIVIDUEL',
          onTap: () => setState(() => _mode = 'INDIVIDUEL')),
      ]),
      const SizedBox(height: 16),

      // ── Mode GROUPE : choisir le rôle ──────────────
      if (_mode == 'GROUPE') ...[
        const Text('Destinataires', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.textDark)),
        const SizedBox(height: 8),
        Row(children: ['TOUS','CLIENT','AGENT','EXPERT'].map((d) => GestureDetector(
          onTap: () => setState(() => _dest = d),
          child: Container(margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _dest == d ? AC.primaryMid : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _dest == d ? AC.primaryMid : AC.border)),
            child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: _dest == d ? Colors.white : AC.textGrey))))).toList()),
        const SizedBox(height: 16),
      ],

      // ── Mode INDIVIDUEL : recherche utilisateur ────
      if (_mode == 'INDIVIDUEL') ...[
        const Text('Chercher la personne', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.textDark)),
        const SizedBox(height: 8),

        // Personne sélectionnée
        if (_userChoisi != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AC.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AC.success.withOpacity(0.3))),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: AC.primaryMid.withOpacity(0.15),
                child: Text((_userChoisi!['prenom'] ?? 'U')[0],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AC.primaryMid))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_userChoisi!['prenom'] ?? ''} ${_userChoisi!['nom'] ?? ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.textDark)),
                Text('${_userChoisi!['telephone'] ?? ''} • ${_userChoisi!['role'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AC.textGrey)),
              ])),
              GestureDetector(
                onTap: () => setState(() { _userChoisi = null; _searchCtrl.clear(); _resultats = []; }),
                child: const Icon(Icons.close_rounded, color: AC.danger, size: 20)),
            ]),
          )
        else ...[
          // Champ de recherche
          Container(height: 42,
            decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _rechercherUser,
              decoration: const InputDecoration(
                hintText: 'Nom, téléphone ou email...',
                hintStyle: TextStyle(color: AC.textGrey, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AC.textGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12)))),
          // Résultats
          if (_loadingUsers)
            const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: AC.primaryMid, strokeWidth: 2)))
          else if (_resultats.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AC.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
              child: Column(children: _resultats.map((u) {
                final rc = {'ADMIN': AC.danger, 'AGENT': AC.warning, 'CLIENT': AC.primaryMid, 'EXPERT': AC.purple};
                final role = u['role'] as String? ?? '';
                return GestureDetector(
                  onTap: () => setState(() {
                    _userChoisi = u;
                    _resultats  = [];
                    _searchCtrl.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border.withOpacity(0.5)))),
                    child: Row(children: [
                      CircleAvatar(radius: 15, backgroundColor: (rc[role] ?? AC.primaryMid).withOpacity(0.15),
                        child: Text((u['prenom'] ?? 'U')[0], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: rc[role] ?? AC.primaryMid))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${u['prenom'] ?? ''} ${u['nom'] ?? ''}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.textDark)),
                        Text('${u['telephone'] ?? ''} • ${u['email'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: AC.textGrey)),
                      ])),
                      _Badge(role, rc[role] ?? AC.primaryMid),
                    ]),
                  ),
                );
              }).toList()),
            ),
        ],
        const SizedBox(height: 16),
      ],

      // ── Titre & Message ────────────────────────────
      _AdminField(ctrl: _titreCtrl, hint: 'Titre de la notification', icon: Icons.title_rounded),
      const SizedBox(height: 12),
      Container(constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
        child: TextField(controller: _msgCtrl, maxLines: 4,
          decoration: const InputDecoration(hintText: 'Message...', hintStyle: TextStyle(color: AC.textGrey, fontSize: 13),
              border: InputBorder.none, contentPadding: EdgeInsets.all(14)))),
      const SizedBox(height: 16),

      // ── Bouton Envoyer ─────────────────────────────
      Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(
        onPressed: _sending ? null : _envoyer,
        icon: _sending
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(_sending ? 'Envoi...' : 'Envoyer'),
        style: ElevatedButton.styleFrom(backgroundColor: AC.primaryMid, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ])),
    const SizedBox(height: 20),
    _Card(title: 'Historique (${_historique.length})', child: Column(children: [
      ..._historique.map((n) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2FF)))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AC.blueLight, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_rounded, color: AC.primaryMid, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n['titre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.textDark)),
            Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: AC.textGrey)),
          ])),
          Text('${n['nb'] ?? 0} dest.', style: const TextStyle(fontSize: 11, color: AC.primaryMid, fontWeight: FontWeight.w700)),
        ]))),
      if (_historique.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aucune notification', style: TextStyle(color: AC.textGrey))),
    ])),
  ]));
}

// ══════════════════════════════════════════════════════
// ONGLET 7 : EXPORT
// ══════════════════════════════════════════════════════
class _ExportTab extends StatefulWidget {
  final AdminService svc;
  const _ExportTab({required this.svc});
  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  // Quel export est en cours de téléchargement
  String? _enCours;

  Future<void> _telecharger(BuildContext ctx, String type) async {
    setState(() => _enCours = type);
    try {
      final token = await widget.svc.getTokenPublic();
      final url   = widget.svc.getExportUrl(type);

      // Téléchargement via http avec le token
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Déclencher le téléchargement dans le navigateur (Flutter Web)
        final bytes    = response.bodyBytes;
        final blob     = html.Blob([bytes], 'text/csv;charset=utf-8');
        final blobUrl  = html.Url.createObjectUrlFromBlob(blob);
        final anchor   = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', '${type}_${DateTime.now().toIso8601String().substring(0, 10)}.csv')
          ..click();
        html.Url.revokeObjectUrl(blobUrl);

        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Fichier $type.csv téléchargé avec succès !'),
          backgroundColor: AC.success, behavior: SnackBarBehavior.floating));
      } else {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Erreur serveur: ${response.statusCode}'),
          backgroundColor: AC.danger, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: AC.danger, behavior: SnackBarBehavior.floating));
    } finally {
      setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
    GridView.count(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16,
      childAspectRatio: 1.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: [
        _ExportCard('Utilisateurs', 'Clients, agents et experts',  Icons.people_rounded,         AC.primaryMid, _enCours == 'utilisateurs', () => _telecharger(context, 'utilisateurs')),
        _ExportCard('Contrats',     'Tous les contrats',           Icons.description_rounded,    AC.accent,     _enCours == 'contrats',     () => _telecharger(context, 'contrats')),
        _ExportCard('Paiements',    'Historique des paiements',    Icons.payment_rounded,        AC.success,    _enCours == 'paiements',    () => _telecharger(context, 'paiements')),
        _ExportCard('Sinistres',    'Déclarations et traitements', Icons.car_crash_rounded,      AC.warning,    _enCours == 'sinistres',    () => _telecharger(context, 'sinistres')),
        _ExportCard('Véhicules',    'Parc automobile assuré',      Icons.directions_car_rounded, AC.purple,     _enCours == 'vehicules',    () => _telecharger(context, 'vehicules')),
      ]),
    const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.blueLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: AC.primaryMid, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text(
          "Cliquez sur une carte pour télécharger le fichier CSV directement. Il s'ouvrira dans Excel.",
          style: TextStyle(fontSize: 13, color: AC.primaryMid))),
      ])),
  ]));
}

// ══════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ══════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final String title; final Widget child; final Widget? action;
  const _Card({required this.title, required this.child, this.action});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AC.textDark)),
        if (action != null) ...[const Spacer(), action!],
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0,4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Icon(Icons.trending_up_rounded, color: color.withOpacity(0.5), size: 16),
      ]),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AC.textGrey)),
    ]),
  );
}

class _StatMini extends StatelessWidget {
  final String label, value; final Color color;
  const _StatMini(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AC.textGrey)),
    ]),
  );
}

class _Bar2 extends StatelessWidget {
  final String label; final int pct; final Color color;
  const _Bar2(this.label, this.pct, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AC.textDark))),
    Expanded(child: Stack(children: [
      Container(height: 8, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
      FractionallySizedBox(widthFactor: pct / 100, child: Container(height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
    ])),
    const SizedBox(width: 8),
    Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _ContratRow extends StatelessWidget {
  final String num, client, type, prime, statut;
  const _ContratRow({required this.num, required this.client, required this.type, required this.prime, required this.statut});
  @override
  Widget build(BuildContext context) {
    final c = {'ACTIF': AC.success, 'EN_ATTENTE': AC.warning, 'EXPIRE': AC.textGrey};
    return Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2FF)))),
      child: Row(children: [
        Expanded(flex:2, child: Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textDark), overflow: TextOverflow.ellipsis)),
        Expanded(flex:2, child: Text(client, style: const TextStyle(fontSize: 11, color: AC.textGrey), overflow: TextOverflow.ellipsis)),
        Expanded(child: Text(type == 'TOUS_RISQUES' ? 'Tous Risques' : 'RC Tiers', style: const TextStyle(fontSize: 11))),
        Expanded(child: Text(prime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.primaryMid))),
        Expanded(child: _Badge(statut, c[statut] ?? AC.textGrey)),
      ]));
  }
}

class _ContratFullRow extends StatelessWidget {
  final Map<String, dynamic> c;
  final Function(String) onChangeStatut;
  const _ContratFullRow({required this.c, required this.onChangeStatut});
  @override
  Widget build(BuildContext context) {
    final numero  = (c['numero'] ?? c['numero_contrat'] ?? '-').toString();
    final client  = (c['client'] ?? c['client_nom'] ?? '-').toString();
    final tel     = (c['telephone'] ?? c['client_tel'] ?? '').toString();
    final type    = (c['type'] ?? c['type_assurance'] ?? '').toString();
    final duree   = (c['duree'] ?? c['duree_mois'] ?? 0).toString();
    final prime   = double.tryParse((c['prime'] ?? c['prime_montant'] ?? 0).toString()) ?? 0.0;
    final statut  = (c['statut'] ?? '-').toString();
    final dateFin = (c['date_fin'] ?? '').toString();
    final cc = {'ACTIF': AC.success, 'EN_ATTENTE': AC.warning, 'EXPIRE': AC.textGrey, 'SUSPENDU': AC.danger, 'ANNULE': AC.danger};
    return Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2FF)))),
      child: Row(children: [
        Expanded(flex:2, child: Text(numero, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textDark), overflow: TextOverflow.ellipsis)),
        Expanded(flex:2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client, style: const TextStyle(fontSize: 11, color: AC.textDark), overflow: TextOverflow.ellipsis),
          Text(tel,    style: const TextStyle(fontSize: 10, color: AC.textGrey)),
        ])),
        Expanded(child: Text(type == 'TOUS_RISQUES' ? 'Tous Risques' : 'RC Tiers', style: const TextStyle(fontSize: 11))),
        Expanded(child: Text('$duree mois', style: const TextStyle(fontSize: 11))),
        Expanded(child: Text('${prime.toStringAsFixed(0)} MRU', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.primaryMid))),
        Expanded(child: _Badge(statut, cc[statut] ?? AC.textGrey)),
        Expanded(child: Text(dateFin, style: const TextStyle(fontSize: 10, color: AC.textGrey))),
      ]));
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit, onSuspend;
  const _UserRow({required this.user, required this.onEdit, required this.onSuspend});
  @override
  Widget build(BuildContext context) {
    final rc = {'ADMIN': AC.danger, 'AGENT': AC.warning, 'CLIENT': AC.primaryMid, 'EXPERT': AC.purple};
    final rs = {'ACTIF': AC.success, 'INACTIF': AC.textGrey, 'SUSPENDU': AC.danger};
    final role   = user['role'] as String? ?? '';
    final statut = user['statut'] as String? ?? '';
    return Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2FF)))),
      child: Row(children: [
        Expanded(flex:2, child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: (rc[role] ?? AC.primaryMid).withOpacity(0.15),
            child: Text((user['prenom'] ?? 'U')[0], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: rc[role] ?? AC.primaryMid))),
          const SizedBox(width: 10),
          Expanded(child: Text('${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.textDark), overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(child: Text(user['telephone'] ?? '', style: const TextStyle(fontSize: 12, color: AC.textGrey))),
        Expanded(child: Text(user['email'] ?? '-', style: const TextStyle(fontSize: 11, color: AC.textGrey), overflow: TextOverflow.ellipsis)),
        Expanded(child: _Badge(role, rc[role] ?? AC.primaryMid)),
        Expanded(child: _Badge(statut, rs[statut] ?? AC.textGrey)),
        SizedBox(width: 80, child: Row(children: [
          IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AC.primaryMid), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.block_rounded, size: 18, color: AC.danger), onPressed: onSuspend, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ])),
      ]));
  }
}

class _SinistreRow extends StatelessWidget {
  final Map<String, dynamic> s;
  final Function(String) onAction;
  const _SinistreRow({required this.s, required this.onAction});
  @override
  Widget build(BuildContext context) {
    final c = {'DECLARE': AC.primaryMid, 'EN_COURS': AC.warning, 'CLOTURE': AC.success, 'REJETE': AC.danger};
    final statut = s['statut'] as String? ?? '';
    return Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2FF)))),
      child: Row(children: [
        Expanded(flex:2, child: Text((s['numero'] ?? s['numero_sinistre'] ?? '-').toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.textDark))),
        Expanded(flex:2, child: Text((s['client'] ?? s['client_nom'] ?? '-').toString(), style: const TextStyle(fontSize: 11, color: AC.textGrey), overflow: TextOverflow.ellipsis)),
        Expanded(flex:2, child: Text((s['description'] ?? '').toString(), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
        Expanded(child: Text((s['date_decl'] ?? s['date_declaration'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: AC.textGrey))),
        Expanded(child: _Badge(statut.replaceAll('_', ' '), c[statut] ?? AC.textGrey)),
        SizedBox(width: 90, child: Row(children: [
          if (statut == 'DECLARE')
            IconButton(icon: const Icon(Icons.engineering_rounded, size: 18, color: AC.warning), tooltip: 'En cours', onPressed: () => onAction('EN_COURS'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          if (statut != 'CLOTURE' && statut != 'REJETE')
            IconButton(icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AC.success), tooltip: 'Résoudre', onPressed: () => onAction('CLOTURE'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          if (statut != 'REJETE' && statut != 'CLOTURE')
            IconButton(icon: const Icon(Icons.cancel_outlined, size: 18, color: AC.danger), tooltip: 'Rejeter', onPressed: () => onAction('REJETE'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ])),
      ]));
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}

class _Btn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool outline;
  const _Btn({required this.label, required this.icon, required this.onTap, this.outline = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: outline ? Colors.transparent : AC.primaryMid, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outline ? AC.border : AC.primaryMid)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: outline ? AC.primaryMid : Colors.white), const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: outline ? AC.primaryMid : Colors.white)),
      ])));
}

class _UserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Function(Map<String, dynamic>) onSave;
  const _UserDialog({this.user, required this.onSave});
  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final _nomCtrl    = TextEditingController(text: widget.user?['nom'] ?? '');
  late final _prenomCtrl = TextEditingController(text: widget.user?['prenom'] ?? '');
  late final _telCtrl    = TextEditingController(text: widget.user?['telephone'] ?? '');
  late final _emailCtrl  = TextEditingController(text: widget.user?['email'] ?? '');
  late final _pinCtrl    = TextEditingController();
  String _role = 'CLIENT';

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(width: 420, padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.user == null ? 'Nouvel utilisateur' : 'Modifier utilisateur',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AC.textDark)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _AdminField(ctrl: _prenomCtrl, hint: 'Prénom *', icon: Icons.person_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _AdminField(ctrl: _nomCtrl, hint: 'Nom *', icon: Icons.person_rounded)),
        ]),
        const SizedBox(height: 12),
        _AdminField(ctrl: _telCtrl,   hint: 'Téléphone *', icon: Icons.phone_rounded),
        const SizedBox(height: 12),
        _AdminField(ctrl: _emailCtrl, hint: 'Email', icon: Icons.email_rounded),
        const SizedBox(height: 12),
        _AdminField(ctrl: _pinCtrl,   hint: widget.user == null ? 'Code PIN *' : 'Nouveau PIN (optionnel)', icon: Icons.lock_rounded),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AC.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _role, isExpanded: true,
            items: ['CLIENT','AGENT','EXPERT','ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _role = v!)))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: AC.textGrey, side: const BorderSide(color: AC.border)),
              child: const Text('Annuler'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () {
              widget.onSave({'nom': _nomCtrl.text, 'prenom': _prenomCtrl.text, 'telephone': _telCtrl.text,
                'email': _emailCtrl.text, 'role': _role,
                if (_pinCtrl.text.isNotEmpty) 'code_pin': _pinCtrl.text});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AC.primaryMid, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(widget.user == null ? 'Créer' : 'Enregistrer'))),
        ]),
      ])),
  );
}

class _ModeBtn extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AC.primaryMid : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AC.primaryMid : AC.border),
        boxShadow: selected ? [BoxShadow(color: AC.primaryMid.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,3))] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: selected ? Colors.white : AC.textGrey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AC.textGrey)),
      ]),
    ),
  );
}

class _TarifCard extends StatelessWidget {
  final String title; final Map<String, TextEditingController> items;
  const _TarifCard(this.title, this.items);
  @override
  Widget build(BuildContext context) => _Card(title: title, child: Column(children: items.entries.map((e) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, color: AC.textDark))),
      SizedBox(width: 120, child: TextField(controller: e.value, keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.primaryMid),
        textAlign: TextAlign.right,
        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AC.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AC.primaryMid)),
          filled: true, fillColor: AC.bg))),
    ]))).toList()));
}

class _PrimeSimulator extends StatefulWidget {
  @override
  State<_PrimeSimulator> createState() => _PrimeSimulatorState();
}

class _PrimeSimulatorState extends State<_PrimeSimulator> {
  int _cv = 7, _places = 5, _duree = 12;
  String _type = 'TIERS';
  double get _prime {
    final cv = _cv<=7?8000:_cv<=10?12000:_cv<=15?18000:25000;
    final pl = _places<=5?0:_places<=9?2000:5000;
    final ct = _type=='TOUS_RISQUES'?2.5:1.0;
    final cd = _duree==3?0.30:_duree==6?0.55:1.0;
    return (cv+pl)*ct*cd;
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Puissance: $_cv CV', style: const TextStyle(fontSize: 12, color: AC.textGrey)),
        Slider(value: _cv.toDouble(), min:4, max:20, divisions:16, activeColor: AC.primaryMid, onChanged:(v)=>setState(()=>_cv=v.round())),
      ])),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Places: $_places', style: const TextStyle(fontSize: 12, color: AC.textGrey)),
        Slider(value: _places.toDouble(), min:2, max:15, divisions:13, activeColor: AC.primaryMid, onChanged:(v)=>setState(()=>_places=v.round())),
      ])),
    ]),
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Type', style: TextStyle(fontSize: 12, color: AC.textGrey)),
        const SizedBox(height: 6),
        Row(children: ['TIERS','TOUS_RISQUES'].map((t) => GestureDetector(onTap:()=>setState(()=>_type=t),
          child: Container(margin: const EdgeInsets.only(right:8), padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
            decoration: BoxDecoration(color:_type==t?AC.primaryMid:AC.bg, borderRadius:BorderRadius.circular(20), border:Border.all(color:_type==t?AC.primaryMid:AC.border)),
            child: Text(t=='TIERS'?'RC Tiers':'Tous Risques', style:TextStyle(fontSize:10, fontWeight:FontWeight.w700, color:_type==t?Colors.white:AC.textGrey))))).toList()),
      ])),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Durée', style: TextStyle(fontSize: 12, color: AC.textGrey)),
        const SizedBox(height: 6),
        Row(children: [3,6,12].map((d) => GestureDetector(onTap:()=>setState(()=>_duree=d),
          child: Container(margin: const EdgeInsets.only(right:8), padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
            decoration: BoxDecoration(color:_duree==d?AC.primaryMid:AC.bg, borderRadius:BorderRadius.circular(20), border:Border.all(color:_duree==d?AC.primaryMid:AC.border)),
            child: Text('$d mois', style:TextStyle(fontSize:10, fontWeight:FontWeight.w700, color:_duree==d?Colors.white:AC.textGrey))))).toList()),
      ])),
    ]),
    const SizedBox(height: 12),
    Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AC.primary, AC.primaryMid]), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Text('Prime calculée', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text('${_prime.toStringAsFixed(0)} MRU', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      ])),
  ]);
}

class _ExportCard extends StatelessWidget {
  final String titre, desc; final IconData icon; final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _ExportCard(this.titre, this.desc, this.icon, this.color, this.loading, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: loading ? color : color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const Spacer(),
          // Icône de téléchargement ou spinner
          loading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: color, strokeWidth: 2))
              : Icon(Icons.download_rounded, color: color, size: 20),
        ]),
        const SizedBox(height: 12),
        Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AC.textDark)),
        const SizedBox(height: 4),
        Text(
          loading ? 'Téléchargement en cours...' : desc,
          style: TextStyle(fontSize: 12, color: loading ? color : AC.textGrey,
              fontWeight: loading ? FontWeight.w600 : FontWeight.normal)),
      ])));
}

class _AdminField extends StatelessWidget {
  final TextEditingController ctrl; final String hint; final IconData icon;
  const _AdminField({required this.ctrl, required this.hint, required this.icon});
  @override
  Widget build(BuildContext context) => TextFormField(controller: ctrl,
    style: const TextStyle(fontSize: 14, color: AC.textDark),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AC.textGrey, fontSize: 13),
      prefixIcon: Icon(icon, color: AC.textGrey, size: 18), filled: true, fillColor: AC.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AC.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AC.primaryMid)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AC.border)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
}

class _ErrorWidget extends StatelessWidget {
  final String msg; final VoidCallback onRetry;
  const _ErrorWidget({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline_rounded, color: AC.danger, size: 48),
    const SizedBox(height: 16),
    Text(msg, style: const TextStyle(color: AC.danger), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(backgroundColor: AC.primaryMid, foregroundColor: Colors.white)),
  ]));
}