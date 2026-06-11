import 'package:flutter/material.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/absence_service.dart';

class StatutExclusionModel {
  final int absencesEcue;
  final int seuilEcue;
  final int absencesSemestre;
  final int seuilSemestre;
  final double heuresSemestre;
  final double seuilHeures;
  final bool excluSession1;
  final bool excluSession1Et2;

  StatutExclusionModel({
    required this.absencesEcue,
    required this.seuilEcue,
    required this.absencesSemestre,
    required this.seuilSemestre,
    required this.heuresSemestre,
    required this.seuilHeures,
    required this.excluSession1,
    required this.excluSession1Et2,
  });

  double get pourcentageEcue => seuilEcue > 0 ? absencesEcue / seuilEcue : 0;
  double get pourcentageSemestre =>
      seuilSemestre > 0 ? absencesSemestre / seuilSemestre : 0;
  double get pourcentageHeures =>
      seuilHeures > 0 ? heuresSemestre / seuilHeures : 0;
}

class StatutExclusionScreen extends StatefulWidget {
  const StatutExclusionScreen({super.key});

  @override
  State<StatutExclusionScreen> createState() => _StatutExclusionScreenState();
}

class _StatutExclusionScreenState extends State<StatutExclusionScreen> {
  final AbsenceService _service = AbsenceService();
  final _session = SessionUtilisateur();
  StatutExclusionModel? _statut;
  bool _loading = false;

  final _ecueIdController = TextEditingController();
  final _semestreIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Statut d\'Exclusion',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vérifier votre statut',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ecueIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID de l\'ECUE',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _semestreIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID du Semestre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _loading ? null : _charger,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Vérifier',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_statut != null) ...[
                const SizedBox(height: 20),
                Expanded(child: SingleChildScrollView(child: _buildStatutResult())),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _charger() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0 || _session.id == 0) return;

    final ecueId = int.tryParse(_ecueIdController.text);
    final semestreId = int.tryParse(_semestreIdController.text);

    if (ecueId == null || semestreId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez renseigner les deux champs')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _service.getStatutExclusion(
        ecoleId,
        etudiantId: _session.id,
        ecueId: ecueId,
        semestreId: semestreId,
      );
      final data = result['data'] as Map<String, dynamic>;

      final statut = StatutExclusionModel(
        absencesEcue: data['absences_ecue'] ?? 0,
        seuilEcue: data['seuil_ecue'] ?? 0,
        absencesSemestre: data['absences_semestre'] ?? 0,
        seuilSemestre: data['seuil_semestre'] ?? 0,
        heuresSemestre: (data['heures_semestre'] ?? 0).toDouble(),
        seuilHeures: (data['seuil_heures'] ?? 0).toDouble(),
        excluSession1: data['exclu_session1'] ?? false,
        excluSession1Et2: data['exclu_session1_et_2'] ?? false,
      );

      if (mounted) {
        setState(() {
          _statut = statut;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatutResult() {
    final s = _statut!;

    return Column(
      children: [
        if (s.excluSession1Et2)
          _buildAlerte(
            'Exclusion Sessions 1 & 2',
            'Vous avez dépassé ${s.seuilHeures.toStringAsFixed(0)}h d\'absence. Vous êtes exclu(e) de TOUTES les sessions.',
            Colors.red,
            Icons.block,
          )
        else if (s.excluSession1)
          _buildAlerte(
            'Exclusion Session 1',
            'Vous avez atteint le seuil d\'absences. Vous êtes exclu(e) de la session 1.',
            Colors.orange,
            Icons.warning_amber,
          ),
        const SizedBox(height: 12),
        _buildJauge(
          'Absences sur cette ECUE',
          s.absencesEcue,
          s.seuilEcue,
          s.pourcentageEcue,
          Icons.book_outlined,
        ),
        const SizedBox(height: 10),
        _buildJauge(
          'Absences sur le semestre',
          s.absencesSemestre,
          s.seuilSemestre,
          s.pourcentageSemestre,
          Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 10),
        _buildJaugeHeures(
          'Heures d\'absence',
          s.heuresSemestre,
          s.seuilHeures,
          s.pourcentageHeures,
        ),
      ],
    );
  }

  Widget _buildAlerte(
    String titre,
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJauge(
    String label,
    int valeur,
    int seuil,
    double pourcentage,
    IconData icon,
  ) {
    final color = _couleurJauge(pourcentage);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$valeur / $seuil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pourcentage.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(pourcentage * 100).toStringAsFixed(0)}% du seuil atteint',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJaugeHeures(
    String label,
    double valeur,
    double seuil,
    double pourcentage,
  ) {
    final color = _couleurJauge(pourcentage);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${valeur.toStringAsFixed(0)}h / ${seuil.toStringAsFixed(0)}h',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pourcentage.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(pourcentage * 100).toStringAsFixed(0)}% du seuil — exclusion sessions 1 & 2',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _couleurJauge(double pct) {
    if (pct >= 1.0) return Colors.red;
    if (pct >= 0.66) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _ecueIdController.dispose();
    _semestreIdController.dispose();
    super.dispose();
  }
}
