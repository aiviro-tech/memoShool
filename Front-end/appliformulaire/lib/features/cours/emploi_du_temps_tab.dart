import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/cours/detail_cours_page.dart';

class EmploiDuTempsTab extends StatefulWidget {
  const EmploiDuTempsTab({super.key});

  @override
  State<EmploiDuTempsTab> createState() => _EmploiDuTempsTabState();
}

class _EmploiDuTempsTabState extends State<EmploiDuTempsTab> {
  final _session = SessionUtilisateur();
  late DateTime _debutSemaine;
  late Future<Map<String, List<CoursModel>>> _emploiFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Lundi de la semaine courante
    _debutSemaine = now.subtract(Duration(days: now.weekday - 1));
    _charger();
  }

  void _charger() {
    _emploiFuture = _fetchEmploi();
  }

  Future<Map<String, List<CoursModel>>> _fetchEmploi() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) return {};

    final semaineStr = '${_debutSemaine.year}-${_debutSemaine.month.toString().padLeft(2, '0')}-${_debutSemaine.day.toString().padLeft(2, '0')}';
    final response = await ApiService.getEmploiDuTemps(ecoleId, semaine: semaineStr);

    final Map<String, List<CoursModel>> result = {};
    final emploi = response['emploi_du_temps'];

    if (emploi is Map) {
      for (final entry in emploi.entries) {
        final date = entry.key.toString();
        final coursList = entry.value as List? ?? [];
        result[date] = coursList
            .map((c) => CoursModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    }

    return result;
  }

  void _semainePrecedente() {
    setState(() {
      _debutSemaine = _debutSemaine.subtract(const Duration(days: 7));
      _charger();
    });
  }

  void _semaineSuivante() {
    setState(() {
      _debutSemaine = _debutSemaine.add(const Duration(days: 7));
      _charger();
    });
  }

  void _semaineActuelle() {
    final now = DateTime.now();
    setState(() {
      _debutSemaine = now.subtract(Duration(days: now.weekday - 1));
      _charger();
    });
  }

  String _formatDateCourte(DateTime d) {
    const mois = [
      '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${mois[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final finSemaine = _debutSemaine.add(const Duration(days: 6));

    return Column(
      children: [
        // ── Navigation semaine ──────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: _semainePrecedente,
                tooltip: 'Semaine précédente',
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _semaineActuelle,
                  child: Column(
                    children: [
                      Text(
                        '${_formatDateCourte(_debutSemaine)} — ${_formatDateCourte(finSemaine)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        '${_debutSemaine.year}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: _semaineSuivante,
                tooltip: 'Semaine suivante',
              ),
            ],
          ),
        ),

        // ── Contenu ─────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() => _charger()),
            child: FutureBuilder<Map<String, List<CoursModel>>>(
              future: _emploiFuture,
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
                        Text('Erreur: ${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSub)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _charger()),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final emploi = snap.data ?? {};

                if (emploi.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64,
                          color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun cours cette semaine',
                          style: TextStyle(fontSize: 16, color: AppColors.textSub,
                            fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Naviguez vers une autre semaine',
                          style: TextStyle(fontSize: 13, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  );
                }

                // Trier les dates
                final dates = emploi.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final date = dates[i];
                    final cours = emploi[date]!;
                    return _JourEmploi(
                      date: date,
                      cours: cours,
                      ecoleId: _session.ecoleId,
                      onRefresh: () => setState(() => _charger()),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// JOUR AVEC SES COURS
// ═══════════════════════════════════════════════
class _JourEmploi extends StatelessWidget {
  final String date;
  final List<CoursModel> cours;
  final int ecoleId;
  final VoidCallback onRefresh;

  const _JourEmploi({
    required this.date,
    required this.cours,
    required this.ecoleId,
    required this.onRefresh,
  });

  String get _jourLabel {
    try {
      final d = DateTime.parse(date);
      const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      const mois = [
        '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month]}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du jour
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                _jourLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${cours.length} cours',
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ],
          ),
        ),
        // Créneaux
        ...cours.map((c) => _CreneauCours(
          cours: c,
          ecoleId: ecoleId,
          onRefresh: onRefresh,
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// CRÉNEAU INDIVIDUEL
// ═══════════════════════════════════════════════
class _CreneauCours extends StatelessWidget {
  final CoursModel cours;
  final int ecoleId;
  final VoidCallback onRefresh;

  const _CreneauCours({
    required this.cours,
    required this.ecoleId,
    required this.onRefresh,
  });

  Color get _couleur {
    switch (cours.statut) {
      case 'confirme': return AppColors.green;
      case 'reporte': return AppColors.orange;
      case 'termine': return Colors.grey;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailCoursPage(cours: cours, ecoleId: ecoleId),
        ),
      ).then((_) => onRefresh()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _couleur.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: _couleur, width: 3),
          ),
        ),
        child: Row(
          children: [
            // Horaire
            Column(
              children: [
                Text(
                  cours.heureDebut,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _couleur,
                  ),
                ),
                Container(
                  width: 1,
                  height: 12,
                  color: _couleur.withValues(alpha: 0.3),
                ),
                Text(
                  cours.heureFin,
                  style: TextStyle(
                    fontSize: 12,
                    color: _couleur.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cours.matiere,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: AppColors.textSub),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          cours.enseignant,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSub),
                      const SizedBox(width: 3),
                      Text(cours.salle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                      const Spacer(),
                      const Icon(Icons.school_outlined, size: 13, color: AppColors.textSub),
                      const SizedBox(width: 3),
                      Text(cours.classe,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSub, size: 18),
          ],
        ),
      ),
    );
  }
}
