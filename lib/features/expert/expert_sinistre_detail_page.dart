// lib/features/expert/expert_sinistre_detail_page.dart

import 'package:flutter/material.dart';
import '../../core/services/expert_service.dart';

class ExpertSinistreDetailPage extends StatefulWidget {
  final Map<String, dynamic> sinistre;
  final ExpertService expertService;
  const ExpertSinistreDetailPage({super.key, required this.sinistre, required this.expertService});
  @override State<ExpertSinistreDetailPage> createState() => _ExpertSinistreDetailPageState();
}

class _ExpertSinistreDetailPageState extends State<ExpertSinistreDetailPage>
    with SingleTickerProviderStateMixin {
  static const _bleu1  = Color(0xFF1535A8);
  static const _bleu2  = Color(0xFF1A56DB);
  static const _vert   = Color(0xFF16A34A);
  static const _rouge  = Color(0xFFDC2626);
  static const _orange = Color(0xFFEA580C);
  static const _fond   = Color(0xFFF5F7FF);
  static const _texte  = Color(0xFF111827);
  static const _gris   = Color(0xFF6B7280);
  static const _card   = Color(0xFFFFFFFF);

  late TabController _tabController;

  final _rapportCtrl          = TextEditingController();
  final _montantEstimeCtrl    = TextEditingController();
  final _montantIndemniseCtrl = TextEditingController();
  final _messageCtrl          = TextEditingController();

  String _statut      = '';
  bool   _saving      = false;
  bool   _loadingDocs = true;
  List   _documents   = [];

  DateTime?  _rdvDate;
  TimeOfDay? _rdvHeure;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _statut = widget.sinistre['statut'] ?? 'DECLARE';
    _rapportCtrl.text          = widget.sinistre['rapport_expert'] ?? '';
    _montantEstimeCtrl.text    = widget.sinistre['montant_estime']?.toString() ?? '';
    _montantIndemniseCtrl.text = widget.sinistre['montant_indemnise']?.toString() ?? '';
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rapportCtrl.dispose();
    _montantEstimeCtrl.dispose();
    _montantIndemniseCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final id = widget.sinistre['id'];
      if (id == null) return;
      final res = await widget.expertService.getDocumentsSinistre(id);
      if (mounted) {
        setState(() {
          _documents   = res['documents'] ?? [];
          _loadingDocs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  Future<void> _sauvegarder() async {
    setState(() => _saving = true);
    try {
      final id  = widget.sinistre['id'];
      final res = await widget.expertService.updateSinistre(
        id,
        statut:           _statut,
        rapportExpert:    _rapportCtrl.text.trim().isNotEmpty ? _rapportCtrl.text.trim() : null,
        montantEstime:    double.tryParse(_montantEstimeCtrl.text),
        montantIndemnise: double.tryParse(_montantIndemniseCtrl.text),
      );
      if (!mounted) return;
      _showSnack(
        res['success'] == true ? 'Dossier mis à jour !' : res['message'] ?? 'Erreur',
        res['success'] == true ? _vert : _rouge,
      );
      if (res['success'] == true) Navigator.pop(context, true);
    } catch (_) {
      _showSnack('Erreur de connexion.', _rouge);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _envoyerMessage() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    final clientId = widget.sinistre['client_id'];
    if (clientId == null) {
      _showSnack('Client introuvable.', _rouge);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await widget.expertService.envoyerMessage(
        clientId: clientId,
        message:  _messageCtrl.text.trim(),
        sujet:    'Message concernant votre sinistre ${widget.sinistre['numero'] ?? ''}',
      );
      if (!mounted) return;
      _showSnack(
        res['success'] == true ? 'Message envoyé !' : res['message'] ?? 'Erreur',
        res['success'] == true ? _vert : _rouge,
      );
      if (res['success'] == true) _messageCtrl.clear();
    } catch (_) {
      _showSnack('Erreur de connexion.', _rouge);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'DECLARE':   return _rouge;
      case 'EN_COURS':  return _bleu2;
      case 'EXPERTISE': return _orange;
      case 'APPROUVE':  return _vert;
      case 'REJETE':    return _rouge;
      case 'CLOTURE':
      case 'INDEMNISE': return _vert;
      default:          return _gris;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sinistre;
    return Scaffold(
      backgroundColor: _fond,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: _bleu1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['numero'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client : ${s['client'] ?? ''}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statut,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Infos'),
                Tab(text: 'Rapport'),
                Tab(text: 'Documents'),
                Tab(text: 'Contact'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfos(s),
            _buildRapport(),
            _buildDocuments(),
            _buildContact(s),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: GestureDetector(
            onTap: _saving ? null : _sauvegarder,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: _bleu2.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Sauvegarder le dossier',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── TAB 1 : INFOS ──────────────────────────────────────
  Widget _buildInfos(Map s) {
    final statuts = ['DECLARE', 'EN_COURS', 'EXPERTISE', 'APPROUVE', 'REJETE', 'CLOTURE', 'INDEMNISE'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informations du sinistre'),
          _infoCard([
            _infoRow(Icons.tag_rounded,            'N° Sinistre',      s['numero']           ?? ''),
            _infoRow(Icons.person_rounded,         'Client',           s['client']           ?? ''),
            _infoRow(Icons.phone_rounded,          'Téléphone',        s['telephone']        ?? ''),
            _infoRow(Icons.article_rounded,        'Contrat',          s['contrat']          ?? ''),
            _infoRow(Icons.calendar_today_rounded, 'Date accident',    s['date_accident']    ?? ''),
            _infoRow(Icons.event_note_rounded,     'Date déclaration', s['date_declaration'] ?? ''),
            _infoRow(Icons.location_on_rounded,    'Lieu',             s['lieu']             ?? 'Non renseigné'),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Description'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              s['description'] ?? '',
              style: const TextStyle(fontSize: 14, color: _texte, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Changer le statut'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut actuel', style: TextStyle(fontSize: 12, color: _gris, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuts.map((st) {
                    final active = _statut == st;
                    return GestureDetector(
                      onTap: () => setState(() => _statut = st),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? _statutColor(st) : _fond,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? _statutColor(st) : const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          st,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _gris,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── TAB 2 : RAPPORT ────────────────────────────────────
  Widget _buildRapport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Rapport d\'expertise'),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _rapportCtrl,
              maxLines: 10,
              style: const TextStyle(fontSize: 14, color: _texte, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Saisissez votre rapport d\'expertise ici...\n\n• Constatations\n• Nature des dommages\n• Causes probables\n• Recommandations',
                hintStyle: TextStyle(color: _gris.withOpacity(0.6), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Estimation financière'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _champMontant('Montant estimé des dommages (MRU)', _montantEstimeCtrl, _orange),
                const SizedBox(height: 16),
                _champMontant('Montant d\'indemnisation proposé (MRU)', _montantIndemniseCtrl, _vert),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Rendez-vous d\'inspection'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate:   DateTime.now(),
                            lastDate:    DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => _rdvDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _fond,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: _bleu2, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _rdvDate != null
                                    ? '${_rdvDate!.day}/${_rdvDate!.month}/${_rdvDate!.year}'
                                    : 'Choisir une date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _rdvDate != null ? _texte : _gris,
                                  fontWeight: _rdvDate != null ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final h = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (h != null) setState(() => _rdvHeure = h);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _fond,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: _bleu2, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _rdvHeure != null
                                    ? '${_rdvHeure!.hour.toString().padLeft(2, '0')}:${_rdvHeure!.minute.toString().padLeft(2, '0')}'
                                    : 'Choisir l\'heure',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _rdvHeure != null ? _texte : _gris,
                                  fontWeight: _rdvHeure != null ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_rdvDate != null && _rdvHeure != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _vert.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _vert.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: _vert, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'RDV fixé : ${_rdvDate!.day}/${_rdvDate!.month}/${_rdvDate!.year}'
                          ' à ${_rdvHeure!.hour.toString().padLeft(2, '0')}:${_rdvHeure!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _vert),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── TAB 3 : DOCUMENTS ──────────────────────────────────
  Widget _buildDocuments() {
    if (_loadingDocs) return const Center(child: CircularProgressIndicator(color: _bleu2));
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _bleu2.withOpacity(0.06), shape: BoxShape.circle),
              child: const Icon(Icons.folder_open_rounded, color: Color(0xFFADBDD8), size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Aucun document', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            const Text(
              'Le client n\'a pas encore uploadé de documents.',
              style: TextStyle(fontSize: 13, color: _gris),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _documents.length,
      itemBuilder: (_, i) {
        final d = _documents[i] as Map;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _bleu2.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(_docIcon(d['type_document'] ?? ''), color: _bleu2, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['nom_fichier'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _texte),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(d['type_document'] ?? '', style: const TextStyle(fontSize: 11, color: _gris)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _vert.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Valide', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _vert)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 4 : CONTACT ────────────────────────────────────
  Widget _buildContact(Map s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contacter le client'),
          _infoCard([
            _infoRow(Icons.person_rounded, 'Client',    s['client']    ?? ''),
            _infoRow(Icons.phone_rounded,  'Téléphone', s['telephone'] ?? ''),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Envoyer un message'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _fond, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, color: _texte),
                    decoration: InputDecoration(
                      hintText: 'Votre message au client...',
                      hintStyle: TextStyle(color: _gris.withOpacity(0.6), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _saving ? null : _envoyerMessage,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_bleu1, _bleu2]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Envoyer le message',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── WIDGETS UTILITAIRES ─────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _texte)),
  );

  Widget _infoCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: _bleu2.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _bleu2, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _texte)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _champMontant(String label, TextEditingController ctrl, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: _gris, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.monetization_on_rounded, color: color, size: 20),
            suffixText: 'MRU',
            suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
    ],
  );

  IconData _docIcon(String type) {
    switch (type) {
      case 'PHOTO_SINISTRE': return Icons.photo_camera_rounded;
      case 'RAPPORT_EXPERT': return Icons.description_rounded;
      case 'FACTURE':        return Icons.receipt_rounded;
      default:               return Icons.insert_drive_file_rounded;
    }
  }
}