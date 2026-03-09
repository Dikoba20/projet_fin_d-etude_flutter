import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/souscription_service.dart';

class SouscriptionPage extends StatefulWidget {
  const SouscriptionPage({super.key});
  @override
  State<SouscriptionPage> createState() => _SouscriptionPageState();
}

class _SouscriptionPageState extends State<SouscriptionPage> {
  final _service = SouscriptionService();
  final _picker  = ImagePicker();

  int  _etape     = 0;
  bool _isLoading = false;

  // ── Étape 0 : Type ───────────────────────────────────
  String _typeAssurance = 'TOUS_RISQUES';
  int    _dureeMois     = 12;

  // ── Étape 1 : Véhicule ───────────────────────────────
  final _marqueCtrl  = TextEditingController();
  final _modeleCtrl  = TextEditingController();
  final _anneeCtrl   = TextEditingController();
  final _immatCtrl   = TextEditingController();
  final _chassisCtrl = TextEditingController();
  final _valeurCtrl  = TextEditingController();
  String _energie    = 'ESSENCE';

  // ── Étape 2 : Documents ──────────────────────────────
  XFile? _carteGrise;
  XFile? _permis;
  XFile? _photoVehicule;

  Uint8List? _carteGriseBytes;
  Uint8List? _permisBytes;
  Uint8List? _photoVehiculeBytes;

  // ── Résultats backend ────────────────────────────────
  String? _vehiculeId;
  double? _prime;

  // ── Étape 4 : Signature ──────────────────────────────
  final List<List<Offset?>> _strokesList = [];
  List<Offset?> _currentStroke          = [];
  bool _signatureConfirmee               = false;

  // ── Résultat final ───────────────────────────────────
  String? _numeroContrat;
  String? _contratId;
  String? _qrCodeData;
  String? _pdfUrl;

