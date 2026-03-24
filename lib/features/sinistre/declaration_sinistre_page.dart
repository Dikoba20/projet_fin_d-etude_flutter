// lib/features/sinistre/declaration_sinistre_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/sinistre_service.dart';

class DeclarationSinistrePage extends StatefulWidget {
  final Map<String, dynamic> contrat;
  const DeclarationSinistrePage({super.key, required this.contrat});

  @override
  State<DeclarationSinistrePage> createState() =>
      _DeclarationSinistrePageState();
}

class _DeclarationSinistrePageState
    extends State<DeclarationSinistrePage> {
  // ── Couleurs (même palette que paiement_page) ───────────────────────────
  static const kBlue       = Color(0xFF1E3A8A);
  static const kBlueMid    = Color(0xFF2563EB);
  static const kBlueLight  = Color(0xFFDBEAFE);
  static const kRed        = Color(0xFFDC2626);
  static const kRedLight   = Color(0xFFFEE2E2);
  static const kGreen      = Color(0xFF16A34A);
  static const kGreenLight = Color(0xFFDCFCE7);
  static const kOrange     = Color(0xFFEA580C);
  static const kGray       = Color(0xFF64748B);
  static const kGrayLight  = Color(0xFFF1F5F9);
  static const kText       = Color(0xFF1E293B);
  static const kBorder     = Color(0xFFE2E8F0);
  static const kBg         = Color(0xFFEEF2FF);

  // ── Controllers ─────────────────────────────────────────────────────────
  final _formKey   = GlobalKey<FormState>();
  final _descCtrl  = TextEditingController();
  final _lieuCtrl  = TextEditingController();
  final _dateCtrl  = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  double?         _latitude;
  double?         _longitude;
  bool            _geoLoading = false;
  bool            _geoObtenu  = false;
  bool            _submitting  = false;
  List<Uint8List> _photos      = [];
  List<String>    _photoNames  = [];

  final SinistreService _service = SinistreService();
  final ImagePicker     _picker  = ImagePicker();

  @override
  void dispose() {
    _descCtrl.dispose();
    _lieuCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Géolocalisation ──────────────────────────────────────────────────────
  Future<void> _obtenirPosition() async {
    setState(() => _geoLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Activez la géolocalisation sur votre appareil', kOrange);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snack('Permission de localisation refusée', kRed);
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Activez la localisation dans les paramètres', kRed);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude  = pos.latitude;
        _longitude = pos.longitude;
        _geoObtenu = true;
        _lieuCtrl.text =
            'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}';
      });
      _snack('Position obtenue avec succès !', kGreen);
    } catch (e) {
      _snack('Erreur géolocalisation: $e', kRed);
    } finally {
      setState(() => _geoLoading = false);
    }
  }

  // ── Sélection date ───────────────────────────────────────────────────────
  Future<void> _choisirDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kBlueMid),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _dateCtrl.text =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── Photos ───────────────────────────────────────────────────────────────
  Future<void> _ajouterPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photos.add(bytes);
        _photoNames.add(picked.name);
      });
    } catch (e) {
      _snack('Erreur photo: $e', kRed);
    }
  }

  void _supprimerPhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _photoNames.removeAt(index);
    });
  }

  // ── Soumission ───────────────────────────────────────────────────────────
  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateCtrl.text.isEmpty) {
      _snack('Veuillez choisir la date de l\'accident', kOrange);
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final contratId =
          int.tryParse(widget.contrat['id']?.toString() ?? '0') ?? 0;

      final res = await _service.declarerSinistre(
        token:        token,
        contratId:    contratId,
        description:  _descCtrl.text.trim(),
        dateAccident: _dateCtrl.text.trim(),
        lieuAccident: _lieuCtrl.text.trim(),
        latitude:     _latitude,
        longitude:    _longitude,
      );

      if (res['success'] == true) {
        _snack('Sinistre déclaré avec succès !', kGreen);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack(res['message'] ?? 'Erreur lors de la déclaration', kRed);
      }
    } catch (e) {
      _snack('Erreur: $e', kRed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoContrat(),
                    const SizedBox(height: 16),
                    _buildLabel('📝 Description de l\'accident'),
                    const SizedBox(height: 8),
                    _buildDescription(),
                    const SizedBox(height: 16),
                    _buildLabel('📅 Date de l\'accident'),
                    const SizedBox(height: 8),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildLabel('📍 Lieu de l\'accident'),
                    const SizedBox(height: 8),
                    _buildGeoSection(),
                    const SizedBox(height: 16),
                    _buildLabel('📸 Photos des dégâts'),
                    const SizedBox(height: 8),
                    _buildPhotosSection(),
                    const SizedBox(height: 24),
                    _buildSubmitBtn(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRed, Color(0xFFEF4444), Color(0xFFF87171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x4DDC2626),
              blurRadius: 20,
              offset: Offset(0, 4)),
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
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Déclarer un sinistre',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bandeau contrat ───────────────────────────────────────────────────────
  Widget _buildInfoContrat() {
    final numero = widget.contrat['numero_contrat'] ?? '—';
    final type   = widget.contrat['type_assurance'] == 'TOUS_RISQUES'
        ? 'Tous Risques'
        : 'Tiers';
    return Container(
      decoration: BoxDecoration(
        color: kRedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Déclaration de sinistre',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kRed,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text('Contrat $numero — $type',
                    style:
                        const TextStyle(fontSize: 12, color: kText)),
                const SizedBox(height: 2),
                const Text('Remplissez soigneusement tous les champs.',
                    style: TextStyle(fontSize: 11, color: kGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: kText, fontSize: 15));
  }

  // ── Description ───────────────────────────────────────────────────────────
  Widget _buildDescription() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F1E3A8A),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: _descCtrl,
        maxLines: 5,
        validator: (v) => (v == null || v.trim().length < 20)
            ? 'Décrivez l\'accident (min. 20 caractères)'
            : null,
        decoration: const InputDecoration(
          hintText:
              'Décrivez les circonstances de l\'accident, les dommages subis...',
          hintStyle: TextStyle(color: kGray, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── Date ──────────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _choisirDate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F1E3A8A),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: kBlueMid, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dateCtrl.text.isEmpty
                    ? 'Choisir la date de l\'accident'
                    : _dateCtrl.text,
                style: TextStyle(
                  color: _dateCtrl.text.isEmpty ? kGray : kText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: kGray, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Géolocalisation ───────────────────────────────────────────────────────
  Widget _buildGeoSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _geoLoading ? null : _obtenirPosition,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _geoObtenu
                    ? [kGreen, const Color(0xFF22C55E)]
                    : [kBlueMid, const Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:
                      (_geoObtenu ? kGreen : kBlueMid).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_geoLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else
                  Icon(
                    _geoObtenu
                        ? Icons.location_on
                        : Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  _geoLoading
                      ? 'Localisation en cours...'
                      : _geoObtenu
                          ? '✓ Position obtenue'
                          : 'Obtenir ma position GPS',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        if (_geoObtenu) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: kGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(6)}  |  Lon: ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: kGreen,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F1E3A8A),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: TextFormField(
            controller: _lieuCtrl,
            decoration: const InputDecoration(
              hintText: 'Ou saisissez l\'adresse manuellement...',
              hintStyle: TextStyle(color: kGray, fontSize: 13),
              prefixIcon: Icon(Icons.place, color: kGray, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Photos ────────────────────────────────────────────────────────────────
  Widget _buildPhotosSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPhotoBtn(
                icon: Icons.camera_alt,
                label: 'Caméra',
                onTap: () => _ajouterPhoto(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPhotoBtn(
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => _ajouterPhoto(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, i) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                      image: DecorationImage(
                        image: MemoryImage(_photos[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _supprimerPhoto(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: kRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${_photos.length} photo(s) sélectionnée(s)',
              style: const TextStyle(fontSize: 12, color: kGray)),
        ],
      ],
    );
  }

  Widget _buildPhotoBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F1E3A8A),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: kBlueMid, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kText)),
          ],
        ),
      ),
    );
  }

  // ── Bouton soumettre ──────────────────────────────────────────────────────
  Widget _buildSubmitBtn() {
    return GestureDetector(
      onTap: _submitting ? null : _soumettre,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [kRed, Color(0xFFEF4444)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4DDC2626),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  '⚠️  Déclarer le sinistre',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3),
                ),
        ),
      ),
    );
  }
}