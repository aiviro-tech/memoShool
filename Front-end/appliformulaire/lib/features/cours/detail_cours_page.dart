import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'formulaire_cours_page.dart';

class DetailCoursPage extends StatefulWidget {
  final CoursModel cours;
  final int ecoleId;

  const DetailCoursPage({
    super.key,
    required this.cours,
    required this.ecoleId,
  });

  @override
  State<DetailCoursPage> createState() => _DetailCoursPageState();
}

class _DetailCoursPageState extends State<DetailCoursPage> {
  late Future<Map<String, dynamic>> _detailFuture;
  final _role = SessionUtilisateur().role;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _detailFuture = ApiService.getDetailCours(widget.ecoleId, widget.cours.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: Text(widget.cours.ecue),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () async {
                // Capturer le contexte avant l'async
                final navigator = Navigator.of(context);
                await navigator.push(
                  MaterialPageRoute(
                    builder: (_) => FormulaireCoursPage(
                      ecoleId: widget.ecoleId,
                      cours: widget.cours,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() => _charger());
                }
              },
            ),
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: () async {
                // Capturer le contexte pour le dialogue
                final ctx = context;
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: const Text('Confirmer la suppression'),
                    content: Text(
                      'Supprimer le cours "${widget.cours.ecue}" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app.AppColors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  try {
                    await ApiService.supprimerCours(
                      widget.ecoleId,
                      widget.cours.id,
                    );
                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Cours supprimé'),
                          backgroundColor: app.AppColors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: app.AppColors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: app.AppColors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text('Impossible de charger le détail'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() => _charger());
                      }
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final data = snap.data?['data'] as Map<String, dynamic>? ?? {};
          final etudiants = data['classe']?['etudiants'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EnteteCours(cours: widget.cours),
                const SizedBox(height: 20),
                const _SectionTitre(titre: 'Informations'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _LigneInfo(
                        icone: Icons.calendar_today_outlined,
                        label: 'Date',
                        valeur: widget.cours.dateFormatee,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.access_time_outlined,
                        label: 'Horaire',
                        valeur: widget.cours.horaireFormate,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.location_on_outlined,
                        label: 'Salle',
                        valeur:
                            '${widget.cours.salle} (${widget.cours.salleCode})',
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.person_outline,
                        label: 'Enseignant',
                        valeur: widget.cours.enseignant,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.school_outlined,
                        label: 'Classe',
                        valeur: widget.cours.classe,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.account_tree_outlined,
                        label: 'Filiere',
                        valeur: widget.cours.filiere,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.category_outlined,
                        label: 'Semestre',
                        valeur: widget.cours.semestre,
                      ),
                      _Sep(),
                      _LigneInfo(
                        icone: Icons.star_outline,
                        label: 'Crédits',
                        valeur: '${widget.cours.ecueCredits} crédits',
                      ),
                    ],
                  ),
                ),
                if (widget.cours.notes != null &&
                    widget.cours.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitre(titre: 'Notes'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      widget.cours.notes!,
                      style: const TextStyle(
                        color: app.AppColors.textSub,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
                if (widget.cours.statut == 'annule' &&
                    widget.cours.motifAnnulation != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: app.AppColors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: app.AppColors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: app.AppColors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Motif d\'annulation',
                                style: TextStyle(
                                  color: app.AppColors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.cours.motifAnnulation!,
                                style: const TextStyle(
                                  color: app.AppColors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_role != 'etudiant' && etudiants.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const _SectionTitre(titre: 'Étudiants de la classe'),
                      const Spacer(),
                      Text(
                        '${etudiants.length} étudiant${etudiants.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: app.AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: etudiants.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value as Map<String, dynamic>;
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: app.AppColors.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  (e['full_name'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: app.AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                e['full_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                e['email'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: app.AppColors.textSub,
                                ),
                              ),
                              dense: true,
                            ),
                            if (i < etudiants.length - 1)
                              Divider(
                                height: 0.5,
                                thickness: 0.5,
                                color: Colors.grey.withValues(alpha: 0.15),
                                indent: 16,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_role == 'admin' && widget.cours.statut != 'termine') ...[
                  const SizedBox(height: 24),
                  const _SectionTitre(titre: 'Changer le statut'),
                  const SizedBox(height: 10),
                  _BoutonsStatut(
                    coursId: widget.cours.id,
                    ecoleId: widget.ecoleId,
                    statutActuel: widget.cours.statut,
                    onStatutChange: () {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnteteCours extends StatelessWidget {
  final CoursModel cours;
  const _EnteteCours({required this.cours});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: app.AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: app.AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: app.AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: app.AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cours.ecue,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: app.AppColors.textMain,
                      ),
                    ),
                    Text(
                      '${cours.ecueCode} ${cours.ecueCredits} crédits',
                      style: const TextStyle(
                        fontSize: 12,
                        color: app.AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BadgeStatutLocal(statut: cours.statut),
              const SizedBox(width: 8),
              _BadgeLocal(texte: cours.semestre, couleur: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoutonsStatut extends StatefulWidget {
  final int coursId;
  final int ecoleId;
  final String statutActuel;
  final VoidCallback onStatutChange;

  const _BoutonsStatut({
    required this.coursId,
    required this.ecoleId,
    required this.statutActuel,
    required this.onStatutChange,
  });

  @override
  State<_BoutonsStatut> createState() => _BoutonsStatutState();
}

class _BoutonsStatutState extends State<_BoutonsStatut> {
  @override
  Widget build(BuildContext context) {
    final statuts = <Map<String, dynamic>>[];

    if (widget.statutActuel == 'planifie') {
      statuts.add({
        'label': 'Confirmer',
        'statut': 'confirme',
        'couleur': app.AppColors.green,
      });
      statuts.add({
        'label': 'Annuler',
        'statut': 'annule',
        'couleur': app.AppColors.red,
      });
      statuts.add({
        'label': 'Reporter',
        'statut': 'reporte',
        'couleur': app.AppColors.orange,
      });
    } else if (widget.statutActuel == 'confirme') {
      statuts.add({
        'label': 'Terminer',
        'statut': 'termine',
        'couleur': Colors.grey,
      });
      statuts.add({
        'label': 'Annuler',
        'statut': 'annule',
        'couleur': app.AppColors.red,
      });
    } else if (widget.statutActuel == 'reporte') {
      statuts.add({
        'label': 'Replanifier',
        'statut': 'planifie',
        'couleur': app.AppColors.primary,
      });
      statuts.add({
        'label': 'Annuler',
        'statut': 'annule',
        'couleur': app.AppColors.red,
      });
    }

    if (statuts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      children: statuts.map((s) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (s['couleur'] as Color),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => _changerStatut(s['statut'] as String),
          child: Text(
            s['label'] as String,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _changerStatut(String nouveauStatut) async {
    String? motif;
    if (nouveauStatut == 'annule' || nouveauStatut == 'reporte') {
      // Capturer le contexte avant l'async
      final ctx = context;
      motif = await _demanderMotif(ctx, nouveauStatut);
      if (motif == null) return;
    }

    try {
      await ApiService.changerStatutCours(
        widget.ecoleId,
        widget.coursId,
        nouveauStatut,
        motifAnnulation: motif,
      );
      if (mounted) {
        // Capturer le contexte pour les SnackBar
        final ctx = context;
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès')),
        );
        widget.onStatutChange();
      }
    } catch (e) {
      if (mounted) {
        final ctx = context;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  Future<String?> _demanderMotif(BuildContext ctx, String statut) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          statut == 'annule' ? 'Motif d\'annulation' : 'Motif du report',
          style: const TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Expliquer la raison...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(color: app.AppColors.textSub),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  const _SectionTitre({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: app.AppColors.textMain,
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  const _LigneInfo({
    required this.icone,
    required this.label,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icone, color: app.AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: app.AppColors.textSub, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: app.AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 0.5,
    thickness: 0.5,
    color: Colors.grey.withValues(alpha: 0.15),
  );
}

class _BadgeLocal extends StatelessWidget {
  final String texte;
  final Color couleur;
  const _BadgeLocal({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 11,
          color: couleur,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeStatutLocal extends StatelessWidget {
  final String statut;
  const _BadgeStatutLocal({required this.statut});

  Color get _c {
    switch (statut) {
      case 'confirme':
        return app.AppColors.green;
      case 'annule':
        return app.AppColors.red;
      case 'reporte':
        return app.AppColors.orange;
      case 'termine':
        return Colors.grey;
      default:
        return app.AppColors.primary;
    }
  }

  String get _l {
    switch (statut) {
      case 'planifie':
        return 'Planifié';
      case 'confirme':
        return 'Confirmé';
      case 'annule':
        return 'Annulé';
      case 'reporte':
        return 'Reporté';
      case 'termine':
        return 'Terminé';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _l,
        style: TextStyle(fontSize: 11, color: _c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
