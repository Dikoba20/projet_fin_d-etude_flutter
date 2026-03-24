import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class AdminExportPage extends StatefulWidget {
  final String token;
  const AdminExportPage({super.key, required this.token});

  @override
  State<AdminExportPage> createState() => _AdminExportPageState();
}

class _AdminExportPageState extends State<AdminExportPage> {
  // Garde en mémoire quel export est en cours de téléchargement
  String? _loading;
  String? _erreur;

  // ── Télécharge le CSV et le propose au téléchargement ──
  Future<void> _exporter(String typeExport) async {
    setState(() {
      _loading = typeExport;
      _erreur = null;
    });

    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/admin/export/$typeExport/',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        // Sur Flutter Web : déclenche le téléchargement via un lien blob
        _telechargerCsv(
          contenu: response.bodyBytes,
          nomFichier: '$typeExport.csv',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export $typeExport téléchargé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _erreur = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _erreur = 'Erreur réseau : $e';
      });
    } finally {
      setState(() => _loading = null);
    }
  }

  // ── Téléchargement du fichier CSV ──────────────────────
  // Fonctionne sur Flutter Web — sur mobile, ajoutez "share_plus" ou "open_file"
  void _telechargerCsv({
    required List<int> contenu,
    required String nomFichier,
  }) {
    debugPrint('CSV prêt : $nomFichier (${contenu.length} octets)');
    // Flutter Web : le navigateur reçoit déjà le fichier via le header
    // Content-Disposition: attachment du serveur Django — pas besoin de code supplémentaire.
    // Sur Android/iOS : installez "share_plus" et faites :
    //   final dir = await getTemporaryDirectory();
    //   final file = File('${dir.path}/$nomFichier');
    //   await file.writeAsBytes(contenu);
    //   await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          'Export',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Message d'erreur ──────────────────────────
            if (_erreur != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _erreur!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

            // ── Grille des cartes export ──────────────────
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _CarteExport(
                    titre: 'Utilisateurs',
                    description: 'Clients, agents et experts',
                    icone: Icons.people_alt_rounded,
                    couleurIcone: const Color(0xFF1535A8),
                    fondIcone: const Color(0xFFEEF2FF),
                    enChargement: _loading == 'utilisateurs',
                    onTap: () => _exporter('utilisateurs'),
                  ),
                  _CarteExport(
                    titre: 'Contrats',
                    description: 'Tous les contrats',
                    icone: Icons.description_rounded,
                    couleurIcone: const Color(0xFF7C3AED),
                    fondIcone: const Color(0xFFF5F3FF),
                    enChargement: _loading == 'contrats',
                    onTap: () => _exporter('contrats'),
                  ),
                  _CarteExport(
                    titre: 'Sinistres',
                    description: 'Déclarations et traitements',
                    icone: Icons.car_crash_rounded,
                    couleurIcone: const Color(0xFFEA580C),
                    fondIcone: const Color(0xFFFFF7ED),
                    enChargement: _loading == 'sinistres',
                    onTap: () => _exporter('sinistres'),
                  ),
                  _CarteExport(
                    titre: 'Véhicules',
                    description: 'Parc automobile assuré',
                    icone: Icons.directions_car_rounded,
                    couleurIcone: const Color(0xFF7C3AED),
                    fondIcone: const Color(0xFFF5F3FF),
                    enChargement: _loading == 'vehicules',
                    onTap: () => _exporter('vehicules'),
                  ),
                ],
              ),
            ),

            // ── Note d'information ────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cliquez sur une carte pour télécharger le fichier CSV directement. Il s\'ouvrira dans Excel.',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Widget carte export
// ══════════════════════════════════════════════════════
class _CarteExport extends StatelessWidget {
  final String titre;
  final String description;
  final IconData icone;
  final Color couleurIcone;
  final Color fondIcone;
  final bool enChargement;
  final VoidCallback onTap;

  const _CarteExport({
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleurIcone,
    required this.fondIcone,
    required this.enChargement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enChargement ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne icone + bouton download ────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: fondIcone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: couleurIcone, size: 26),
                ),
                enChargement
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: couleurIcone,
                        ),
                      )
                    : Icon(
                        Icons.download_rounded,
                        color: couleurIcone,
                        size: 22,
                      ),
              ],
            ),
            const Spacer(),
            // ── Titre ────────────────────────────────────
            Text(
              titre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // ── Description ──────────────────────────────
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}