  @override
  void dispose() {
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _immatCtrl.dispose();
    _chassisCtrl.dispose();
    _valeurCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // SIGNATURE : exporter en PNG (web + mobile)
  // ══════════════════════════════════════════════════════
  Future<Uint8List?> _exportSignatureBytes() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas   = Canvas(recorder, const Rect.fromLTWH(0, 0, 320, 180));
      canvas.drawRect(const Rect.fromLTWH(0, 0, 320, 180),
          Paint()..color = Colors.white);
      final paint = Paint()
        ..color       = const Color(0xFF1A56DB)
        ..strokeWidth = 3
        ..strokeCap   = StrokeCap.round
        ..style       = PaintingStyle.stroke;
      for (final stroke in _strokesList) {
        for (int i = 0; i < stroke.length - 1; i++) {
          if (stroke[i] != null && stroke[i + 1] != null) {
            canvas.drawLine(stroke[i]!, stroke[i + 1]!, paint);
          }
        }
      }
      final picture = recorder.endRecording();
      final img     = await picture.toImage(320, 180);
      final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return bytes.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════
  // PICKER IMAGE — compatible web + mobile
  // ══════════════════════════════════════════════════════
  void _showPickerSheet(Function(XFile, Uint8List) onPicked) {
    if (kIsWeb) {
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 80)
          .then((xfile) async {
        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          onPicked(xfile, bytes);
        }
      });
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1A56DB)),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final xfile = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (xfile != null) {
                  final bytes = await xfile.readAsBytes();
                  onPicked(xfile, bytes);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1A56DB)),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final xfile = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (xfile != null) {
                  final bytes = await xfile.readAsBytes();
                  onPicked(xfile, bytes);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ACTIONS BACKEND
  // ══════════════════════════════════════════════════════

  Future<void> _soumettreVehicule() async {
    final annee = int.tryParse(_anneeCtrl.text.trim());
    if (_marqueCtrl.text.isEmpty || _modeleCtrl.text.isEmpty ||
        _anneeCtrl.text.isEmpty  || _immatCtrl.text.isEmpty  ||
        _chassisCtrl.text.isEmpty) {
      _showError('Remplissez tous les champs obligatoires (*).');
      return;
    }
    if (annee == null || annee < 1990 || annee > DateTime.now().year) {
      _showError('Année invalide (entre 1990 et ${DateTime.now().year}).');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _service.creerVehicule(
        marque:             _marqueCtrl.text.trim(),
        modele:             _modeleCtrl.text.trim(),
        annee:              annee,
        immatriculation:    _immatCtrl.text.trim().toUpperCase(),
        numeroChassis:      _chassisCtrl.text.trim().toUpperCase(),
        energie:            _energie,
        valeurVenale:       double.tryParse(_valeurCtrl.text.trim()),
        carteGriseBytes:    _carteGriseBytes,
        carteGriseNom:      _carteGrise?.name,
        photoVehiculeBytes: _photoVehiculeBytes,
        photoVehiculeNom:   _photoVehicule?.name,
      );
      if (res['success'] == true) {
        _vehiculeId = res['vehicule']['id'].toString();
        setState(() => _etape = 2);
      } else {
        _showError(res['message'] ?? 'Erreur ajout véhicule.');
      }
    } catch (_) {
      _showError('Erreur de connexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploaderDocumentsEtCalculer() async {
    if (_permis == null) {
      _showError('Le permis de conduire est obligatoire.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final resPermis = await _service.uploadPermis(
        permisBytes: _permisBytes!,
        permisNom:   _permis!.name,
        vehiculeId:  _vehiculeId!,
      );
      if (resPermis['success'] != true) {
        _showError(resPermis['message'] ?? 'Erreur upload permis.');
        return;
      }
      final resPrime = await _service.calculerPrime(
        typeAssurance: _typeAssurance,
        vehiculeId:    _vehiculeId!,
        dureeMois:     _dureeMois,
      );
      if (resPrime['success'] == true) {
        _prime = double.tryParse(resPrime['prime_montant'].toString());
        setState(() => _etape = 3);
      } else {
        _showError(resPrime['message'] ?? 'Erreur calcul prime.');
      }
    } catch (_) {
      _showError('Erreur de connexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finaliserContrat() async {
    if (_strokesList.isEmpty) {
      _showError('Veuillez signer le contrat.');
      return;
    }
    if (!_signatureConfirmee) {
      _showError('Veuillez confirmer les conditions générales.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sigBytes = await _exportSignatureBytes();
      if (sigBytes == null) {
        _showError('Erreur lors de l\'export de la signature.');
        return;
      }
      final res = await _service.creerContrat(
        vehiculeId:     _vehiculeId!,
        typeAssurance:  _typeAssurance,
        dureeMois:      _dureeMois,
        primeMontant:   _prime!,
        signatureBytes: sigBytes,
      );
      if (res['success'] == true) {
        _numeroContrat = res['contrat']['numero_contrat'];
        _contratId     = res['contrat']['id'].toString();
        final resAttest = await _service.getAttestation(_contratId!);
        if (resAttest['success'] == true) {
          _qrCodeData = resAttest['qr_code_data'];
          _pdfUrl     = resAttest['pdf_url'];
        }
        setState(() => _etape = 5);
      } else {
        _showError(res['message'] ?? 'Erreur création contrat.');
      }
    } catch (_) {
      _showError('Erreur de connexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouvelle souscription',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: _etape > 0 && _etape < 5
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _etape--),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          if (_etape < 5) _buildProgressBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
                : _buildEtape(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final labels = ['Type', 'Véhicule', 'Documents', 'Prime', 'Signature'];
    return Container(
      color: const Color(0xFF1A56DB),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (i) {
              final done   = i < _etape;
              final active = i == _etape;
              return Expanded(
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: done || active ? Colors.white : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded, color: Color(0xFF1A56DB), size: 16)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: active ? const Color(0xFF1A56DB) : Colors.white54)),
                    ),
                  ),
                  if (i < 4)
                    Expanded(child: Container(height: 2,
                        color: done ? Colors.white : Colors.white24)),
                ]),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) => Text(labels[i],
                style: TextStyle(
                    fontSize: 10,
                    color: i <= _etape ? Colors.white : Colors.white38,
                    fontWeight: i == _etape ? FontWeight.w700 : FontWeight.normal))),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case 0: return _buildEtapeType();
      case 1: return _buildEtapeVehicule();
      case 2: return _buildEtapeDocuments();
      case 3: return _buildEtapePrime();
      case 4: return _buildEtapeSignature();
      case 5: return _buildSucces();
      default: return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 0 : TYPE D'ASSURANCE
  // ══════════════════════════════════════════════════════
  Widget _buildEtapeType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type d\'assurance',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
          const SizedBox(height: 6),
          const Text('Choisissez la couverture adaptée à votre véhicule',
              style: TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
          const SizedBox(height: 24),
          _buildTypeCard(value: 'TOUS_RISQUES', icon: Icons.security_rounded,
              title: 'Tous Risques',
              desc: 'Couverture maximale : accidents, vol, incendie, bris de glace.',
              color: const Color(0xFF1A56DB), recommended: true),
          const SizedBox(height: 14),
          _buildTypeCard(value: 'TIERS', icon: Icons.shield_outlined,
              title: 'Responsabilité Civile',
              desc: 'Couverture obligatoire : dommages causés aux tiers uniquement.',
              color: const Color(0xFF22C55E)),
          const SizedBox(height: 28),
          const Text('Durée du contrat',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1535A8))),
          const SizedBox(height: 12),
          Row(children: [
            _buildDureeCard(6, '6 mois'),
            const SizedBox(width: 12),
            _buildDureeCard(12, '12 mois'),
          ]),
          const SizedBox(height: 32),
          _buildBouton('Continuer', () => setState(() => _etape = 1)),
        ],
      ),
    );
  }

  Widget _buildTypeCard({required String value, required IconData icon,
      required String title, required String desc, required Color color, bool recommended = false}) {
    final sel = _typeAssurance == value;
    return GestureDetector(
      onTap: () => setState(() => _typeAssurance = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sel ? color : const Color(0xFFE0E8F5), width: sel ? 2.5 : 1.2),
          boxShadow: [BoxShadow(
              color: sel ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                  color: sel ? color : const Color(0xFF1A1A2E))),
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF1A56DB),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Recommandé',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF8492A6), height: 1.4)),
          ])),
          if (sel) Icon(Icons.check_circle_rounded, color: color, size: 22),
        ]),
      ),
    );
  }

  Widget _buildDureeCard(int mois, String label) {
    final sel = _dureeMois == mois;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dureeMois = mois),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A56DB) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0), width: 1.5),
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                  color: sel ? Colors.white : const Color(0xFF4A5568)))),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 1 : VÉHICULE
  // ══════════════════════════════════════════════════════
  Widget _buildEtapeVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Informations du véhicule',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 24),
        _field(_marqueCtrl, 'Marque *', Icons.directions_car_rounded),
        const SizedBox(height: 12),
        _field(_modeleCtrl, 'Modèle *', Icons.car_repair_rounded),
        const SizedBox(height: 12),
        _field(_anneeCtrl, 'Année *', Icons.calendar_today_outlined,
            type: TextInputType.number, max: 4),
        const SizedBox(height: 12),
        _field(_immatCtrl, 'N° Immatriculation *', Icons.pin_rounded),
        const SizedBox(height: 12),
        _field(_chassisCtrl, 'N° Châssis *', Icons.confirmation_number_outlined),
        const SizedBox(height: 12),
        _field(_valeurCtrl, 'Valeur vénale en MRU', Icons.monetization_on_outlined,
            type: TextInputType.number),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _energie, isExpanded: true,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              items: ['ESSENCE','DIESEL','ELECTRIQUE','HYBRIDE','AUTRE']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _energie = v!),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Photos (optionnel)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1535A8))),
        const SizedBox(height: 12),
        Row(children: [
          _uploadBox('Carte grise', _carteGriseBytes,
              () => _showPickerSheet((xfile, bytes) => setState(() {
                    _carteGrise = xfile; _carteGriseBytes = bytes;
                  }))),
          const SizedBox(width: 12),
          _uploadBox('Photo véhicule', _photoVehiculeBytes,
              () => _showPickerSheet((xfile, bytes) => setState(() {
                    _photoVehicule = xfile; _photoVehiculeBytes = bytes;
                  }))),
        ]),
        const SizedBox(height: 32),
        _buildBouton('Continuer', _soumettreVehicule),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 2 : DOCUMENTS
  // ══════════════════════════════════════════════════════
  Widget _buildEtapeDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Documents requis',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 6),
        const Text('Uploadez vos documents pour valider la souscription.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
        const SizedBox(height: 28),
        _docCard('Permis de conduire *', 'Obligatoire',
            Icons.credit_card_rounded, _permis,
            () => _showPickerSheet((xfile, bytes) => setState(() {
                  _permis = xfile; _permisBytes = bytes;
                })), required: true),
        const SizedBox(height: 14),
        _docCard('Carte grise', 'Si non uploadée à l\'étape précédente',
            Icons.article_outlined, _carteGrise,
            () => _showPickerSheet((xfile, bytes) => setState(() {
                  _carteGrise = xfile; _carteGriseBytes = bytes;
                }))),
        const SizedBox(height: 14),
        _docCard('Photo du véhicule', 'Vue de face recommandée',
            Icons.directions_car_rounded, _photoVehicule,
            () => _showPickerSheet((xfile, bytes) => setState(() {
                  _photoVehicule = xfile; _photoVehiculeBytes = bytes;
                }))),
        const SizedBox(height: 32),
        _buildBouton('Calculer la prime', _uploaderDocumentsEtCalculer),
      ]),
    );
  }

  Widget _docCard(String titre, String sous, IconData icon, XFile? file,
      VoidCallback onTap, {bool required = false}) {
    final ok = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: ok ? const Color(0xFF22C55E) : const Color(0xFFD0DCF0),
              width: ok ? 2 : 1.2),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: ok ? const Color(0xFF22C55E).withOpacity(0.1)
                      : const Color(0xFF1A56DB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(ok ? Icons.check_rounded : icon,
                  color: ok ? const Color(0xFF22C55E) : const Color(0xFF1A56DB), size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text(ok ? 'Document uploadé ✓' : sous,
                style: TextStyle(fontSize: 12,
                    color: ok ? const Color(0xFF22C55E) : const Color(0xFF8492A6))),
          ])),
          Icon(ok ? Icons.edit_outlined : Icons.upload_rounded,
              color: const Color(0xFFADBDD8), size: 20),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 3 : PRIME CALCULÉE
  // ══════════════════════════════════════════════════════
  Widget _buildEtapePrime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Votre prime d\'assurance',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1535A8), Color(0xFF1A56DB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            const Icon(Icons.shield_rounded, color: Colors.white70, size: 44),
            const SizedBox(height: 12),
            Text(_typeAssurance == 'TOUS_RISQUES' ? 'Tous Risques' : 'Responsabilité Civile',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text('${_prime?.toStringAsFixed(2) ?? '—'} MRU',
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
            Text('Pour $_dureeMois mois',
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 24),
        _infoRow('Type', _typeAssurance == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers'),
        _infoRow('Durée', '$_dureeMois mois'),
        _infoRow('Véhicule', '${_marqueCtrl.text} ${_modeleCtrl.text} (${_anneeCtrl.text})'),
        _infoRow('Immatriculation', _immatCtrl.text.toUpperCase()),
        const SizedBox(height: 32),
        _buildBouton('Accepter et signer', () => setState(() => _etape = 4)),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 4 : SIGNATURE — compatible WEB + MOBILE ✅
  // ══════════════════════════════════════════════════════
  Widget _buildEtapeSignature() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Signature électronique',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 6),
        Text(
          kIsWeb
              ? 'Signez avec votre souris dans la zone ci-dessous.'
              : 'Signez avec votre doigt dans la zone ci-dessous.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8492A6)),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _strokesList.isNotEmpty
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFF1A56DB).withOpacity(0.4),
              width: 2.5,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Fond blanc explicite
                  Container(color: Colors.white),
                  // Zone de dessin — Listener capture souris ET doigt
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) {
                      setState(() {
                        _currentStroke = [e.localPosition];
                        _strokesList.add(_currentStroke);
                      });
                    },
                    onPointerMove: (e) {
                      setState(() => _currentStroke.add(e.localPosition));
                    },
                    onPointerUp: (_) {
                      setState(() => _currentStroke.add(null));
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_strokesList),
                      size: const Size(double.infinity, 220),
                    ),
                  ),
                  // Placeholder visible si vide
                  if (_strokesList.isEmpty)
                    IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw_rounded,
                                color: const Color(0xFF1A56DB).withOpacity(0.25), size: 48),
                            const SizedBox(height: 8),
                            Text(
                              kIsWeb ? 'Cliquez et glissez pour signer' : 'Signez ici avec votre doigt',
                              style: TextStyle(
                                  color: const Color(0xFF1A56DB).withOpacity(0.4),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_strokesList.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _strokesList.clear()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _signatureConfirmee = !_signatureConfirmee),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: _signatureConfirmee ? const Color(0xFF1A56DB) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _signatureConfirmee ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0),
                    width: 2),
              ),
              child: _signatureConfirmee
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Je confirme avoir lu et accepté les conditions générales d\'assurance AssurAncy.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        _buildBouton('Finaliser le contrat', _finaliserContrat),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // ÉTAPE 5 : SUCCÈS + QR CODE
  // ══════════════════════════════════════════════════════
  Widget _buildSucces() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 72),
        ),
        const SizedBox(height: 20),
        const Text('Contrat créé avec succès !',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
        const SizedBox(height: 6),
        Text(_numeroContrat ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: Color(0xFF1A56DB))),
        const SizedBox(height: 28),
        if (_qrCodeData != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                    blurRadius: 16, offset: const Offset(0, 4))]),
            child: Column(children: [
              const Text('QR Code de l\'attestation',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                      color: Color(0xFF1535A8))),
              const SizedBox(height: 14),
              QrImageView(
                data: _qrCodeData!, version: QrVersions.auto, size: 180,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1535A8)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A56DB)),
              ),
              const SizedBox(height: 10),
              const Text('Présentez ce QR Code aux autorités\npour vérification immédiate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF8492A6))),
            ]),
          ),
          const SizedBox(height: 20),
        ],
        if (_pdfUrl != null)
          _buildBouton('📄 Télécharger l\'attestation PDF', () {}),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share_rounded),
          label: const Text('Partager l\'attestation'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A56DB),
            side: const BorderSide(color: Color(0xFF1A56DB)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
              'L\'attestation PDF finale sera générée après confirmation du paiement.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour au dashboard',
              style: TextStyle(color: Color(0xFF8492A6))),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ══════════════════════════════════════════════════════

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, int? max}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextField(
        controller: ctrl, keyboardType: type, maxLength: max,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFADBDD8), size: 21),
          border: InputBorder.none, counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _uploadBox(String label, Uint8List? bytes, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: bytes != null ? const Color(0xFF22C55E) : const Color(0xFFD0DCF0),
                  width: bytes != null ? 2 : 1.2)),
          child: bytes != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.memory(bytes, fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.upload_rounded, color: Color(0xFFADBDD8), size: 24),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFADBDD8))),
                ]),
        ),
      ),
    );
  }

  Widget _buildBouton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: Center(child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// PAINTER : signature
// ══════════════════════════════════════════════════════
class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = const Color(0xFF1A56DB)
      ..strokeWidth = 3.0
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != null && stroke[i + 1] != null) {
          canvas.drawLine(stroke[i]!, stroke[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
