// lib/features/profil/edit_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/profil_service.dart';

// ── Modèle pays ───────────────────────────────────────────────────────────────
class _Pays {
  final String nom;
  final String indicatif;
  final String drapeau;
  const _Pays(this.nom, this.indicatif, this.drapeau);
}

// ── Liste complète des pays avec indicatifs ───────────────────────────────────
const List<_Pays> _listePays = [
  // ── Afrique de l'Ouest (prioritaires) ─────────────────────────────────────
  _Pays('Bénin',            '+229', '🇧🇯'),
  _Pays('Burkina Faso',     '+226', '🇧🇫'),
  _Pays('Côte d\'Ivoire',   '+225', '🇨🇮'),
  _Pays('Ghana',            '+233', '🇬🇭'),
  _Pays('Guinée',           '+224', '🇬🇳'),
  _Pays('Mali',             '+223', '🇲🇱'),
  _Pays('Niger',            '+227', '🇳🇪'),
  _Pays('Nigeria',          '+234', '🇳🇬'),
  _Pays('Sénégal',          '+221', '🇸🇳'),
  _Pays('Togo',             '+228', '🇹🇬'),
  _Pays('Guinée-Bissau',    '+245', '🇬🇼'),
  _Pays('Cap-Vert',         '+238', '🇨🇻'),
  _Pays('Gambie',           '+220', '🇬🇲'),
  _Pays('Guinée équatoriale','+240','🇬🇶'),
  _Pays('Liberia',          '+231', '🇱🇷'),
  _Pays('Mauritanie',       '+222', '🇲🇷'),
  _Pays('Sierra Leone',     '+232', '🇸🇱'),
  // ── Afrique centrale ───────────────────────────────────────────────────────
  _Pays('Cameroun',         '+237', '🇨🇲'),
  _Pays('Congo',            '+242', '🇨🇬'),
  _Pays('Congo (RDC)',      '+243', '🇨🇩'),
  _Pays('Gabon',            '+241', '🇬🇦'),
  _Pays('Centrafrique',     '+236', '🇨🇫'),
  _Pays('Tchad',            '+235', '🇹🇩'),
  _Pays('São Tomé',         '+239', '🇸🇹'),
  // ── Afrique de l'Est ───────────────────────────────────────────────────────
  _Pays('Éthiopie',         '+251', '🇪🇹'),
  _Pays('Kenya',            '+254', '🇰🇪'),
  _Pays('Tanzanie',         '+255', '🇹🇿'),
  _Pays('Ouganda',          '+256', '🇺🇬'),
  _Pays('Rwanda',           '+250', '🇷🇼'),
  _Pays('Burundi',          '+257', '🇧🇮'),
  _Pays('Djibouti',         '+253', '🇩🇯'),
  _Pays('Érythrée',         '+291', '🇪🇷'),
  _Pays('Somalie',          '+252', '🇸🇴'),
  _Pays('Soudan',           '+249', '🇸🇩'),
  _Pays('Soudan du Sud',    '+211', '🇸🇸'),
  _Pays('Mozambique',       '+258', '🇲🇿'),
  _Pays('Madagascar',       '+261', '🇲🇬'),
  _Pays('Comores',          '+269', '🇰🇲'),
  _Pays('Maurice',          '+230', '🇲🇺'),
  _Pays('Seychelles',       '+248', '🇸🇨'),
  // ── Afrique du Nord ────────────────────────────────────────────────────────
  _Pays('Algérie',          '+213', '🇩🇿'),
  _Pays('Égypte',           '+20',  '🇪🇬'),
  _Pays('Libye',            '+218', '🇱🇾'),
  _Pays('Maroc',            '+212', '🇲🇦'),
  _Pays('Tunisie',          '+216', '🇹🇳'),
  // ── Afrique du Sud ─────────────────────────────────────────────────────────
  _Pays('Afrique du Sud',   '+27',  '🇿🇦'),
  _Pays('Angola',           '+244', '🇦🇴'),
  _Pays('Botswana',         '+267', '🇧🇼'),
  _Pays('Lesotho',          '+266', '🇱🇸'),
  _Pays('Malawi',           '+265', '🇲🇼'),
  _Pays('Namibie',          '+264', '🇳🇦'),
  _Pays('Zambie',           '+260', '🇿🇲'),
  _Pays('Zimbabwe',         '+263', '🇿🇼'),
  _Pays('Eswatini',         '+268', '🇸🇿'),
  // ── Europe ─────────────────────────────────────────────────────────────────
  _Pays('France',           '+33',  '🇫🇷'),
  _Pays('Belgique',         '+32',  '🇧🇪'),
  _Pays('Suisse',           '+41',  '🇨🇭'),
  _Pays('Luxembourg',       '+352', '🇱🇺'),
  _Pays('Allemagne',        '+49',  '🇩🇪'),
  _Pays('Espagne',          '+34',  '🇪🇸'),
  _Pays('Italie',           '+39',  '🇮🇹'),
  _Pays('Portugal',         '+351', '🇵🇹'),
  _Pays('Royaume-Uni',      '+44',  '🇬🇧'),
  _Pays('Pays-Bas',         '+31',  '🇳🇱'),
  _Pays('Russie',           '+7',   '🇷🇺'),
  _Pays('Ukraine',          '+380', '🇺🇦'),
  _Pays('Turquie',          '+90',  '🇹🇷'),
  // ── Amériques ──────────────────────────────────────────────────────────────
  _Pays('États-Unis',       '+1',   '🇺🇸'),
  _Pays('Canada',           '+1',   '🇨🇦'),
  _Pays('Brésil',           '+55',  '🇧🇷'),
  _Pays('Mexique',          '+52',  '🇲🇽'),
  _Pays('Argentine',        '+54',  '🇦🇷'),
  _Pays('Haïti',            '+509', '🇭🇹'),
  _Pays('Colombie',         '+57',  '🇨🇴'),
  // ── Asie ───────────────────────────────────────────────────────────────────
  _Pays('Chine',            '+86',  '🇨🇳'),
  _Pays('Inde',             '+91',  '🇮🇳'),
  _Pays('Japon',            '+81',  '🇯🇵'),
  _Pays('Corée du Sud',     '+82',  '🇰🇷'),
  _Pays('Arabie Saoudite',  '+966', '🇸🇦'),
  _Pays('Émirats Arabes',   '+971', '🇦🇪'),
  _Pays('Liban',            '+961', '🇱🇧'),
  // ── Océanie ────────────────────────────────────────────────────────────────
  _Pays('Australie',        '+61',  '🇦🇺'),
  _Pays('Nouvelle-Zélande', '+64',  '🇳🇿'),
];

