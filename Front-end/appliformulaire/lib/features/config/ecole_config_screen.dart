// lib/features/config/ecole_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/services/api_service.dart';

class EcoleConfigScreen extends StatefulWidget {
  final int ecoleId;
  const EcoleConfigScreen({super.key, required this.ecoleId});

  @override
  State<EcoleConfigScreen> createState() => _EcoleConfigScreenState();
}

class _EcoleConfigScreenState extends State<EcoleConfigScreen>
    with SingleTickerProviderStateMixin {

  // ── Onglets ────────────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── État global ────────────────────────────────────────────────────────────
  bool _chargement    = true;
  bool _sauvegarde    = false;
  bool _estConfiguree = false;
  String? _erreur;

  // ── Section 1 — Calcul des notes ───────────────────────────────────────────
  double _poidsCC     = 40;
  double _poidsExamen = 60;
  final _noteMiniCtrl   = TextEditingController();
  final _moyenneValCtrl = TextEditingController();
  bool   _rattrapageTotal = true;

  // ── Section 1 — Crédits & progression ─────────────────────────────────────
  final _creditsSemestreCtrl       = TextEditingController();
  final _seuilEnjambementCtrl      = TextEditingController();
  int   _nombreSessions            = 2;

  // ── Section 2 — Assiduité ──────────────────────────────────────────────────
  final _absencesMaxEcueCtrl       = TextEditingController();
  final _absencesMaxSemestreCtrl   = TextEditingController();
  final _heuresExclusionCtrl       = TextEditingController();

  static const Color _brun   = Color(0xFF6D4C41);
  static const Color _fond   = Color(0xFFF4F6FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteMiniCtrl.dispose();
    _moyenneValCtrl.dispose();
    _creditsSemestreCtrl.dispose();
    _seuilEnjambementCtrl.dispose();
    _absencesMaxEcueCtrl.dispose();
    _absencesMaxSemestreCtrl.dispose();
    _heuresExclusionCtrl.dispose();
    super.dispose();
  }

  // ── Chargement ─────────────────────────────────────────────────────────────
  Future<void> _chargerConfig() async {
    setState(() { _chargement = true; _erreur = null; });
    try {
      final res    = await ApiService.getConfig(widget.ecoleId);
      final data   = res['data'] as Map<String, dynamic>? ?? {};
      _estConfiguree = res['est_configuree'] == true;

      setState(() {
        // Section 1 — notes
        _poidsCC     = (data['poids_cc']     ?? 40).toDouble();
        _poidsExamen = (data['poids_examen'] ?? 60).toDouble();
        _noteMiniCtrl.text   = (data['note_minimale_examen']  ?? 5.0).toString();
        _moyenneValCtrl.text = (data['moyenne_validation_ue'] ?? 10.0).toString();
        _rattrapageTotal     = data['rattrapage_note_100_pourcent'] ?? true;

        // Section 1 — crédits
        _creditsSemestreCtrl.text  = (data['credits_par_semestre']      ?? 30).toString();
        _seuilEnjambementCtrl.text = (data['seuil_enjambement_pourcent'] ?? 80).toString();
        _nombreSessions            = (data['nombre_sessions']           ?? 2) as int;

        // Section 2 — assiduité
        _absencesMaxEcueCtrl.text     = (data['absences_max_par_ecue']          ?? 3).toString();
        _absencesMaxSemestreCtrl.text = (data['absences_max_par_semestre']       ?? 10).toString();
        _heuresExclusionCtrl.text     = (data['heures_absence_exclusion_s1_s2'] ?? 150).toString();

        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur     = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  // ── Validation locale avant envoi ──────────────────────────────────────────
  String? _valider() {
    final noteMin  = double.tryParse(_noteMiniCtrl.text.trim());
    final moyenneV = double.tryParse(_moyenneValCtrl.text.trim());
    final credits  = int.tryParse(_creditsSemestreCtrl.text.trim());
    final seuil    = int.tryParse(_seuilEnjambementCtrl.text.trim());
    final absEcue  = int.tryParse(_absencesMaxEcueCtrl.text.trim());
    final absSem   = int.tryParse(_absencesMaxSemestreCtrl.text.trim());
    final heures   = int.tryParse(_heuresExclusionCtrl.text.trim());

    if (_poidsCC.round() + _poidsExamen.round() != 100) {
      return 'La somme Poids CC + Poids Examen doit être égale à 100%.';
    }
    if (noteMin == null || noteMin < 0 || noteMin > 20) {
      return 'Note minimale examen : valeur entre 0 et 20 requise.';
    }
    if (moyenneV == null || moyenneV < 0 || moyenneV > 20) {
      return 'Moyenne de validation UE : valeur entre 0 et 20 requise.';
    }
    if (noteMin > moyenneV) {
      return 'La note minimale examen ne peut pas dépasser la moyenne de validation UE.';
    }
    if (credits == null || credits < 1 || credits > 60) {
      return 'Crédits par semestre : valeur entre 1 et 60 requise.';
    }
    if (seuil == null || seuil < 0 || seuil > 100) {
      return 'Seuil d\'enjambement : valeur entre 0 et 100 requise.';
    }
    if (absEcue == null || absEcue < 0) {
      return 'Absences max par ECUE : valeur positive requise.';
    }
    if (absSem == null || absSem < 0) {
      return 'Absences max par semestre : valeur positive requise.';
    }
    if (heures == null || heures < 0) {
      return 'Heures d\'absence pour exclusion : valeur positive requise.';
    }
    return null;
  }

  // ── Sauvegarde ─────────────────────────────────────────────────────────────
  Future<void> _sauvegarder() async {
    FocusScope.of(context).unfocus();

    final erreur = _valider();
    if (erreur != null) {
      _snackErr(erreur);
      return;
    }

    setState(() => _sauvegarde = true);
    try {
      await ApiService.saveConfig(widget.ecoleId, {
        // Section 1 — notes
        'poids_cc'                      : _poidsCC.round(),
        'poids_examen'                  : _poidsExamen.round(),
        'note_minimale_examen'          : double.parse(_noteMiniCtrl.text.trim()),
        'moyenne_validation_ue'         : double.parse(_moyenneValCtrl.text.trim()),
        'rattrapage_note_100_pourcent'  : _rattrapageTotal,
        // Section 1 — crédits
        'credits_par_semestre'          : int.parse(_creditsSemestreCtrl.text.trim()),
        'seuil_enjambement_pourcent'    : int.parse(_seuilEnjambementCtrl.text.trim()),
        'nombre_sessions'               : _nombreSessions,
        // Section 2 — assiduité
        'absences_max_par_ecue'         : int.parse(_absencesMaxEcueCtrl.text.trim()),
        'absences_max_par_semestre'     : int.parse(_absencesMaxSemestreCtrl.text.trim()),
        'heures_absence_exclusion_s1_s2': int.parse(_heuresExclusionCtrl.text.trim()),
      });

      if (mounted) {
        setState(() => _estConfiguree = true);
        _snackOk('Configuration enregistrée avec succès !');
      }
    } catch (e) {
      if (mounted) _snackErr(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sauvegarde = false);
    }
  }

  // ── Snackbars ──────────────────────────────────────────────────────────────
  void _snackOk(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _snackErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build principal ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        title: const Text(
          'Configuration pédagogique',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _brun,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Badge "configurée" ou "par défaut"
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _estConfiguree
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _estConfiguree ? 'Configurée' : 'Par défaut',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _estConfiguree ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined, size: 18), text: 'Notes'),
            Tab(icon: Icon(Icons.school_outlined,    size: 18), text: 'Crédits'),
            Tab(icon: Icon(Icons.event_busy_outlined, size: 18), text: 'Assiduité'),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? _buildErreur()
              : Column(
                  children: [
                    // Bandeau info si première config
                    if (!_estConfiguree)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: Colors.orange.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucune configuration enregistrée. '
                                'Les valeurs affichées sont les valeurs par défaut.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Onglets
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOngletNotes(),
                          _buildOngletCredits(),
                          _buildOngletAssiduite(),
                        ],
                      ),
                    ),

                    // Boutons du bas
                    _buildBoutonsBas(),
                  ],
                ),
    );
  }

  // ── Onglet 1 — Notes ───────────────────────────────────────────────────────
  Widget _buildOngletNotes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitre(
            Icons.balance_outlined,
            'Pondération CC / Examen',
            'La somme doit toujours être égale à 100%',
          ),
          const SizedBox(height: 16),

          // Slider CC
          _sliderPoids(
            label: 'Poids Contrôle Continu (CC)',
            valeur: _poidsCC,
            couleur: Colors.blue,
            onChanged: (v) {
              setState(() {
                _poidsCC     = v.roundToDouble();
                _poidsExamen = (100 - _poidsCC).roundToDouble();
              });
            },
          ),
          const SizedBox(height: 8),

          // Slider Examen
          _sliderPoids(
            label: 'Poids Examen final',
            valeur: _poidsExamen,
            couleur: Colors.deepPurple,
            onChanged: (v) {
              setState(() {
                _poidsExamen = v.roundToDouble();
                _poidsCC     = (100 - _poidsExamen).roundToDouble();
              });
            },
          ),

          // Indicateur somme
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: (_poidsCC + _poidsExamen == 100)
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_poidsCC + _poidsExamen == 100)
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (_poidsCC + _poidsExamen == 100)
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 16,
                  color: (_poidsCC + _poidsExamen == 100)
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total : ${(_poidsCC + _poidsExamen).round()}% '
                  '${(_poidsCC + _poidsExamen == 100) ? "✓" : "≠ 100%"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: (_poidsCC + _poidsExamen == 100)
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitre(
            Icons.grade_outlined,
            'Seuils de validation',
            'Notes éliminatoires et de passage',
          ),
          const SizedBox(height: 16),

          // Note minimale examen
          _champNumerique(
            controller: _noteMiniCtrl,
            label: 'Note minimale à l\'examen',
            hint: '5.00',
            unite: '/ 20',
            description:
                'En dessous de cette note, l\'étudiant est automatiquement ajourné même si sa moyenne est suffisante.',
            icone: Icons.remove_circle_outline,
            couleur: Colors.red,
            decimal: true,
          ),
          const SizedBox(height: 16),

          // Moyenne validation UE
          _champNumerique(
            controller: _moyenneValCtrl,
            label: 'Moyenne de validation de l\'UE',
            hint: '10.00',
            unite: '/ 20',
            description:
                'Note minimale pour valider une Unité d\'Enseignement.',
            icone: Icons.check_circle_outline,
            couleur: Colors.green,
            decimal: true,
          ),
          const SizedBox(height: 24),

          _sectionTitre(
            Icons.replay_outlined,
            'Règle de rattrapage',
            '',
          ),
          const SizedBox(height: 12),

          // Switch rattrapage 100%
          _switchOption(
            titre: 'Note de rattrapage remplace à 100%',
            description:
                'Si activé, la note de rattrapage remplace entièrement la note '
                'initiale (même si elle est inférieure). Si désactivé, seule '
                'la meilleure note est retenue.',
            valeur: _rattrapageTotal,
            onChanged: (v) => setState(() => _rattrapageTotal = v),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Onglet 2 — Crédits & progression ──────────────────────────────────────
  Widget _buildOngletCredits() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitre(
            Icons.library_books_outlined,
            'Crédits ECTS',
            'Système européen de transfert de crédits',
          ),
          const SizedBox(height: 16),

          _champNumerique(
            controller: _creditsSemestreCtrl,
            label: 'Crédits par semestre',
            hint: '30',
            unite: 'crédits',
            description:
                'Nombre total de crédits à valider pour compléter un semestre (généralement 30 en système LMD).',
            icone: Icons.stars_outlined,
            couleur: Colors.amber,
            decimal: false,
          ),
          const SizedBox(height: 24),

          _sectionTitre(
            Icons.trending_up_outlined,
            'Progression & enjambement',
            'Conditions pour passer en année supérieure',
          ),
          const SizedBox(height: 16),

          _champNumerique(
            controller: _seuilEnjambementCtrl,
            label: 'Seuil d\'enjambement',
            hint: '80',
            unite: '%',
            description:
                'Pourcentage de crédits minimum à valider pour pouvoir passer '
                'en année supérieure tout en conservant les UE non validées.',
            icone: Icons.moving_outlined,
            couleur: Colors.teal,
            decimal: false,
          ),
          const SizedBox(height: 24),

          _sectionTitre(
            Icons.event_repeat_outlined,
            'Sessions d\'examen',
            'Nombre de sessions par année académique',
          ),
          const SizedBox(height: 16),

          // Sélecteur nombre de sessions
          Container(
            padding: const EdgeInsets.all(16),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre de sessions d\'examen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: app.AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inclut les sessions normales et de rattrapage.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3].map((n) {
                    final selected = _nombreSessions == n;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _nombreSessions = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? _brun
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _brun
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : Colors.grey,
                                ),
                              ),
                              Text(
                                n == 1 ? 'session' : 'sessions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white70
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Onglet 3 — Assiduité ───────────────────────────────────────────────────
  Widget _buildOngletAssiduite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitre(
            Icons.event_busy_outlined,
            'Limites d\'absences',
            'Au-delà de ces seuils, des sanctions s\'appliquent',
          ),
          const SizedBox(height: 16),

          _champNumerique(
            controller: _absencesMaxEcueCtrl,
            label: 'Absences max par ECUE',
            hint: '3',
            unite: 'absences',
            description:
                'Nombre d\'absences non justifiées tolérées par cours (ECUE). '
                'Au-delà, l\'étudiant peut être exclu de la composition.',
            icone: Icons.class_outlined,
            couleur: Colors.orange,
            decimal: false,
          ),
          const SizedBox(height: 16),

          _champNumerique(
            controller: _absencesMaxSemestreCtrl,
            label: 'Absences max par semestre',
            hint: '10',
            unite: 'absences',
            description:
                'Nombre total d\'absences non justifiées tolérées sur l\'ensemble '
                'du semestre toutes ECUE confondues.',
            icone: Icons.calendar_month_outlined,
            couleur: Colors.deepOrange,
            decimal: false,
          ),
          const SizedBox(height: 24),

          _sectionTitre(
            Icons.block_outlined,
            'Exclusion des sessions',
            'Seuil horaire d\'exclusion définitive',
          ),
          const SizedBox(height: 16),

          _champNumerique(
            controller: _heuresExclusionCtrl,
            label: 'Heures d\'absence pour exclusion S1 + S2',
            hint: '150',
            unite: 'heures',
            description:
                'Volume horaire d\'absences cumulées (sessions 1 et 2) à partir '
                'duquel l\'étudiant est définitivement exclu des deux sessions.',
            icone: Icons.timer_off_outlined,
            couleur: Colors.red,
            decimal: false,
          ),

          const SizedBox(height: 24),

          // Info — échéances gérées depuis Gestion des paiements
          _infoEcheances(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Info-bulle échéances ─────────────────────────────────────────────────
  Widget _infoEcheances() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.teal, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Échéances de scolarité',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Les tranches et dates limites de paiement se configurent '
                  'depuis Gestion des paiements → sélectionner un étudiant '
                  '→ "Configurer frais" (onglet Échéances).',
                  style: TextStyle(
                    fontSize: 12,
                    color: app.AppColors.textSub,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons du bas (Réinitialiser + Enregistrer) ───────────────────────────
  Widget _buildBoutonsBas() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Réinitialiser
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _sauvegarde ? null : _chargerConfig,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brun,
                  side: BorderSide(color: _brun.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Enregistrer
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _sauvegarde ? null : _sauvegarder,
                icon: _sauvegarde
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_sauvegarde ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brun,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _brun.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets réutilisables ──────────────────────────────────────────────────

  Widget _sectionTitre(IconData icone, String titre, String sousTitre) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _brun.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: _brun, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: app.AppColors.textMain,
                ),
              ),
              if (sousTitre.isNotEmpty)
                Text(
                  sousTitre,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderPoids({
    required String label,
    required double valeur,
    required Color couleur,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: app.AppColors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${valeur.round()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: couleur,
              thumbColor: couleur,
              inactiveTrackColor: couleur.withValues(alpha: 0.2),
              overlayColor: couleur.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: valeur,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _champNumerique({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unite,
    required String description,
    required IconData icone,
    required Color couleur,
    required bool decimal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: couleur, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: app.AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: decimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: decimal
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                      : [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: app.AppColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: couleur, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unite,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: couleur,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchOption({
    required String titre,
    required String description,
    required bool valeur,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: app.AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: valeur,
            onChanged: onChanged,
            activeColor: _brun,
          ),
        ],
      ),
    );
  }

  // ── Écran d'erreur ─────────────────────────────────────────────────────────
  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: app.AppColors.red),
            const SizedBox(height: 16),
            Text(
              _erreur!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _chargerConfig,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brun,
                foregroundColor: Colors.white,
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
}