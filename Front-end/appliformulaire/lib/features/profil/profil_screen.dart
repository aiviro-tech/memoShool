// lib/features/profil/profil_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/profil_service.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/profil/edit_info_screen.dart';
import 'package:appliformulaire/features/profil/change_password_screen.dart';

// ── ThemeNotifier global ──────────────────────────────────────────────────────
class ThemeNotifier {
  static final ThemeNotifier instance = ThemeNotifier._();
  ThemeNotifier._();
  final ValueNotifier<bool> isDark = ValueNotifier(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool('theme_sombre') ?? false;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL PROFIL
// ═════════════════════════════════════════════════════════════════════════════
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _session = SessionUtilisateur();
  bool _uploadEnCours = false;

  static const Color _bleu = Color(0xFF3D5AF1);

  @override
  void initState() {
    super.initState();
    ThemeNotifier.instance.isDark.addListener(_onThemeChanged);
    ThemeNotifier.instance.init(); // ← charge le thème sauvegardé après connexion
  }

  @override
  void dispose() {
    ThemeNotifier.instance.isDark.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  String get _roleLabel {
    switch (_session.role) {
      case 'admin':       return 'Administrateur';
      case 'super_admin': return 'Super Admin';
      case 'enseignant':  return 'Enseignant';
      case 'etudiant':    return 'Étudiant';
      default:            return _session.role;
    }
  }

  String get _initiale {
    final p = _session.prenom;
    return p.isNotEmpty ? p[0].toUpperCase() : '?';
  }

  // ── Menu photo ─────────────────────────────────────────────────────────────
  void _afficherMenuPhoto() {
    final hasPhoto = _session.photoProfil.isNotEmpty;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Photo de profil',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _bleu.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined,
                      color: _bleu, size: 20),
                ),
                title: Text(hasPhoto ? 'Modifier la photo' : 'Ajouter une photo',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Choisir depuis la galerie',
                    style: TextStyle(fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                onTap: () { Navigator.pop(ctx); _choisirDepuisGalerie(); },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.green, size: 20),
                ),
                title: const Text('Prendre une photo',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text("Utiliser l'appareil photo",
                    style: TextStyle(fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                onTap: () { Navigator.pop(ctx); _choisirDepuisCamera(); },
              ),
              if (hasPhoto) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                  ),
                  title: const Text('Supprimer la photo',
                      style: TextStyle(fontWeight: FontWeight.w500,
                          color: Colors.red)),
                  subtitle: Text('Retirer votre photo de profil',
                      style: TextStyle(fontSize: 12,
                          color: Colors.red.withValues(alpha: 0.7))),
                  onTap: () { Navigator.pop(ctx); _confirmerSuppression(); },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choisirDepuisGalerie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    await _uploadImage(picked);
  }

  Future<void> _choisirDepuisCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    await _uploadImage(picked);
  }

