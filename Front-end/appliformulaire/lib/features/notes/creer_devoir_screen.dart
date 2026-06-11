import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class CreerDevoirScreen extends StatefulWidget {
  const CreerDevoirScreen({super.key});

  @override
  State<CreerDevoirScreen> createState() => _CreerDevoirScreenState();
}

class _CreerDevoirScreenState extends State<CreerDevoirScreen> {
  final _session = SessionUtilisateur();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _classes = [];
  List<dynamic> _ecues = [];
  List<dynamic> _coursEnseignant = [];

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  int? _classeId;
  int? _ecueId;
  int? _coursId;
  String? _type;
  int _sessionNum = 1;
  final _titreCtrl      = TextEditingController();
  final _baremeCtrl     = TextEditingController(text: '20');
  final _dateCtrl       = TextEditingController();
  final _dureeCtrl      = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final List<String> _types = ['CC', 'TP', 'TD', 'EXAMEN'];

  static const Map<String, String> _statutLabels = {
    'planifie' : 'Planifié',
    'en_cours'  : 'En cours',
    'termine'   : 'Terminé',
    'annule'    : 'Annulé',
  };

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _baremeCtrl.dispose();
    _dateCtrl.dispose();
    _dureeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _chargerDonnees() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ecoleId = _session.ecoleId;

      final results = await Future.wait([
        ApiService.getClasses(ecoleId),
        ApiService.getEcues(ecoleId),
        ApiService.getCours(ecoleId),
      ]);

      //  FIX unnecessary_cast : Future.wait retourne List<dynamic>,
      //    on cast directement via pattern matching sans cast redondant
      final classesData = (results[0] as Map)['data'] as List? ?? [];
      final ecuesData   = (results[1] as Map)['data'] as List? ?? [];
      final coursData   = (results[2] as Map)['data'] as List? ?? [];

      final coursFiltres = coursData.where((c) {
        final statut      = c['statut'] ?? '';
        final enseignantId = c['enseignant_id'] as int?;
        return enseignantId == _session.id && statut != 'annule';
      }).toList();

      coursFiltres.sort((a, b) {
        final dateA = a['date_cours'] as String? ?? '';
        final dateB = b['date_cours'] as String? ?? '';
        return dateB.compareTo(dateA);
      });

      setState(() {
        _classes          = classesData;
        _ecues            = ecuesData;
        _coursEnseignant  = coursFiltres;
        _loading          = false;

        if (_coursEnseignant.length == 1) {
          _preselectCours(_coursEnseignant.first);
        } else {
          final enCours = coursFiltres
              .where((c) => c['statut'] == 'en_cours')
              .toList();
          if (enCours.length == 1) _preselectCours(enCours.first);
        }
      });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _preselectCours(dynamic c) {
    _coursId  = c['id']         as int?;
    _classeId = c['classe_id']  as int?;
    _ecueId   = c['ecue_id']    as int?;
  }

