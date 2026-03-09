// lib/features/paiement/paiement_page.dart

import 'package:flutter/material.dart';
import 'nouveau_paiement_page.dart';

// ── Modèles locaux ───────────────────────────────────────────────────────────
class Paiement {
  final String id;
  final String contratId;
  final String contratType;
  final double montant;
  final String methode;
  final String statut;
  final String date;

  const Paiement({
    required this.id,
    required this.contratId,
    required this.contratType,
    required this.montant,
    required this.methode,
    required this.statut,
    required this.date,
  });
}

// ── Page principale ──────────────────────────────────────────────────────────
class PaiementPage extends StatefulWidget {
  final Map<String, dynamic> contrat;
  const PaiementPage({super.key, required this.contrat});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  static const kBlue        = Color(0xFF1E3A8A);
  static const kBlueMid     = Color(0xFF2563EB);
  static const kBlueLight   = Color(0xFFDBEAFE);
  static const kPurple      = Color(0xFF7C3AED);
  static const kGreen       = Color(0xFF16A34A);
  static const kGreenLight  = Color(0xFFDCFCE7);
  static const kOrange      = Color(0xFFEA580C);
  static const kOrangeLight = Color(0xFFFFF0E6);
  static const kGray        = Color(0xFF64748B);
  static const kGrayLight   = Color(0xFFF1F5F9);
  static const kText        = Color(0xFF1E293B);
  static const kBorder      = Color(0xFFE2E8F0);
  static const kBg          = Color(0xFFEEF2FF);

  String _typeLabel(dynamic type) {
    if (type == null) return 'Tous Risques';
    return type.toString() == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers';
  }

  List<Paiement> get _mockPaiements => [
        Paiement(
          id: 'PAY-2026-001',
          contratId: widget.contrat['numero_contrat'] ?? 'ASR-2026-000001',
          contratType: _typeLabel(widget.contrat['type_assurance']),
          montant: double.tryParse(
                  widget.contrat['prime_montant']?.toString() ?? '13750') ??
              13750,
          methode: 'Masrvi',
          statut: 'Confirmé',
          date: '2026-03-07',
        ),
        const Paiement(
          id: 'PAY-2026-002',
          contratId: 'ASR-2026-000002',
          contratType: 'Tiers',
          montant: 7500,
          methode: 'Virement bancaire',
          statut: 'En attente',
          date: '2026-03-07',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final numeroContrat = widget.contrat['numero_contrat'] ?? '—';
    final dateFin       = widget.contrat['date_fin']       ?? '—';
    final typeLabel     = _typeLabel(widget.contrat['type_assurance']);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRappelBanner(numeroContrat, dateFin),
                  const SizedBox(height: 16),
                  _buildSectionHeader(context),
                  const SizedBox(height: 12),
                  ..._mockPaiements.map((p) => _buildCartePaiement(context, p)),
                  const SizedBox(height: 8),
                  _buildRenouvellementCard(numeroContrat, typeLabel, dateFin),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header dégradé ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue, kBlueMid, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x4D2563EB), blurRadius: 20, offset: Offset(0, 4))
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Mes paiements',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }

  // ── Bannière rappel expiration ──────────────────────────────────────────────
  Widget _buildRappelBanner(String numeroContrat, String dateFin) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rappel d\'expiration',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kOrange,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Votre contrat ',
                    style: const TextStyle(fontSize: 12, color: kText),
                    children: [
                      TextSpan(
                          text: numeroContrat,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' expire le '),
                      TextSpan(
                          text: dateFin,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: '. Renouvelez en un clic.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _renouvelerContrat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    elevation: 0,
                  ),
                  child: const Text('🔄 Renouveler maintenant'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête de section ──────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Historique des paiements',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: kText, fontSize: 16)),
        GestureDetector(
          onTap: () => _ouvrirNouveauPaiement(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kBlue, kBlueMid]),
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Nouveau',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Carte paiement ──────────────────────────────────────────────────────────
  Widget _buildCartePaiement(BuildContext context, Paiement p) {
    return GestureDetector(
      onTap: () => _voirDetail(context, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F1E3A8A),
                blurRadius: 12,
                offset: Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kText,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(p.contratId,
                        style:
                            const TextStyle(fontSize: 12, color: kGray)),
                  ],
                ),
                _buildBadge(p.statut),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildInfoCol('Montant', '${_formatMontant(p.montant)} MRU'),
                _buildInfoCol('Méthode', p.methode),
                _buildInfoCol('Date', p.date),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kGray)),
          const SizedBox(height: 2),
          Text(val,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kText)),
        ],
      ),
    );
  }

  // ── Carte renouvellement ────────────────────────────────────────────────────
  Widget _buildRenouvellementCard(
      String numeroContrat, String typeLabel, String dateFin) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Text('🔄', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Renouvellement en un clic',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kPurple,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('$numeroContrat — $typeLabel',
                    style: const TextStyle(fontSize: 12, color: kText)),
                Text('Expire le $dateFin',
                    style: const TextStyle(fontSize: 12, color: kGray)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _renouvelerContrat,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Renouveler',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Badge statut ────────────────────────────────────────────────────────────
  Widget _buildBadge(String statut) {
    Color bg, color;
    switch (statut) {
      case 'Confirmé':
        bg = kGreenLight;
        color = kGreen;
      case 'En attente':
        bg = kOrangeLight;
        color = kOrange;
      default:
        bg = kGrayLight;
        color = kGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(statut,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  void _ouvrirNouveauPaiement(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NouveauPaiementPage()));
  }

  void _voirDetail(BuildContext context, Paiement p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DetailPaiementPage(paiement: p)));
  }

  void _renouvelerContrat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Renouvellement en cours...'),
          backgroundColor: kPurple),
    );
  }

  String _formatMontant(double m) => m
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]} ');
}

// ── Page détail paiement ─────────────────────────────────────────────────────
class DetailPaiementPage extends StatelessWidget {
  final Paiement paiement;
  const DetailPaiementPage({super.key, required this.paiement});

  static const kBlue      = Color(0xFF1E3A8A);
  static const kBlueMid   = Color(0xFF2563EB);
  static const kBlueLight = Color(0xFFDBEAFE);
  static const kText      = Color(0xFF1E293B);
  static const kGray      = Color(0xFF64748B);
  static const kBorder    = Color(0xFFE2E8F0);
  static const kBg        = Color(0xFFEEF2FF);

  @override
  Widget build(BuildContext context) {
    final confirmed = paiement.statut == 'Confirmé';
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: confirmed
                    ? [const Color(0xFF065F46), const Color(0xFF059669)]
                    : [const Color(0xFF9A3412), const Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 20,
                left: 20,
                right: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Détail du paiement',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(confirmed ? '✅' : '⏳',
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(paiement.id,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${paiement.montant.toStringAsFixed(0)} MRU',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(paiement.statut,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildLigneDetail('Contrat', paiement.contratId),
                  _buildLigneDetail('Type', paiement.contratType),
                  _buildLigneDetail('Méthode de paiement', paiement.methode),
                  _buildLigneDetail('Date', paiement.date),
                  _buildLigneDetail('Statut', paiement.statut),
                  if (confirmed) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildActionBtn('📥', 'Attestation', () {}),
                        const SizedBox(width: 8),
                        _buildActionBtn('📧', 'Email', () {}),
                        const SizedBox(width: 8),
                        _buildActionBtn('💬', 'WhatsApp', () {}),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLigneDetail(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: kGray)),
          Text(val,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kText)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kBlueLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kBlueMid)),
            ],
          ),
        ),
      ),
    );
  }
}