  Future<void> _uploadImage(XFile picked) async {
    setState(() => _uploadEnCours = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ProfilService.uploadPhoto(fichierBytes: bytes, fileName: picked.name);
      } else {
        await ProfilService.uploadPhoto(fichier: File(picked.path), fileName: picked.name);
      }
      if (mounted) { setState(() {}); _snackOk('Photo de profil mise à jour !'); }
    } catch (e) {
      if (mounted) _snackErr(e.toString());
    } finally {
      if (mounted) setState(() => _uploadEnCours = false);
    }
  }

  Future<void> _confirmerSuppression() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Voulez-vous vraiment supprimer votre photo de profil ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _uploadEnCours = true);
    try {
      await ProfilService.deletePhoto();
      if (mounted) { setState(() {}); _snackOk('Photo supprimée.'); }
    } catch (e) {
      if (mounted) _snackErr(e.toString());
    } finally {
      if (mounted) setState(() => _uploadEnCours = false);
    }
  }

  // ── Déconnexion ────────────────────────────────────────────────────────────
  Future<void> _seDeconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // ← Réinitialiser le thème au mode clair avant de déconnecter
    ThemeNotifier.instance.isDark.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_sombre', false);

    SessionUtilisateur().vider();
    try { await ApiService.logout(); } catch (_) {}
    finally {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  void _snackOk(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _snackErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceAll('Exception: ', '')),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    final url = _session.photoProfil;
    return GestureDetector(
      onTap: _uploadEnCours ? null : _afficherMenuPhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: ClipOval(
              child: _uploadEnCours
                  ? const Center(child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : url.isNotEmpty
                      ? Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initiales())
                      : _initiales(),
            ),
          ),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: _bleu, width: 1.5),
            ),
            child: const Icon(Icons.camera_alt, size: 15, color: _bleu),
          ),
        ],
      ),
    );
  }

  Widget _initiales() => Container(
    color: Colors.white.withValues(alpha: 0.2),
    child: Center(child: Text(_initiale,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
            color: Colors.white))),
  );

  // ── Item de menu ───────────────────────────────────────────────────────────
  Widget _item({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
    bool danger = false,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: iconBg,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(titre, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: danger ? Colors.red : cs.onSurface)),
        subtitle: Text(sousTitre, style: TextStyle(
            fontSize: 12,
            color: danger
                ? Colors.red.withValues(alpha: 0.7)
                : cs.onSurface.withValues(alpha: 0.5))),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: danger
                    ? Colors.red.withValues(alpha: 0.5)
                    : cs.onSurface.withValues(alpha: 0.3)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        letterSpacing: 1.0)),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDark.value;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 28, left: 20, right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D3A) : _bleu,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const Text('Mon Profil', style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildAvatar(),
                const SizedBox(height: 14),
                Text('${_session.prenom} ${_session.nom}'.trim(),
                    style: const TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_session.email, style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_roleLabel, style: const TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Corps ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('PARAMÈTRES'),
                  _item(
                    icon: Icons.person_outline,
                    iconBg: _bleu.withValues(alpha: 0.12),
                    iconColor: _bleu,
                    titre: 'Informations personnelles',
                    sousTitre: 'Modifier nom, prénom et téléphone',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const EditInfoScreen()));
                      setState(() {});
                    },
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const _ThemeSwitchTile(),
                  ),

                  _item(
                    icon: Icons.lock_outline,
                    iconBg: Colors.orange.withValues(alpha: 0.12),
                    iconColor: Colors.orange,
                    titre: 'Modifier le mot de passe',
                    sousTitre: 'Changer votre mot de passe actuel',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen())),
                  ),

                  const SizedBox(height: 8),

                  _label('SUPPORT'),
                  _item(
                    icon: Icons.help_outline_rounded,
                    iconBg: const Color(0xFF1565C0).withValues(alpha: 0.12),
                    iconColor: const Color(0xFF1565C0),
                    titre: "Centre d'aide",
                    sousTitre: 'Questions fréquentes et assistance',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CentreAidePage())),
                  ),
                  _item(
                    icon: Icons.info_outline_rounded,
                    iconBg: Colors.green.withValues(alpha: 0.12),
                    iconColor: const Color(0xFF2E7D32),
                    titre: 'À propos',
                    sousTitre: 'Version, équipe et mission BenCampus',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AProposPage())),
                  ),

                  const SizedBox(height: 8),

                  _label('LÉGAL'),
                  _item(
                    icon: Icons.gavel_rounded,
                    iconBg: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                    iconColor: const Color(0xFF6A1B9A),
                    titre: "Conditions d'utilisation",
                    sousTitre: "Règles d'utilisation de la plateforme",
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ConditionsUtilisationPage())),
                  ),
                  _item(
                    icon: Icons.privacy_tip_outlined,
                    iconBg: Colors.red.withValues(alpha: 0.12),
                    iconColor: const Color(0xFFC62828),
                    titre: 'Politique de confidentialité',
                    sousTitre: 'Comment nous protégeons vos données',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const PolitiqueConfidentialitePage())),
                  ),

                  const SizedBox(height: 8),

                  _label('SESSION'),
                  _item(
                    icon: Icons.logout,
                    iconBg: Colors.red.withValues(alpha: 0.12),
                    iconColor: Colors.red,
                    titre: 'Se déconnecter',
                    sousTitre: 'Quitter votre session actuelle',
                    onTap: _seDeconnecter,
                    danger: true,
                  ),

                  const SizedBox(height: 12),
                  Center(child: Text('BenCampus v1.0.0',
                      style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.3)))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SWITCH THÈME
// ═════════════════════════════════════════════════════════════════════════════
class _ThemeSwitchTile extends StatefulWidget {
  const _ThemeSwitchTile();
  @override
  State<_ThemeSwitchTile> createState() => _ThemeSwitchTileState();
}

class _ThemeSwitchTileState extends State<_ThemeSwitchTile> {
  bool get _isDark => ThemeNotifier.instance.isDark.value;

