import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  String _typeAssurance = 'TOUS_RISQUES';
  int    _dureeMois     = 12;

  final _marqueCtrl    = TextEditingController();
  final _modeleCtrl    = TextEditingController();
  final _typeCtrl      = TextEditingController();
  final _anneeCtrl     = TextEditingController();
  final _immatCtrl     = TextEditingController();
  final _chassisCtrl   = TextEditingController();
  final _puissanceCtrl = TextEditingController();
  final _placesCtrl    = TextEditingController();
  final _couleurCtrl   = TextEditingController();
  String _energie = 'DIESEL';
  String _genre   = 'VP';

  XFile?     _carteGrise;
  XFile?     _permis;
  XFile?     _photoVehicule;
  Uint8List? _carteGriseBytes;
  Uint8List? _permisBytes;
  Uint8List? _photoVehiculeBytes;

  String? _vehiculeId;
  double? _prime;

  final List<List<Offset?>> _strokes = [];
  List<Offset?> _cur                 = [];
  bool _sigConfirmee                 = false;

  String? _numeroContrat;
  String? _contratId;
  String? _qrCodeData;
  String? _pdfUrl;

  @override
  void dispose() {
    for (final c in [
      _marqueCtrl, _modeleCtrl, _typeCtrl, _anneeCtrl,
      _immatCtrl, _chassisCtrl, _puissanceCtrl, _placesCtrl, _couleurCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ══════════════════════════════════════════════════
  // PICKER — FIX DEFINITIF avec Completer
  // L'utilisateur choisit la SOURCE dans le bottom sheet,
  // puis on lance le picker APRES fermeture complète.
  // ══════════════════════════════════════════════════
  Future<XFile?> _pick() async {
    if (kIsWeb) {
      return _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    }

    final completer = Completer<ImageSource?>();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1A56DB)),
            title: const Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(ctx);
              completer.complete(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1A56DB)),
            title: const Text('Choisir depuis la galerie'),
            onTap: () {
              Navigator.pop(ctx);
              completer.complete(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );

    // Si l'utilisateur ferme sans choisir
    if (!completer.isCompleted) completer.complete(null);

    final source = await completer.future;
    if (source == null) return null;

    // Lance le picker APRES fermeture complète du bottom sheet
    try {
      return await _picker.pickImage(source: source, imageQuality: 88);
    } catch (e) {
      _snack('Erreur accès caméra/galerie.');
      return null;
    }
  }

  Future<void> _pickCarteGrise() async {
    final f = await _pick();
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() { _carteGrise = f; _carteGriseBytes = bytes; });
    _snack('✅ Carte grise ajoutée !', green: true);
  }

  Future<void> _pickPhotoVehicule() async {
    final f = await _pick();
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() { _photoVehicule = f; _photoVehiculeBytes = bytes; });
    _snack('✅ Photo du véhicule ajoutée !', green: true);
  }

  Future<void> _pickPermis() async {
    final f = await _pick();
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() { _permis = f; _permisBytes = bytes; });
    _snack('✅ Permis ajouté !', green: true);
  }

  // ══════════════════════════════════════════════════
  // BACKEND
  // ══════════════════════════════════════════════════
  Future<void> _soumettreVehicule() async {
    final annee = int.tryParse(_anneeCtrl.text.trim());
    if ([_marqueCtrl, _modeleCtrl, _anneeCtrl, _immatCtrl, _chassisCtrl,
         _puissanceCtrl, _placesCtrl].any((c) => c.text.isEmpty)) {
      _snack('Remplissez tous les champs obligatoires (*).'); return;
    }
    if (annee == null || annee < 1990 || annee > DateTime.now().year) {
      _snack('Année invalide.'); return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _service.creerVehicule(
        marque: _marqueCtrl.text.trim(), modele: _modeleCtrl.text.trim(),
        annee: annee, immatriculation: _immatCtrl.text.trim().toUpperCase(),
        numeroChassis: _chassisCtrl.text.trim().toUpperCase(), energie: _energie, genre: _genre,
        type: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
        puissanceCv: int.tryParse(_puissanceCtrl.text.trim()),
        nombrePlaces: int.tryParse(_placesCtrl.text.trim()),
        couleur: _couleurCtrl.text.trim().isEmpty ? null : _couleurCtrl.text.trim(),
        carteGriseBytes: _carteGriseBytes, carteGriseNom: _carteGrise?.name,
        photoVehiculeBytes: _photoVehiculeBytes, photoVehiculeNom: _photoVehicule?.name,
      );
      if (res['success'] == true) {
        _vehiculeId = res['vehicule']['id'].toString();
        setState(() => _etape = 2);
      } else { _snack(res['message'] ?? 'Erreur ajout véhicule.'); }
    } catch (_) { _snack('Erreur de connexion.'); }
    finally { setState(() => _isLoading = false); }
  }

  Future<void> _calculerPrime() async {
    if (_permis == null) { _snack('Le permis de conduire est obligatoire.'); return; }
    setState(() => _isLoading = true);
    try {
      final rp = await _service.uploadPermis(
        permisBytes: _permisBytes!, permisNom: _permis!.name, vehiculeId: _vehiculeId!);
      if (rp['success'] != true) { _snack(rp['message'] ?? 'Erreur upload permis.'); return; }
      final rPrime = await _service.calculerPrime(
        typeAssurance: _typeAssurance, vehiculeId: _vehiculeId!, dureeMois: _dureeMois);
      if (rPrime['success'] == true) {
        _prime = double.tryParse(rPrime['prime_montant'].toString());
        setState(() => _etape = 3);
      } else { _snack(rPrime['message'] ?? 'Erreur calcul prime.'); }
    } catch (_) { _snack('Erreur de connexion.'); }
    finally { setState(() => _isLoading = false); }
  }

  Future<void> _finaliserContrat() async {
    if (_strokes.isEmpty) { _snack('Veuillez signer le contrat.'); return; }
    if (!_sigConfirmee)   { _snack('Veuillez confirmer les conditions générales.'); return; }
    setState(() => _isLoading = true);
    try {
      final sig = await _exportSig();
      if (sig == null) { _snack('Erreur export signature.'); return; }
      final res = await _service.creerContrat(vehiculeId: _vehiculeId!, typeAssurance: _typeAssurance,
          dureeMois: _dureeMois, primeMontant: _prime!, signatureBytes: sig);
      if (res['success'] == true) {
        _numeroContrat = res['contrat']['numero_contrat'];
        _contratId     = res['contrat']['id'].toString();
        final ra = await _service.getAttestation(_contratId!);
        if (ra['success'] == true) { _qrCodeData = ra['qr_code_data']; _pdfUrl = ra['pdf_url']; }
        setState(() => _etape = 5);
      } else { _snack(res['message'] ?? 'Erreur création contrat.'); }
    } catch (_) { _snack('Erreur de connexion.'); }
    finally { setState(() => _isLoading = false); }
  }

  Future<Uint8List?> _exportSig() async {
    try {
      final rec = ui.PictureRecorder();
      final c   = Canvas(rec, const Rect.fromLTWH(0, 0, 320, 180));
      c.drawRect(const Rect.fromLTWH(0, 0, 320, 180), Paint()..color = Colors.white);
      final p = Paint()..color = const Color(0xFF1A56DB)..strokeWidth = 3
          ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
      for (final s in _strokes)
        for (int i = 0; i < s.length - 1; i++)
          if (s[i] != null && s[i + 1] != null) c.drawLine(s[i]!, s[i + 1]!, p);
      final img = await rec.endRecording().toImage(320, 180);
      final bd  = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (_) { return null; }
  }

  void _snack(String msg, {bool green = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: green ? const Color(0xFF22C55E) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F4FF),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1A56DB), foregroundColor: Colors.white, elevation: 0,
      title: const Text('Nouvelle souscription', style: TextStyle(fontWeight: FontWeight.w700)),
      leading: _etape > 0 && _etape < 5
          ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _etape--))
          : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
    ),
    body: Column(children: [
      if (_etape < 5) _progressBar(),
      Expanded(child: _isLoading ? _loading() : _etapeWidget()),
    ]),
  );

  Widget _loading() => const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)));

  Widget _progressBar() {
    final labels = ['Type', 'Véhicule', 'Documents', 'Prime', 'Signature'];
    return Container(color: const Color(0xFF1A56DB), padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(children: [
        Row(children: List.generate(5, (i) {
          final done = i < _etape; final active = i == _etape;
          return Expanded(child: Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: done || active ? Colors.white : Colors.white24, shape: BoxShape.circle),
              child: Center(child: done
                  ? const Icon(Icons.check_rounded, color: Color(0xFF1A56DB), size: 16)
                  : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? const Color(0xFF1A56DB) : Colors.white54)))),
            if (i < 4) Expanded(child: Container(height: 2, color: done ? Colors.white : Colors.white24)),
          ]));
        })),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) => Text(labels[i], style: TextStyle(fontSize: 10,
              color: i <= _etape ? Colors.white : Colors.white38,
              fontWeight: i == _etape ? FontWeight.w700 : FontWeight.normal)))),
      ]),
    );
  }

  Widget _etapeWidget() {
    switch (_etape) {
      case 0: return _etape0();
      case 1: return _etape1();
      case 2: return _etape2();
      case 3: return _etape3();
      case 4: return _etape4();
      case 5: return _etape5();
      default: return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 0 : TYPE
  // ══════════════════════════════════════════════════
  Widget _etape0() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Type d\'assurance',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 6),
      const Text('Choisissez la couverture adaptée à votre véhicule',
          style: TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
      const SizedBox(height: 24),
      _typeCard('TOUS_RISQUES', Icons.security_rounded, 'Tous Risques',
          'Couverture maximale : accidents, vol, incendie, bris de glace.',
          const Color(0xFF1A56DB), true),
      const SizedBox(height: 14),
      _typeCard('TIERS', Icons.shield_outlined, 'Responsabilité Civile',
          'Couverture obligatoire : dommages causés aux tiers uniquement.',
          const Color(0xFF22C55E), false),
      const SizedBox(height: 28),
      const Text('Durée du contrat',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1535A8))),
      const SizedBox(height: 12),
      Row(children: [
        _dureeCard(3, '3 mois'), const SizedBox(width: 12),
        _dureeCard(6, '6 mois'), const SizedBox(width: 12),
        _dureeCard(12, '12 mois'),
      ]),
      const SizedBox(height: 32),
      _btn('Continuer', () => setState(() => _etape = 1)),
    ]),
  );

  Widget _typeCard(String val, IconData icon, String title, String desc, Color color, bool rec) {
    final sel = _typeAssurance == val;
    return GestureDetector(onTap: () => setState(() => _typeAssurance = val),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sel ? color : const Color(0xFFE0E8F5), width: sel ? 2.5 : 1.2),
          boxShadow: [BoxShadow(color: sel ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                  color: sel ? color : const Color(0xFF1A1A2E))),
              if (rec) ...[const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF1A56DB), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Recommandé', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
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

  Widget _dureeCard(int mois, String label) {
    final sel = _dureeMois == mois;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _dureeMois = mois),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1A56DB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0), width: 1.5)),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
            color: sel ? Colors.white : const Color(0xFF4A5568)))),
      ),
    ));
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 1 : VÉHICULE
  // ══════════════════════════════════════════════════
  Widget _etape1() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informations du véhicule',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 6),
      const Text('Remplissez les informations de votre véhicule',
          style: TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
      const SizedBox(height: 20),
      _uploadZone('Carte grise (recto + verso)', _carteGriseBytes, _pickCarteGrise,
          icon: Icons.credit_card_rounded, couleur: const Color(0xFF1A56DB)),
      const SizedBox(height: 16),
      _field(_marqueCtrl,    'Marque *',                       Icons.directions_car_rounded),
      const SizedBox(height: 12),
      _field(_modeleCtrl,    'Modèle *',                       Icons.car_repair_rounded),
      const SizedBox(height: 12),
      _field(_typeCtrl,      'Type (ex: Santafe, Corolla...)', Icons.info_outline_rounded),
      const SizedBox(height: 12),
      _field(_anneeCtrl,     'Année de fabrication *',         Icons.calendar_today_outlined,
          type: TextInputType.number, max: 4),
      const SizedBox(height: 12),
      _field(_immatCtrl,     'N° Immatriculation *',           Icons.pin_rounded),
      const SizedBox(height: 12),
      _field(_chassisCtrl,   'N° Châssis (VIN) *',            Icons.confirmation_number_outlined),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field(_puissanceCtrl, 'Puissance (CV) *', Icons.speed_rounded, type: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _field(_placesCtrl, 'Nb. places *', Icons.people_rounded, type: TextInputType.number)),
      ]),
      const SizedBox(height: 12),
      _field(_couleurCtrl, 'Couleur', Icons.color_lens_outlined),
      const SizedBox(height: 12),
      _drop<String>(value: _genre, label: 'Genre du véhicule', icon: Icons.category_outlined,
        items: const {'VP': 'VP — Véhicule Personnel', 'SW': 'SW — Station Wagon',
          'TC': 'TC — Transport en commun', 'TM': 'TM — Transport marchandise', 'MOTO': 'Moto'},
        onChanged: (v) => setState(() => _genre = v!)),
      const SizedBox(height: 12),
      _drop<String>(value: _energie, label: 'Type d\'énergie', icon: Icons.local_gas_station_outlined,
        items: const {'ESSENCE': 'Essence', 'DIESEL': 'Diesel (Gasoil)',
          'ELECTRIQUE': 'Électrique', 'HYBRIDE': 'Hybride', 'AUTRE': 'Autre'},
        onChanged: (v) => setState(() => _energie = v!)),
      const SizedBox(height: 20),
      _uploadZone('Photo du véhicule', _photoVehiculeBytes, _pickPhotoVehicule,
          icon: Icons.directions_car_rounded, couleur: const Color(0xFF8492A6)),
      const SizedBox(height: 32),
      _btn('Continuer', _soumettreVehicule),
    ]),
  );

  Widget _uploadZone(String label, Uint8List? bytes, VoidCallback onTap,
      {required IconData icon, required Color couleur}) {
    final hasFile = bytes != null;
    return GestureDetector(onTap: onTap,
      child: Container(width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasFile ? const Color(0xFF22C55E) : couleur.withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: hasFile
            ? Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(14),
                  child: Image.memory(bytes, width: double.infinity, height: 160, fit: BoxFit.cover)),
                Positioned(top: 10, right: 10,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 14), SizedBox(width: 4),
                      Text('Ajouté ✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]))),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
                    child: const Row(children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 14), SizedBox(width: 6),
                      Text('Appuyer pour changer', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ]))),
              ])
            : Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: couleur.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: couleur, size: 32)),
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                const Text('JPG ou PNG uniquement', style: TextStyle(fontSize: 11, color: Color(0xFF8492A6))),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1A56DB), borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.upload_rounded, color: Colors.white, size: 16), SizedBox(width: 6),
                    Text('Choisir un fichier', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ])),
              ])),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 2 : DOCUMENTS
  // ══════════════════════════════════════════════════
  Widget _etape2() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Documents requis',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 6),
      const Text('Uploadez vos documents pour valider la souscription.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
      const SizedBox(height: 28),
      _docCard('Permis de conduire *', 'Obligatoire — JPG ou PNG',
          Icons.credit_card_rounded, _permis, _pickPermis),
      const SizedBox(height: 14),
      _docCard('Carte grise', 'Déjà uploadée à l\'étape précédente',
          Icons.article_outlined, _carteGrise, _pickCarteGrise),
      const SizedBox(height: 32),
      _btn('Calculer la prime', _calculerPrime),
    ]),
  );

  Widget _docCard(String titre, String sous, IconData icon, XFile? file, VoidCallback onTap) {
    final ok = file != null;
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ok ? const Color(0xFF22C55E) : const Color(0xFFD0DCF0), width: ok ? 2 : 1.2)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ok ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFF1A56DB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(ok ? Icons.check_rounded : icon,
                color: ok ? const Color(0xFF22C55E) : const Color(0xFF1A56DB), size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text(ok ? 'Document ajouté ✓' : sous,
              style: TextStyle(fontSize: 12, color: ok ? const Color(0xFF22C55E) : const Color(0xFF8492A6))),
          ])),
          Icon(ok ? Icons.edit_outlined : Icons.upload_rounded, color: const Color(0xFFADBDD8), size: 20),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 3 : PRIME
  // ══════════════════════════════════════════════════
  Widget _etape3() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Votre prime d\'assurance',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 24),
      Container(width: double.infinity, padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1535A8), Color(0xFF1A56DB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(children: [
          const Icon(Icons.shield_rounded, color: Colors.white70, size: 44),
          const SizedBox(height: 12),
          Text(_typeAssurance == 'TOUS_RISQUES' ? 'Tous Risques' : 'Responsabilité Civile',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${_prime?.toStringAsFixed(2) ?? "—"} MRU',
              style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
          Text('Pour $_dureeMois mois', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 24),
      _row('Type',              _typeAssurance == 'TOUS_RISQUES' ? 'Tous Risques' : 'Tiers'),
      _row('Durée',             '$_dureeMois mois'),
      _row('Véhicule',          '${_marqueCtrl.text} ${_modeleCtrl.text} (${_anneeCtrl.text})'),
      _row('Immatriculation',   _immatCtrl.text.toUpperCase()),
      _row('Puissance fiscale', '${_puissanceCtrl.text} CV'),
      _row('Nombre de places',  _placesCtrl.text),
      const SizedBox(height: 32),
      _btn('Accepter et signer', () => setState(() => _etape = 4)),
    ]),
  );

  Widget _row(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    ]),
  );

  // ══════════════════════════════════════════════════
  // ÉTAPE 4 : SIGNATURE
  // ══════════════════════════════════════════════════
  Widget _etape4() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Signature électronique',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 6),
      Text(kIsWeb ? 'Signez avec votre souris.' : 'Signez avec votre doigt.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8492A6))),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _strokes.isNotEmpty ? const Color(0xFF1A56DB) : const Color(0xFF1A56DB).withOpacity(0.4),
              width: 2.5)),
        child: ClipRRect(borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: 220, child: Stack(children: [
            Container(color: Colors.white),
            Listener(behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => setState(() { _cur = [e.localPosition]; _strokes.add(_cur); }),
              onPointerMove: (e) => setState(() => _cur.add(e.localPosition)),
              onPointerUp:   (_) => setState(() => _cur.add(null)),
              child: CustomPaint(painter: _SigPainter(_strokes), size: const Size(double.infinity, 220))),
            if (_strokes.isEmpty) IgnorePointer(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_rounded, color: const Color(0xFF1A56DB).withOpacity(0.25), size: 48),
                const SizedBox(height: 8),
                Text(kIsWeb ? 'Cliquez et glissez pour signer' : 'Signez ici avec votre doigt',
                    style: TextStyle(color: const Color(0xFF1A56DB).withOpacity(0.4), fontSize: 14)),
              ]))),
          ]))),
      ),
      const SizedBox(height: 10),
      if (_strokes.isNotEmpty) Align(alignment: Alignment.centerRight,
        child: TextButton.icon(onPressed: () => setState(() => _strokes.clear()),
          icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Effacer'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)))),
      const SizedBox(height: 16),
      GestureDetector(onTap: () => setState(() => _sigConfirmee = !_sigConfirmee),
        child: Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 200), width: 24, height: 24,
            decoration: BoxDecoration(
              color: _sigConfirmee ? const Color(0xFF1A56DB) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _sigConfirmee ? const Color(0xFF1A56DB) : const Color(0xFFD0DCF0), width: 2)),
            child: _sigConfirmee ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null),
          const SizedBox(width: 12),
          const Expanded(child: Text(
            'Je confirme avoir lu et accepté les conditions générales d\'assurance AssurAncy.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4A5568)))),
        ]),
      ),
      const SizedBox(height: 32),
      _btn('Finaliser le contrat', _finaliserContrat),
    ]),
  );

  // ══════════════════════════════════════════════════
  // ÉTAPE 5 : SUCCÈS
  // ══════════════════════════════════════════════════
  Widget _etape5() => SingleChildScrollView(
    padding: const EdgeInsets.all(24), physics: const BouncingScrollPhysics(),
    child: Column(children: [
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 72)),
      const SizedBox(height: 20),
      const Text('Contrat créé avec succès !',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1535A8))),
      const SizedBox(height: 6),
      Text(_numeroContrat ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A56DB))),
      const SizedBox(height: 28),
      if (_qrCodeData != null) ...[
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Column(children: [
            const Text('QR Code de l\'attestation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1535A8))),
            const SizedBox(height: 14),
            QrImageView(data: _qrCodeData!, version: QrVersions.auto, size: 180,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1535A8)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A56DB))),
            const SizedBox(height: 10),
            const Text('Présentez ce QR Code aux autorités pour vérification.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF8492A6))),
          ])),
        const SizedBox(height: 20),
      ],
      if (_pdfUrl != null) _btn('📄 Télécharger l\'attestation PDF', () {}),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () {},
        icon: const Icon(Icons.share_rounded), label: const Text('Partager l\'attestation'),
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A56DB),
          side: const BorderSide(color: Color(0xFF1A56DB)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20), SizedBox(width: 10),
          Expanded(child: Text('L\'attestation PDF finale sera générée après confirmation du paiement.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4))),
        ])),
      const SizedBox(height: 24),
      TextButton(onPressed: () => Navigator.pop(context),
        child: const Text('Retour au dashboard', style: TextStyle(color: Color(0xFF8492A6)))),
      const SizedBox(height: 24),
    ]),
  );

  // ══════════════════════════════════════════════════
  // HELPERS UI
  // ══════════════════════════════════════════════════
  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, int? max}) =>
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(controller: ctrl, keyboardType: type, maxLength: max,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFADBDD8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFADBDD8), size: 21),
            border: InputBorder.none, counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
      );

  Widget _drop<T>({required T value, required String label, required IconData icon,
      required Map<T, String> items, required ValueChanged<T?> onChanged}) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2)),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFADBDD8), size: 21), const SizedBox(width: 12),
          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<T>(
            value: value, isExpanded: true,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: onChanged))),
        ]),
      );

  Widget _btn(String label, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, height: 54,
      decoration: BoxDecoration(color: const Color(0xFF1A56DB), borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))]),
      child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
    ),
  );
}

// ══════════════════════════════════════════════════
// PAINTER
// ══════════════════════════════════════════════════
class _SigPainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  _SigPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF1A56DB)..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes)
      for (int i = 0; i < s.length - 1; i++)
        if (s[i] != null && s[i + 1] != null) canvas.drawLine(s[i]!, s[i + 1]!, p);
  }
  @override
  bool shouldRepaint(_SigPainter old) => true;
}