// ═════════════════════════════════════════════════════════════════════════════
// ÉCRAN MODIFIER INFORMATIONS
// ═════════════════════════════════════════════════════════════════════════════
class EditInfoScreen extends StatefulWidget {
  const EditInfoScreen({super.key});

  @override
  State<EditInfoScreen> createState() => _EditInfoScreenState();
}

class _EditInfoScreenState extends State<EditInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final session  = SessionUtilisateur();

  late TextEditingController _prenomCtrl;
  late TextEditingController _nomCtrl;
  late TextEditingController _phoneCtrl;

  bool _chargement = false;

  // Pays sélectionné — Bénin par défaut
  _Pays _paysSelectionne = _listePays.first;

  static const Color _bleuPrimaire = Color(0xFF3D5AF1);

  @override
  void initState() {
    super.initState();
    _prenomCtrl = TextEditingController(text: session.prenom);
    _nomCtrl    = TextEditingController(text: session.nom);

    // Extraire l'indicatif et le numéro du téléphone stocké
    final phoneStocke = session.phone;
    _paysSelectionne  = _trouverPays(phoneStocke);
    final numeroSans  = _extraireNumero(phoneStocke);
    _phoneCtrl = TextEditingController(text: numeroSans);
  }

  // ── Helpers indicatif ─────────────────────────────────────────────────────
  _Pays _trouverPays(String phone) {
    for (final p in _listePays) {
      if (phone.startsWith(p.indicatif)) return p;
    }
    return _listePays.first; // Bénin par défaut
  }

  String _extraireNumero(String phone) {
    for (final p in _listePays) {
      if (phone.startsWith(p.indicatif)) {
        return phone.substring(p.indicatif.length).trim();
      }
    }
    return phone;
  }

  String get _phoneComplet {
    final numero = _phoneCtrl.text.trim();
    if (numero.isEmpty) return '';
    return '${_paysSelectionne.indicatif}$numero';
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Sauvegarde ─────────────────────────────────────────────────────────────
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);
    try {
      await ProfilService.updateInfo(
        firstName: _prenomCtrl.text.trim(),
        lastName:  _nomCtrl.text.trim(),
        phone:     _phoneComplet,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Profil mis à jour avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // ── Dialog sélecteur de pays ───────────────────────────────────────────────
  Future<void> _choisirPays() async {
    final recherche = TextEditingController();
    List<_Pays> filtre = List.from(_listePays);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Poignée
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Choisir un pays',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: recherche,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un pays...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) {
                    setLocal(() {
                      filtre = _listePays
                          .where((p) =>
                              p.nom.toLowerCase().contains(v.toLowerCase()) ||
                              p.indicatif.contains(v))
                          .toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Liste des pays
              Expanded(
                child: ListView.builder(
                  itemCount: filtre.length,
                  itemBuilder: (_, i) {
                    final p = filtre[i];
                    final selected = p.indicatif == _paysSelectionne.indicatif &&
                        p.nom == _paysSelectionne.nom;
                    return ListTile(
                      leading: Text(p.drapeau,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(p.nom,
                          style: const TextStyle(fontSize: 14)),
                      trailing: Text(p.indicatif,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _bleuPrimaire)),
                      tileColor: selected
                          ? _bleuPrimaire.withValues(alpha: 0.08)
                          : null,
                      onTap: () {
                        setState(() => _paysSelectionne = p);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Champ texte générique ──────────────────────────────────────────────────
  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obligatoire = true,
    TextInputType clavier = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A6A))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: clavier,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: _bleuPrimaire, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _bleuPrimaire, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: obligatoire
              ? (v) => (v == null || v.trim().isEmpty)
                  ? 'Ce champ est requis'
                  : null
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Champ téléphone avec sélecteur de pays ─────────────────────────────────
  Widget _buildChampTelephone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Téléphone',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A6A))),
        const SizedBox(height: 8),
        Row(
          children: [
            // ── Bouton sélecteur pays ────────────────────────────────────
            GestureDetector(
              onTap: _choisirPays,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E4FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_paysSelectionne.drapeau,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(_paysSelectionne.indicatif,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _bleuPrimaire)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        color: _bleuPrimaire, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Champ numéro ─────────────────────────────────────────────
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Numéro sans indicatif',
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _bleuPrimaire, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // Optionnel
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 6 || digits.length > 15) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // Aperçu du numéro complet
        if (_phoneCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Numéro complet : $_phoneComplet',
              style: TextStyle(
                  fontSize: 12,
                  color: _bleuPrimaire.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _bleuPrimaire,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Informations personnelles',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Card formulaire
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildChamp(
                        controller: _prenomCtrl,
                        label: 'Prénom',
                        hint: 'Votre prénom',
                        icon: Icons.person_outline,
                      ),
                      _buildChamp(
                        controller: _nomCtrl,
                        label: 'Nom',
                        hint: 'Votre nom de famille',
                        icon: Icons.badge_outlined,
                      ),
                      // Champ téléphone avec indicatif
                      StatefulBuilder(
                        builder: (ctx, _) => _buildChampTelephone(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton sauvegarder
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bleuPrimaire,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _bleuPrimaire.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _chargement
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Sauvegarder',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}