  @override
  void initState() {
    super.initState();
    ThemeNotifier.instance.isDark.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeNotifier.instance.isDark.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

  Future<void> _toggle(bool val) async {
    ThemeNotifier.instance.isDark.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_sombre', val);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _isDark ? Icons.dark_mode : Icons.light_mode,
          color: Colors.deepPurple, size: 22,
        ),
      ),
      title: Text('Thème', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
      subtitle: Text(_isDark ? 'Mode sombre activé' : 'Mode clair activé',
          style: TextStyle(fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5))),
      trailing: Switch(
        value: _isDark,
        onChanged: _toggle,
        activeColor: const Color(0xFF3D5AF1),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BASE PAGE LÉGALE
// ═════════════════════════════════════════════════════════════════════════════
class _PageBase extends StatelessWidget {
  final String titre;
  final Widget body;
  final Color headerColor;

  const _PageBase({
    required this.titre,
    required this.body,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titre, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }
}

Widget _sectionTitre(String titre,
    {Color color = const Color(0xFF3D5AF1)}) =>
    Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(titre, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );

Widget _para(BuildContext context, String texte) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(texte, style: TextStyle(
      fontSize: 13.5,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
      height: 1.65)),
);

// ─── FAQ Item ─────────────────────────────────────────────────────────────────
class _FaqItem extends StatefulWidget {
  final String question, reponse;
  const _FaqItem({required this.question, required this.reponse});
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(widget.question, style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface)),
          trailing: Icon(
              _ouvert
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: const Color(0xFF3D5AF1), size: 20),
          onExpansionChanged: (v) => setState(() => _ouvert = v),
          children: [
            Text(widget.reponse, style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CENTRE D'AIDE
// ═════════════════════════════════════════════════════════════════════════════
class CentreAidePage extends StatelessWidget {
  const CentreAidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBase(
      titre: "Centre d'aide",
      headerColor: const Color(0xFF1565C0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF3D5AF1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Besoin d'aide ?", style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Trouvez rapidement une réponse à vos questions.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )),
              ],
            ),
          ),
          _sectionTitre('🔐 Connexion & Compte'),
          _FaqItem(
            question: 'Je n\'arrive pas à me connecter, que faire ?',
            reponse:
                'Vérifiez que votre email et mot de passe sont corrects. '
                'Si vous avez oublié votre mot de passe, utilisez le lien '
                '"Mot de passe oublié ?" sur la page de connexion.',
          ),
          _FaqItem(
            question: 'Comment modifier mes informations personnelles ?',
            reponse:
                'Rendez-vous dans Profil → Informations personnelles. '
                'Vous pouvez y modifier votre prénom, nom et numéro de téléphone.',
          ),
          _FaqItem(
            question: 'Comment changer mon mot de passe ?',
            reponse:
                'Allez dans Profil → Modifier le mot de passe. '
                'Saisissez votre mot de passe actuel puis votre nouveau mot de passe '
                '(minimum 8 caractères).',
          ),
          _sectionTitre('💳 Paiements & Scolarité'),
          _FaqItem(
            question: 'Comment payer ma scolarité ?',
            reponse:
                'Allez dans la section Paiements depuis le menu principal. '
                'Appuyez sur "Payer une tranche", saisissez le montant, '
                'votre numéro de téléphone et choisissez MTN MoMo ou Moov Money.',
          ),
          _FaqItem(
            question: 'Comment télécharger mon reçu de paiement ?',
            reponse:
                'Une fois votre paiement approuvé, allez dans '
                'Paiements → Historique. Appuyez sur "Générer reçu" '
                'puis "Télécharger".',
          ),
          _sectionTitre('📱 Application'),
          _FaqItem(
            question: 'Comment activer le mode sombre ?',
            reponse:
                'Allez dans Profil → Thème et activez le switch "Mode sombre". '
                'Toute l\'application bascule immédiatement en thème sombre.',
          ),
          _FaqItem(
            question: 'L\'application est lente ou ne charge pas ?',
            reponse:
                'Vérifiez votre connexion internet. '
                'Fermez et rouvrez l\'application. '
                'Si le problème persiste, déconnectez-vous puis reconnectez-vous.',
          ),
          _sectionTitre('📞 Contact'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D5AF1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF3D5AF1).withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.mail_outline, color: Color(0xFF3D5AF1), size: 18),
                  SizedBox(width: 8),
                  Text('support@bencampus.app', style: TextStyle(
                      color: Color(0xFF3D5AF1), fontWeight: FontWeight.w600,
                      fontSize: 14)),
                ]),
                SizedBox(height: 8),
                Text(
                  'Notre équipe répond dans un délai de 24h ouvrées. '
                  'Pensez à préciser votre école et votre numéro d\'étudiant.',
                  style: TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// À PROPOS
// ═════════════════════════════════════════════════════════════════════════════
class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBase(
      titre: 'À propos',
      headerColor: const Color(0xFF2E7D32),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D5AF1), Color(0xFF1565C0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF3D5AF1).withValues(alpha: 0.3),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 14),
                Text('BenCampus', style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('La plateforme académique qui te fait graduer',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                  ),
                  child: const Text('Version 1.0.0', style: TextStyle(
                      fontSize: 12, color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          _sectionTitre('Notre mission', color: const Color(0xFF2E7D32)),
          _para(context,
              'BenCampus est une plateforme académique mobile conçue pour simplifier '
              'la gestion des établissements d\'enseignement supérieur en Afrique. '
              'Notre mission est de connecter étudiants, enseignants et administrateurs '
              'au sein d\'un seul outil simple, fiable et accessible.'),
          _sectionTitre('Technologie', color: const Color(0xFF2E7D32)),
          _para(context,
              'BenCampus est développé avec Flutter pour une expérience native sur '
              'Android et iOS. Le backend repose sur une API REST sécurisée. '
              'Les paiements sont traités via FedaPay (MTN MoMo & Moov Money).'),
          _sectionTitre('Contact & Support', color: const Color(0xFF2E7D32)),
          _para(context, 'Pour toute question : support@bencampus.app'),
          _para(context, 'Site web : www.bencampus.app'),
          const SizedBox(height: 8),
          Center(child: Text('© 2025 BenCampus. Tous droits réservés.',
              style: TextStyle(fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CONDITIONS D'UTILISATION
// ═════════════════════════════════════════════════════════════════════════════
class ConditionsUtilisationPage extends StatelessWidget {
  const ConditionsUtilisationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBase(
      titre: "Conditions d'utilisation",
      headerColor: const Color(0xFF6A1B9A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF6A1B9A), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Dernière mise à jour : 1er janvier 2025',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF6A1B9A)))),
            ]),
          ),
          _sectionTitre('1. Acceptation', color: const Color(0xFF6A1B9A)),
          _para(context,
              'En accédant à BenCampus et en utilisant nos services, vous acceptez '
              'd\'être lié par les présentes conditions d\'utilisation.'),
          _sectionTitre('2. Paiements', color: const Color(0xFF6A1B9A)),
          _para(context,
              'Les paiements effectués via BenCampus sont traités par FedaPay. '
              'Toute transaction validée est définitive.'),
          _sectionTitre('3. Comportement', color: const Color(0xFF6A1B9A)),
          _para(context,
              'Vous vous engagez à fournir des informations exactes et à ne pas '
              'tenter de pirater ou altérer le fonctionnement de la plateforme.'),
          _sectionTitre('4. Droit applicable', color: const Color(0xFF6A1B9A)),
          _para(context,
              'Les présentes conditions sont régies par le droit béninois. '
              'Tout litige sera soumis à la juridiction compétente de Cotonou, Bénin.'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// POLITIQUE DE CONFIDENTIALITÉ
// ═════════════════════════════════════════════════════════════════════════════
class PolitiqueConfidentialitePage extends StatelessWidget {
  const PolitiqueConfidentialitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBase(
      titre: 'Politique de confidentialité',
      headerColor: const Color(0xFFC62828),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined,
                  color: Color(0xFFC62828), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                  'Nous prenons la protection de vos données très au sérieux.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFC62828)))),
            ]),
          ),
          _sectionTitre('1. Données collectées', color: const Color(0xFFC62828)),
          _para(context,
              'Lors de votre utilisation de BenCampus, nous collectons : '
              'informations d\'identité, coordonnées, données académiques, '
              'données de paiement et photo de profil (optionnelle).'),
          _sectionTitre('2. Protection des données', color: const Color(0xFFC62828)),
          _para(context,
              'Toutes les communications sont chiffrées via HTTPS/TLS. '
              'Vos mots de passe sont stockés sous forme hachée (bcrypt) '
              'et ne sont jamais lisibles.'),
          _sectionTitre('3. Partage des données', color: const Color(0xFFC62828)),
          _para(context,
              'Nous ne vendons jamais vos données personnelles à des tiers. '
              'Elles peuvent être partagées uniquement avec votre établissement '
              'scolaire et FedaPay pour le traitement des paiements.'),
          _sectionTitre('4. Vos droits', color: const Color(0xFFC62828)),
          _para(context,
              'Vous disposez des droits d\'accès, de rectification, d\'effacement '
              'et de portabilité de vos données. '
              'Contact : privacy@bencampus.app'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}