import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportsCoursTab extends StatefulWidget {
  const SupportsCoursTab({super.key});

  @override
  State<SupportsCoursTab> createState() => _SupportsCoursTabState();
}

class _SupportsCoursTabState extends State<SupportsCoursTab> {
  final _session = SessionUtilisateur();
  late Future<List<dynamic>> _supportsFuture;
  String _filtreStatut = 'tous';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _supportsFuture = _fetchSupports();
  }

  Future<List<dynamic>> _fetchSupports() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) return [];
    final response = await ApiService.getSupports(ecoleId);
    return response['data'] as List? ?? [];
  }

  List<dynamic> _filtrer(List<dynamic> supports) {
    if (_filtreStatut == 'tous') return supports;
    return supports.where((s) => s['statut'] == _filtreStatut).toList();
  }

  // ── Enseignant dépose un support ──
  Future<void> _deposerSupport() async {
    // D'abord charger la liste des cours de l'enseignant
    List<dynamic> coursList = [];
    try {
      final response = await ApiService.getCours(_session.ecoleId);
      coursList = response['data'] as List? ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement cours: $e'), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    if (coursList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun cours disponible pour deposer un support'), backgroundColor: AppColors.orange),
        );
      }
      return;
    }

    if (!mounted) return;

    // Dialog de dépôt
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? coursId;
    String? fichierPath;
    String? fichierNom;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Deposer un support de cours', style: TextStyle(fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du cours
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Cours *',
                    prefixIcon: const Icon(Icons.menu_book, size: 18),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: coursList.map((c) {
                    final ecue = c['ecue'] ?? {};
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text('${ecue['nom'] ?? ''} - ${c['date_cours'] ?? ''}',
                        style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => coursId = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Titre du support *',
                    prefixIcon: const Icon(Icons.title, size: 18),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: const Icon(Icons.description, size: 18),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton fichier
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'jpg', 'png', 'zip'],
                    );
                    if (picked != null && picked.files.isNotEmpty) {
                      setDialogState(() {
                        fichierPath = picked.files.single.path;
                        fichierNom = picked.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(fichierNom ?? 'Choisir un fichier *'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (fichierNom != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(fichierNom!, style: const TextStyle(fontSize: 12, color: AppColors.green)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Deposer'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    if (coursId == null || titreCtrl.text.isEmpty || fichierPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires'), backgroundColor: AppColors.orange),
      );
      return;
    }

    try {
      await ApiService.deposerSupport(
        _session.ecoleId,
        {'cours_id': coursId, 'titre': titreCtrl.text.trim(), 'description': descCtrl.text.trim()},
        fichierPath!,
        fichierNom!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support depose ! En attente de validation par l\'administration.'), backgroundColor: AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  // ── Admin valide un support ──
  Future<void> _validerSupport(int supportId) async {
    try {
      await ApiService.validerSupport(_session.ecoleId, supportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support valide avec succes'), backgroundColor: AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  // ── Admin rejette un support ──
  Future<void> _rejeterSupport(int supportId) async {
    final motifCtrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: motifCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Expliquez pourquoi ce support est rejete...',
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motifCtrl.text.trim().isNotEmpty ? motifCtrl.text.trim() : 'Rejete par l\'administrateur'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (motif == null || !mounted) return;
    try {
      await ApiService.rejeterSupport(_session.ecoleId, supportId, motif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support rejete'), backgroundColor: AppColors.orange),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _supprimerSupport(int supportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce support ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.supprimerSupport(_session.ecoleId, supportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support supprime'), backgroundColor: AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  // ── Télécharger un support ──
  Future<void> _telechargerSupport(Map<String, dynamic> support) async {
    try {
      final url = ApiService.getDownloadUrl(_session.ecoleId, support['id'] as int);
      final token = SessionUtilisateur().token;
      final uri = Uri.parse('$url?token=$token');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le lien de telechargement'), backgroundColor: AppColors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.estAdmin;
    final isEnseignant = _session.estEnseignant;
    final isEtudiant = _session.estEtudiant;

    return Stack(
      children: [
        Column(
          children: [
            // ── Filtres (admin et enseignant seulement) ──
            if (isAdmin || isEnseignant)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 18, color: AppColors.textSub),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtreStatut,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                            items: const [
                              DropdownMenuItem(value: 'tous', child: Text('Tous les supports')),
                              DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                              DropdownMenuItem(value: 'valide', child: Text('Valides')),
                              DropdownMenuItem(value: 'rejete', child: Text('Rejetes')),
                            ],
                            onChanged: (v) => setState(() => _filtreStatut = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Liste ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() => _charger()),
                child: FutureBuilder<List<dynamic>>(
                  future: _supportsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                            const SizedBox(height: 12),
                            Text('Erreur: ${snap.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: () => setState(() => _charger()), child: const Text('Reessayer')),
                          ],
                        ),
                      );
                    }

                    final supports = _filtrer(snap.data ?? []);
                    if (supports.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text('Aucun support de cours',
                              style: TextStyle(fontSize: 16, color: AppColors.textSub, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              isEnseignant
                                ? 'Deposez votre premier support avec le bouton +'
                                : isEtudiant
                                  ? 'Aucun support disponible pour le moment'
                                  : 'Aucun support disponible',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: supports.length,
                      itemBuilder: (context, i) {
                        final s = supports[i] as Map<String, dynamic>;
                        return _CarteSupport(
                          support: s,
                          isAdmin: isAdmin,
                          isEnseignant: isEnseignant,
                          isEtudiant: isEtudiant,
                          onValider: isAdmin && s['statut'] == 'en_attente'
                            ? () => _validerSupport(s['id'] as int) : null,
                          onRejeter: isAdmin && s['statut'] == 'en_attente'
                            ? () => _rejeterSupport(s['id'] as int) : null,
                          onSupprimer: (isAdmin || (isEnseignant && s['enseignant_id'] == _session.id))
                            ? () => _supprimerSupport(s['id'] as int) : null,
                          onTelecharger: (s['statut'] == 'valide' || isAdmin || (isEnseignant && s['enseignant_id'] == _session.id))
                            ? () => _telechargerSupport(s) : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // ── FAB Enseignant seulement ──
        if (isEnseignant)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _deposerSupport,
              backgroundColor: const Color(0xFF2E7D32),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Deposer', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// CARTE SUPPORT
// ═══════════════════════════════════════════
class _CarteSupport extends StatelessWidget {
  final Map<String, dynamic> support;
  final bool isAdmin;
  final bool isEnseignant;
  final bool isEtudiant;
  final VoidCallback? onValider;
  final VoidCallback? onRejeter;
  final VoidCallback? onSupprimer;
  final VoidCallback? onTelecharger;

  const _CarteSupport({
    required this.support,
    required this.isAdmin,
    required this.isEnseignant,
    required this.isEtudiant,
    this.onValider,
    this.onRejeter,
    this.onSupprimer,
    this.onTelecharger,
  });

  Color get _couleurStatut {
    switch (support['statut']) {
      case 'valide': return AppColors.green;
      case 'rejete': return AppColors.red;
      default: return AppColors.orange;
    }
  }

  String get _labelStatut {
    switch (support['statut']) {
      case 'valide': return 'Valide';
      case 'rejete': return 'Rejete';
      default: return 'En attente';
    }
  }

  IconData get _iconeType {
    final type = (support['fichier_type'] ?? '').toString().toLowerCase();
    if (type == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(type)) return Icons.description;
    if (['ppt', 'pptx'].contains(type)) return Icons.slideshow;
    if (['xls', 'xlsx'].contains(type)) return Icons.table_chart;
    if (['jpg', 'jpeg', 'png'].contains(type)) return Icons.image;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final cours = support['cours'] as Map<String, dynamic>? ?? {};
    final ecue = cours['ecue'] as Map<String, dynamic>? ?? {};
    final enseignant = support['enseignant'] as Map<String, dynamic>? ?? {};
    final taille = support['fichier_taille'] ?? 0;
    final tailleStr = taille > 1048576
      ? '${(taille / 1048576).toStringAsFixed(1)} Mo'
      : '${(taille / 1024).toStringAsFixed(0)} Ko';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: _couleurStatut, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _couleurStatut.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconeType, color: _couleurStatut, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(support['titre'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                      Text('${ecue['nom'] ?? 'Cours'} • ${support['fichier_nom'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSub), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Badge statut (visible pour admin et enseignant)
                if (!isEtudiant)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _couleurStatut.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_labelStatut, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _couleurStatut)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (support['description'] != null && (support['description'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(support['description'], style: const TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.4)),
              ),
            Row(
              children: [
                if (!isEtudiant) ...[
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSub),
                  const SizedBox(width: 4),
                  Text(enseignant['full_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                  const Spacer(),
                ],
                if (isEtudiant)
                  const Spacer(),
                const Icon(Icons.storage, size: 14, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(tailleStr, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
              ],
            ),
            // Bouton télécharger (pour tout le monde quand le support est validé)
            if (onTelecharger != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onTelecharger,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Telecharger'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            // Motif de rejet
            if (support['statut'] == 'rejete' && support['motif_rejet'] != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(support['motif_rejet'], style: const TextStyle(fontSize: 12, color: AppColors.red))),
                  ],
                ),
              ),
            // Boutons admin (valider/rejeter)
            if (isAdmin && support['statut'] == 'en_attente')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onValider,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRejeter,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ),
            // Bouton supprimer (admin ou enseignant propriétaire)
            if (onSupprimer != null && support['statut'] != 'en_attente')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSupprimer,
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                  label: const Text('Supprimer', style: TextStyle(fontSize: 12, color: AppColors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
