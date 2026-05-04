import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/cours/detail_cours_page.dart';
import 'package:appliformulaire/features/cours/formulaire_cours_page.dart';

class ListeCoursTab extends StatefulWidget {
  const ListeCoursTab({super.key});

  @override
  State<ListeCoursTab> createState() => _ListeCoursTabState();
}

class _ListeCoursTabState extends State<ListeCoursTab> {
  final _session = SessionUtilisateur();
  late Future<List<CoursModel>> _coursFuture;
  String _filtreStatut = 'tous';
  String _filtreSemestre = 'tous';

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  void _chargerCours() {
    _coursFuture = _fetchCours();
  }

  Future<List<CoursModel>> _fetchCours() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) return [];

    final response = await ApiService.getCours(ecoleId);
    final data = response['data'] as List? ?? [];
    return data.map((json) => CoursModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  List<CoursModel> _filtrer(List<CoursModel> cours) {
    return cours.where((c) {
      if (_filtreStatut != 'tous' && c.statut != _filtreStatut) return false;
      if (_filtreSemestre != 'tous' && c.semestre != _filtreSemestre) return false;
      return true;
    }).toList();
  }

  Future<void> _supprimerCours(CoursModel cours) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le cours "${cours.ecue}" du ${cours.dateFormatee} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSub)),
          ),
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
      await ApiService.supprimerCours(_session.ecoleId, cours.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours supprimé'), backgroundColor: AppColors.green),
        );
        setState(() => _chargerCours());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.estAdmin;

    return Stack(
      children: [
        Column(
          children: [
            // ── Filtres ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  // Filtre statut
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
                            DropdownMenuItem(value: 'tous', child: Text('Tous statuts')),
                            DropdownMenuItem(value: 'planifie', child: Text('Planifié')),
                            DropdownMenuItem(value: 'confirme', child: Text('Confirmé')),
                            DropdownMenuItem(value: 'reporte', child: Text('Reporté')),
                            DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                            DropdownMenuItem(value: 'termine', child: Text('Terminé')),
                          ],
                          onChanged: (v) => setState(() => _filtreStatut = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filtre semestre
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filtreSemestre,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                        items: const [
                          DropdownMenuItem(value: 'tous', child: Text('Semestre')),
                          DropdownMenuItem(value: 'S1', child: Text('S1')),
                          DropdownMenuItem(value: 'S2', child: Text('S2')),
                          DropdownMenuItem(value: 'S3', child: Text('S3')),
                          DropdownMenuItem(value: 'S4', child: Text('S4')),
                          DropdownMenuItem(value: 'S5', child: Text('S5')),
                          DropdownMenuItem(value: 'S6', child: Text('S6')),
                          DropdownMenuItem(value: 'S7', child: Text('S7')),
                          DropdownMenuItem(value: 'S8', child: Text('S8')),
                          DropdownMenuItem(value: 'S9', child: Text('S9')),
                          DropdownMenuItem(value: 'S10', child: Text('S10')),
                        ],
                        onChanged: (v) => setState(() => _filtreSemestre = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liste ───────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() => _chargerCours()),
                child: FutureBuilder<List<CoursModel>>(
                  future: _coursFuture,
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
                            Text('Erreur: ${snap.error}', textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSub)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() => _chargerCours()),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final cours = _filtrer(snap.data ?? []);
                    if (cours.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 64,
                              color: AppColors.primary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text('Aucun cours trouvé',
                              style: TextStyle(fontSize: 16, color: AppColors.textSub,
                                fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              _filtreStatut != 'tous' || _filtreSemestre != 'tous'
                                ? 'Essayez de modifier les filtres'
                                : isAdmin
                                  ? 'Créez votre premier cours avec le bouton +'
                                  : 'Aucun cours programmé pour le moment',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: cours.length,
                      itemBuilder: (context, i) => _CarteCours(
                        cours: cours[i],
                        isAdmin: isAdmin,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailCoursPage(
                              cours: cours[i],
                              ecoleId: _session.ecoleId,
                            ),
                          ),
                        ).then((_) => setState(() => _chargerCours())),
                        onDelete: isAdmin ? () => _supprimerCours(cours[i]) : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // ── FAB Admin ──────────────────────
        if (isAdmin)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormulaireCoursPage(
                    ecoleId: _session.ecoleId,
                    cours: null,
                  ),
                ),
              ).then((_) => setState(() => _chargerCours())),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau cours', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// CARTE DE COURS
// ═══════════════════════════════════════════════
class _CarteCours extends StatelessWidget {
  final CoursModel cours;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CarteCours({
    required this.cours,
    required this.isAdmin,
    required this.onTap,
    this.onDelete,
  });

  Color get _couleurStatut {
    switch (cours.statut) {
      case 'confirme': return AppColors.green;
      case 'annule': return AppColors.red;
      case 'reporte': return AppColors.orange;
      case 'termine': return Colors.grey;
      default: return AppColors.primary;
    }
  }

  String get _labelStatut {
    switch (cours.statut) {
      case 'planifie': return 'Planifié';
      case 'confirme': return 'Confirmé';
      case 'annule': return 'Annulé';
      case 'reporte': return 'Reporté';
      case 'termine': return 'Terminé';
      default: return cours.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: _couleurStatut, width: 4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours.ecue,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                        Text(
                          '${cours.ecueCode} • ${cours.ecueCredits} crédits',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _couleurStatut.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _labelStatut,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _couleurStatut,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Infos secondaires
              Row(
                children: [
                  _InfoChip(icon: Icons.person_outline, text: cours.enseignant),
                  const Spacer(),
                  _InfoChip(icon: Icons.location_on_outlined, text: cours.salle),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: cours.dateFormatee.isNotEmpty
                        ? cours.dateFormatee
                        : cours.dateCours,
                  ),
                  const Spacer(),
                  _InfoChip(icon: Icons.access_time, text: cours.horaireFormate),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(icon: Icons.school_outlined, text: cours.classe),
                  const Spacer(),
                  _InfoChip(icon: Icons.category_outlined, text: cours.semestre),
                  if (isAdmin && onDelete != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSub),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
