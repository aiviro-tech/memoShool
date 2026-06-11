import 'package:flutter/material.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/main.dart';
import 'package:intl/intl.dart';

class EmploiDuTempsTab extends StatefulWidget {
  const EmploiDuTempsTab({super.key});

  @override
  State<EmploiDuTempsTab> createState() => _EmploiDuTempsTabState();
}

class _EmploiDuTempsTabState extends State<EmploiDuTempsTab> {
  final _session = SessionUtilisateur();

  late DateTime _lundiSemaine;
  late Future<Map<String, List<CoursModel>>> _futureEmploi;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Lundi de la semaine courante (weekday : 1=lun … 7=dim)
    _lundiSemaine = now.subtract(Duration(days: now.weekday - 1));
    _charger();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  void _charger() {
    //  On envoie toujours le lundi de la semaine au format yyyy-MM-dd.
    // Le backend calcule lui-même startOfWeek / endOfWeek via Carbon,
    // donc envoyer n'importe quel jour de la semaine fonctionnerait aussi,
    // mais envoyer le lundi est plus explicite.
    final semaineStr = DateFormat('yyyy-MM-dd').format(_lundiSemaine);
    _futureEmploi = _chargerEmploi(semaineStr);
  }

  /// Appelle l'endpoint dédié emploi-du-temps et parse la réponse.
  /// Le backend filtre déjà par rôle (enseignant / étudiant / admin),
  /// pas besoin de refilter côté Flutter.
  Future<Map<String, List<CoursModel>>> _chargerEmploi(String semaine) async {
    final raw = await ApiService.getEmploiDuTemps(
      _session.ecoleId,
      semaine: semaine,
    );

    // ── Parse ──────────────────────────────────────────────────────────────
    // La réponse Laravel est :
    // {
    //   "success": true,
    //   "semaine_debut": "...",
    //   "semaine_fin": "...",
    //   "emploi_du_temps": {
    //     "2025-01-20": [ { cours... }, ... ],
    //     "2025-01-21": [ ... ],
    //   }
    // }
    final emploi = raw['emploi_du_temps'];

    // Réponse vide ou format inattendu → semaine sans cours
    if (emploi == null || emploi is! Map || emploi.isEmpty) {
      return {};
    }

    final result = <String, List<CoursModel>>{};

    emploi.forEach((date, list) {
      if (list is! List || list.isEmpty) return;
      try {
        final cours = list
            .map((e) => CoursModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Tri par heure de début (le backend le fait déjà, mais au cas où)
        cours.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
        result[date as String] = cours;
      } catch (e) {
        debugPrint('[EmploiDuTemps] Erreur parsing cours pour $date : $e');
      }
    });

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION SEMAINE
  // ══════════════════════════════════════════════════════════════════════════

  void _semainePrec() => setState(() {
    _lundiSemaine = _lundiSemaine.subtract(const Duration(days: 7));
    _charger();
  });

  void _semaineSuiv() => setState(() {
    _lundiSemaine = _lundiSemaine.add(const Duration(days: 7));
    _charger();
  });

  Future<void> _refresh() async => setState(() => _charger());

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _formatDateEntete(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      const mois = [
        'jan',
        'fév',
        'mar',
        'avr',
        'mai',
        'juin',
        'juil',
        'août',
        'sep',
        'oct',
        'nov',
        'déc',
      ];
      return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  String _labelSemaine() {
    final dimanche = _lundiSemaine.add(const Duration(days: 6));
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(_lundiSemaine)} – ${fmt.format(dimanche)}';
  }

  bool _estSemaineCourante() {
    final now = DateTime.now();
    final lundiCourant = now.subtract(Duration(days: now.weekday - 1));
    return _lundiSemaine.year == lundiCourant.year &&
        _lundiSemaine.month == lundiCourant.month &&
        _lundiSemaine.day == lundiCourant.day;
  }

  /// Calcule la durée entre heureDebut et heureFin d'un cours.
  String _formatDuree(CoursModel cours) {
    try {
      final p1 = cours.heureDebut.split(':');
      final p2 = cours.heureFin.split(':');
      final debut = Duration(
        hours: int.parse(p1[0]),
        minutes: int.parse(p1[1]),
      );
      final fin = Duration(hours: int.parse(p2[0]), minutes: int.parse(p2[1]));
      final diff = fin - debut;
      final h = diff.inHours;
      final mn = diff.inMinutes % 60;
      if (h > 0 && mn > 0) return '${h}h${mn.toString().padLeft(2, '0')}';
      if (h > 0) return '${h}h';
      return '${mn}min';
    } catch (_) {
      return '';
    }
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'planifie':
        return AppColors.primary;
      case 'en_cours':
        return Colors.blue.shade600;
      case 'confirme':
        return AppColors.green;
      case 'termine':
        return Colors.grey.shade500;
      case 'annule':
        return AppColors.red;
      case 'reporte':
        return AppColors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'planifie':
        return 'Planifié';
      case 'en_cours':
        return 'En cours';
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

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNavigationSemaine(),
        Expanded(
          child: FutureBuilder<Map<String, List<CoursModel>>>(
            future: _futureEmploi,
            builder: (context, snap) {
              // ── Chargement ─────────────────────────────────────────────────
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // ── Erreur ─────────────────────────────────────────────────────
              if (snap.hasError) {
                final msg = snap.error.toString().replaceAll('Exception: ', '');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 56,
                          color: AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snap.data ?? {};

              // ── Aucun cours cette semaine ───────────────────────────────────
              if (data.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 72,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _session.estEtudiant
                                    ? 'Aucun cours cette semaine.\n\nVérifiez que votre inscription est validée.'
                                    : _session.estEnseignant
                                    ? 'Aucun cours assigné cette semaine.'
                                    : 'Aucun cours planifié cette semaine.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // ── Liste des jours ────────────────────────────────────────────
              final dates = data.keys.toList()..sort();

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  itemCount: dates.length,
                  itemBuilder: (_, i) {
                    final date = dates[i];
                    final coursDuJour = data[date]!;
                    return _buildJour(date, coursDuJour);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNavigationSemaine() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _semainePrec,
            color: AppColors.primary,
            tooltip: 'Semaine précédente',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _labelSemaine(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                if (_estSemaineCourante()) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Semaine actuelle',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _semaineSuiv,
            color: AppColors.primary,
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }

  Widget _buildJour(String date, List<CoursModel> cours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDateEntete(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${cours.length} cours',
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ],
          ),
        ),
        ...cours.map((c) => _buildCarteCours(c)),
      ],
    );
  }

  Widget _buildCarteCours(CoursModel cours) {
    final couleur = _couleurStatut(cours.statut);
    final duree = _formatDuree(cours);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: couleur, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne 1 : ECUE + badge statut ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    cours.ecue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                //  Badge visible pour admin ET enseignant
                if (_session.estAdmin || _session.estEnseignant)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _libelleStatut(cours.statut),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: couleur,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Ligne 2 : Heure début → fin + durée ────────────────────
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    duree.isNotEmpty
                        ? '${cours.heureDebut} – ${cours.heureFin}  ($duree)'
                        : '${cours.heureDebut} – ${cours.heureFin}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Ligne 3 : Salle ─────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cours.salle.isNotEmpty ? cours.salle : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Ligne 4 : Enseignant ────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cours.enseignant.isNotEmpty ? cours.enseignant : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Ligne 5 : Classe + filière ──────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 13,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${cours.classe} • ${cours.filiere}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ── Motif annulation ────────────────────────────────────────
            if (cours.statut == 'annule' && cours.motifAnnulation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.red,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cours.motifAnnulation!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