  void _onCoursSelectionne(int? coursId) {
    if (coursId == null) {
      setState(() { _coursId = null; _classeId = null; _ecueId = null; });
      return;
    }
    final cours = _coursEnseignant.firstWhere(
      (c) => c['id'] == coursId,
      orElse: () => null,
    );
    setState(() {
      _coursId  = coursId;
      _classeId = cours?['classe_id'] as int?;
      _ecueId   = cours?['ecue_id']   as int?;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOUMISSION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classeId == null || _ecueId == null || _type == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez remplir tous les champs obligatoires.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.creerDevoir(_session.ecoleId, {
        'classe_id'       : _classeId,
        'ecue_id'         : _ecueId,
        'titre'           : _titreCtrl.text.trim(),
        'type'            : _type,
        'session'         : _sessionNum,
        'bareme'          : double.tryParse(_baremeCtrl.text) ?? 20,
        'date_evaluation' : _dateCtrl.text,
        if (_coursId != null)                    'cours_id'    : _coursId,
        if (_dureeCtrl.text.isNotEmpty)          'duree'       : int.tryParse(_dureeCtrl.text),
        if (_descriptionCtrl.text.isNotEmpty)    'description' : _descriptionCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Devoir créé avec succès !'),
          backgroundColor: app.AppColors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LABEL COURS POUR DROPDOWN
  // ══════════════════════════════════════════════════════════════════════════

  String _labelCours(dynamic c) {
    final ecueNom   = (c['ecue']   as Map?)?['nom']  ?? c['ecue_nom']   ?? 'ECUE ?';
    final classeNom = (c['classe'] as Map?)?['nom']  ?? c['classe_nom'] ?? 'Classe ?';
    final date = (c['date_cours'] as String? ?? '').length >= 10
        ? (c['date_cours'] as String).substring(0, 10)
        : c['date_cours'] ?? '';
    final statut = _statutLabels[c['statut']] ?? c['statut'] ?? '';
    return '$ecueNom · $classeNom · $date [$statut]';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Padding horizontal adaptatif : 4% de la largeur, min 12, max 24
    final double sw   = MediaQuery.of(context).size.width;
    final double hPad = (sw * 0.04).clamp(12.0, 24.0);
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Créer un devoir',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _coursEnseignant.isEmpty
                  ? _buildAucunCours()
                  : SafeArea(
                      maintainBottomViewPadding: true,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, bottomPad),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // ── Bannière ──────────────────────────────────
                              _buildBanniere(),
                              const SizedBox(height: 14),

                              // ── Cours concerné ────────────────────────────
                              _buildSection('Cours concerné', [
                                _buildChamp(
                                  label: 'Cours *',
                                  //  FIX deprecated : initialValue au lieu de value
                                  child: DropdownButtonFormField<int>(
                                    key: ValueKey(_coursId),
                                    initialValue: _coursId,
                                    isExpanded: true,
                                    decoration: _inputDeco('Sélectionner le cours'),
                                    items: _coursEnseignant.map((c) {
                                      return DropdownMenuItem<int>(
                                        value: c['id'] as int,
                                        child: Text(
                                          _labelCours(c),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onCoursSelectionne,
                                    validator: (v) =>
                                        v == null ? 'Champ requis' : null,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),

                              // ── Informations générales ────────────────────
                              _buildSection('Informations générales', [
                                _buildChamp(
                                  label: 'Titre du devoir *',
                                  child: TextFormField(
                                    controller: _titreCtrl,
                                    textCapitalization: TextCapitalization.sentences,
                                    decoration: _inputDeco('Ex: Contrôle chapitre 1'),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildChamp(
                                  label: 'Classe *',
                                  //  FIX deprecated : initialValue au lieu de value
                                  child: DropdownButtonFormField<int>(
                                    key: ValueKey(_classeId),
                                    initialValue: _classeId,
                                    isExpanded: true,
                                    decoration: _inputDeco('Sélectionner une classe'),
                                    items: _classes.map((c) => DropdownMenuItem<int>(
                                      value: c['id'] as int,
                                      child: Text(
                                        c['nom'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _classeId = v),
                                    validator: (v) =>
                                        v == null ? 'Champ requis' : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildChamp(
                                  label: 'ECUE *',
                                  //  FIX deprecated : initialValue au lieu de value
                                  child: DropdownButtonFormField<int>(
                                    key: ValueKey(_ecueId),
                                    initialValue: _ecueId,
                                    isExpanded: true,
                                    decoration: _inputDeco('Sélectionner une ECUE'),
                                    items: _ecues.map((e) => DropdownMenuItem<int>(
                                      value: e['id'] as int,
                                      child: Text(
                                        '${e['nom'] ?? ''} (${e['code'] ?? ''})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _ecueId = v),
                                    validator: (v) =>
                                        v == null ? 'Champ requis' : null,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),

                              // ── Type et session ───────────────────────────
                              _buildSection('Type et session', [
                                _buildChamp(
                                  label: 'Type *',
                                  //  FIX deprecated : initialValue au lieu de value
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _type,
                                    isExpanded: true,
                                    decoration: _inputDeco('Sélectionner le type'),
                                    items: _types.map((t) => DropdownMenuItem<String>(
                                      value: t,
                                      child: Text(t),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _type = v),
                                    validator: (v) =>
                                        v == null ? 'Champ requis' : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildChamp(
                                  label: 'Session *',
                                  //  FIX deprecated : initialValue au lieu de value
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _sessionNum,
                                    isExpanded: true,
                                    decoration: _inputDeco(''),
                                    items: const [
                                      DropdownMenuItem(value: 1, child: Text('Session 1')),
                                      DropdownMenuItem(value: 2, child: Text('Session 2')),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _sessionNum = v ?? 1),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),

                              // ── Évaluation ────────────────────────────────
                              _buildSection('Évaluation', [
                                //  FIX overflow : on empile Barème/Durée verticalement
                                //    sur petits écrans (< 360px) et côte à côte sinon
                                sw < 360
                                    ? Column(
                                        children: [
                                          _buildChamp(
                                            label: 'Barème *',
                                            child: _baremeField(),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildChamp(
                                            label: 'Durée (minutes)',
                                            child: _dureeField(),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _buildChamp(
                                            label: 'Barème *',
                                            child: _baremeField(),
                                          )),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildChamp(
                                            label: 'Durée (minutes)',
                                            child: _dureeField(),
                                          )),
                                        ],
                                      ),
                                const SizedBox(height: 12),
                                _buildChamp(
                                  label: "Date d'évaluation *",
                                  child: TextFormField(
                                    controller: _dateCtrl,
                                    readOnly: true,
                                    onTap: _choisirDate,
                                    decoration: _inputDeco('Choisir une date').copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildChamp(
                                  label: 'Description (optionnel)',
                                  child: TextFormField(
                                    controller: _descriptionCtrl,
                                    maxLines: 3,
                                    decoration: _inputDeco('Consignes, chapitres concernés...'),
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 24),

                              // ── Bouton créer ──────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _submitting
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.add_task, color: Colors.white),
                                  label: Text(
                                    _submitting ? 'Création en cours...' : 'Créer le devoir',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _submitting ? null : _soumettre,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _baremeField() => TextFormField(
        controller: _baremeCtrl,
        keyboardType: TextInputType.number,
        decoration: _inputDeco('20'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Champ requis';
          if (double.tryParse(v) == null) return 'Nombre invalide';
          return null;
        },
      );

  Widget _dureeField() => TextFormField(
        controller: _dureeCtrl,
        keyboardType: TextInputType.number,
        decoration: _inputDeco('Ex: 60'),
      );

  Widget _buildBanniere() {
    final nbEnCours = _coursEnseignant.where((c) => c['statut'] == 'en_cours').length;
    final nbTotal   = _coursEnseignant.length;
    final String message = nbEnCours > 0
        ? '$nbEnCours cours en cours • $nbTotal cours disponibles pour créer un devoir.'
        : '$nbTotal cours disponibles. Sélectionnez celui concerné par ce devoir.';
    final Color couleur = nbEnCours > 0 ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: couleur, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: couleur, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  //  FIX overflow boutons : Column + boutons pleine largeur
  Widget _buildAucunCours() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucun cours assigné',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: app.AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vous n'avez aucun cours planifié. Contactez l'administrateur pour que des cours vous soient assignés.",
              textAlign: TextAlign.center,
              style: TextStyle(color: app.AppColors.textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            //  Boutons empilés verticalement → jamais d'overflow
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String titre, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: app.AppColors.textMain,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildChamp({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: app.AppColors.textSub,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _chargerDonnees,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}