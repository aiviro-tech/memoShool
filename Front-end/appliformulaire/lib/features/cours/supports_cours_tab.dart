import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _deposerSupport() async {
    List<dynamic> coursList = [];
    try {
      final response = await ApiService.getCours(_session.ecoleId);
      coursList = response['data'] as List? ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement cours: $e'), backgroundColor: app.AppColors.red),
        );
      }
      return;
    }

    if (coursList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun cours disponible pour déposer un support'), backgroundColor: app.AppColors.orange),
        );
      }
      return;
    }

    if (!mounted) return;

    final resultat = await showDialog<_ResultatDepot>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SimpleDeposerSupportDialog(coursList: coursList),
    );

    if (resultat == null || !mounted) return;

    try {
      await ApiService.deposerSupport(
        _session.ecoleId,
        {
          'cours_id': resultat.coursId,
          'titre': resultat.titre,
          'description': resultat.description,
        },
        resultat.fichierNom,
        fichierPath: resultat.fichierPath,
        fichierBytes: resultat.fichierBytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support déposé ! En attente de validation.'), backgroundColor: app.AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _validerSupport(int supportId) async {
    try {
      await ApiService.validerSupport(_session.ecoleId, supportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support validé avec succès'), backgroundColor: app.AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

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
            hintText: 'Expliquez pourquoi ce support est rejeté...',
            filled: true,
            fillColor: app.AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motifCtrl.text.trim().isNotEmpty ? motifCtrl.text.trim() : 'Rejeté'),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
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
          const SnackBar(content: Text('Support rejeté'), backgroundColor: app.AppColors.orange),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
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
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
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
          const SnackBar(content: Text('Support supprimé'), backgroundColor: app.AppColors.green),
        );
        setState(() => _charger());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _telechargerSupport(Map<String, dynamic> support) async {
    try {
      final url = ApiService.getDownloadUrl(_session.ecoleId, support['id'] as int);
      final token = SessionUtilisateur().token;
      final uri = Uri.parse('$url?token=$token');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final response = await ApiService.dio.get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        final bytes = response.data as List<int>;
        final directory = await getTemporaryDirectory();
        final fileName = support['fichier_nom'] ?? 'support_${support['id']}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(file.path)]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier téléchargé avec succès'), backgroundColor: app.AppColors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: app.AppColors.red),
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
            if (isAdmin || isEnseignant)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 18, color: app.AppColors.textSub),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: app.AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtreStatut,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 13, color: app.AppColors.textMain),
                            items: const [
                              DropdownMenuItem(value: 'tous', child: Text('Tous les supports')),
                              DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                              DropdownMenuItem(value: 'valide', child: Text('Validés')),
                              DropdownMenuItem(value: 'rejete', child: Text('Rejetés')),
                            ],
                            onChanged: (v) => setState(() => _filtreStatut = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                            const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
                            const SizedBox(height: 12),
                            Text('Erreur: ${snap.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: () => setState(() => _charger()), child: const Text('Réessayer')),
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
                            Icon(Icons.folder_open, size: 64, color: app.AppColors.primary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text('Aucun support de cours', style: TextStyle(fontSize: 16, color: app.AppColors.textSub, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              isEnseignant ? 'Déposez votre premier support avec le bouton +'
                                  : isEtudiant ? 'Aucun support disponible pour le moment'
                                  : 'Aucun support disponible',
                              style: const TextStyle(fontSize: 13, color: app.AppColors.textSub),
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
                          onValider: isAdmin && s['statut'] == 'en_attente' ? () => _validerSupport(s['id'] as int) : null,
                          onRejeter: isAdmin && s['statut'] == 'en_attente' ? () => _rejeterSupport(s['id'] as int) : null,
                          onSupprimer: (isAdmin || (isEnseignant && s['enseignant_id'] == _session.id)) ? () => _supprimerSupport(s['id'] as int) : null,
                          onTelecharger: (s['statut'] == 'valide' || isAdmin || (isEnseignant && s['enseignant_id'] == _session.id)) ? () => _telechargerSupport(s) : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (isEnseignant)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _deposerSupport,
              backgroundColor: const Color(0xFF2E7D32),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Déposer', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}

class _ResultatDepot {
  final int coursId;
  final String titre;
  final String description;
  final String? fichierPath;
  final Uint8List? fichierBytes;
  final String fichierNom;

  const _ResultatDepot({
    required this.coursId,
    required this.titre,
    required this.description,
    this.fichierPath,
    this.fichierBytes,
    required this.fichierNom,
  });
}

class _SimpleDeposerSupportDialog extends StatefulWidget {
  final List<dynamic> coursList;

  const _SimpleDeposerSupportDialog({required this.coursList});

  @override
  State<_SimpleDeposerSupportDialog> createState() => _SimpleDeposerSupportDialogState();
}

class _SimpleDeposerSupportDialogState extends State<_SimpleDeposerSupportDialog> {
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _coursId;
  Uint8List? _fichierBytes;
  String? _fichierNom;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirFichier() async {
    try {
      //  Correction: Utiliser FilePicker.platform.pickFiles
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          _fichierBytes = file.bytes;
          _fichierNom = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  void _valider() {
    if (_coursId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un cours'), backgroundColor: app.AppColors.orange),
      );
      return;
    }
    if (_titreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un titre'), backgroundColor: app.AppColors.orange),
      );
      return;
    }
    if (_fichierBytes == null || _fichierNom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un fichier'), backgroundColor: app.AppColors.orange),
      );
      return;
    }

    Navigator.pop(
      context,
      _ResultatDepot(
        coursId: _coursId!,
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        fichierPath: null,
        fichierBytes: _fichierBytes,
        fichierNom: _fichierNom!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Déposer un support', style: TextStyle(fontSize: 17)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _coursId,
              decoration: const InputDecoration(
                labelText: 'Cours *',
                border: OutlineInputBorder(),
              ),
              items: widget.coursList.map((c) {
                final ecue = c['ecue'] as Map<String, dynamic>? ?? {};
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(
                    '${ecue['nom'] ?? 'Cours'} (${c['date_cours'] ?? ''})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _coursId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _choisirFichier,
              icon: const Icon(Icons.attach_file),
              label: Text(_fichierNom ?? 'Choisir un fichier *'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            if (_fichierNom != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: app.AppColors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _fichierNom!,
                        style: const TextStyle(fontSize: 12, color: app.AppColors.green),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _valider,
          style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.primary),
          child: const Text('Déposer'),
        ),
      ],
    );
  }
}

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
      case 'valide': return app.AppColors.green;
      case 'rejete': return app.AppColors.red;
      default: return app.AppColors.orange;
    }
  }

  String get _labelStatut {
    switch (support['statut']) {
      case 'valide': return 'Validé';
      case 'rejete': return 'Rejeté';
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
    final tailleStr = taille > 1048576 ? '${(taille / 1048576).toStringAsFixed(1)} Mo' : '${(taille / 1024).toStringAsFixed(0)} Ko';

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
                      Text(support['titre'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: app.AppColors.textMain)),
                      Text('${ecue['nom'] ?? 'Cours'} • ${support['fichier_nom'] ?? ''}', style: const TextStyle(fontSize: 12, color: app.AppColors.textSub), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
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
                child: Text(support['description'], style: const TextStyle(fontSize: 13, color: app.AppColors.textSub, height: 1.4)),
              ),
            Row(
              children: [
                if (!isEtudiant) ...[
                  const Icon(Icons.person_outline, size: 14, color: app.AppColors.textSub),
                  const SizedBox(width: 4),
                  Text(enseignant['full_name'] ?? '', style: const TextStyle(fontSize: 12, color: app.AppColors.textSub)),
                  const Spacer(),
                ],
                if (isEtudiant) const Spacer(),
                const Icon(Icons.storage, size: 14, color: app.AppColors.textSub),
                const SizedBox(width: 4),
                Text(tailleStr, style: const TextStyle(fontSize: 12, color: app.AppColors.textSub)),
              ],
            ),
            if (onTelecharger != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onTelecharger,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Télécharger'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: app.AppColors.primary,
                      side: const BorderSide(color: app.AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            if (support['statut'] == 'rejete' && support['motif_rejet'] != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: app.AppColors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: app.AppColors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: app.AppColors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(support['motif_rejet'], style: const TextStyle(fontSize: 12, color: app.AppColors.red))),
                  ],
                ),
              ),
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
                        style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRejeter,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(foregroundColor: app.AppColors.red, side: const BorderSide(color: app.AppColors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ),
            if (onSupprimer != null && support['statut'] != 'en_attente')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSupprimer,
                  icon: const Icon(Icons.delete_outline, size: 16, color: app.AppColors.red),
                  label: const Text('Supprimer', style: TextStyle(fontSize: 12, color: app.AppColors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}