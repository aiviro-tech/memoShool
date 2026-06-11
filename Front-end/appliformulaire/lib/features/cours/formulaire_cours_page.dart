import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/services/api_service.dart';

class FormulaireCoursPage extends StatefulWidget {
  final int ecoleId;
  final CoursModel? cours;

  const FormulaireCoursPage({
    super.key,
    required this.ecoleId,
    required this.cours,
  });

  @override
  State<FormulaireCoursPage> createState() => _FormulaireCoursPageState();
}

class _FormulaireCoursPageState extends State<FormulaireCoursPage> {
  final _formKey = GlobalKey<FormState>();
  bool _chargement = false;
  bool _chargementDonnees = true;

  List<Map<String, dynamic>> _ecues      = [];
  List<Map<String, dynamic>> _salles     = [];
  List<Map<String, dynamic>> _classes    = [];
  List<Map<String, dynamic>> _enseignants = [];
  List<Map<String, dynamic>> _filieres   = [];
  List<Map<String, dynamic>> _semestres  = [];
  List<Map<String, dynamic>> _ues        = [];

  int? _ecueId;
  int? _salleId;
  int? _classeId;
  int? _enseignantId;
  int? _semestreId;

  late TextEditingController _dateCtrl;
  late TextEditingController _heureDebutCtrl;
  late TextEditingController _heureFinCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _anneeCtrl;

  static const double _gap       = 10.0;
  static const double _labelSz   = 13.5;
  static const double _fieldPad  = 10.0;
  static const double _btnPad    = 13.0;
  static const double _titleSz   = 13.0;
  static const double _errorSz   = 10.5;

  InputDecoration _deco(String label, {IconData? icon, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: _labelSz, color: app.AppColors.textSub),
        prefixIcon: icon != null
            ? Icon(icon, size: 18.0, color: app.AppColors.primary)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: _fieldPad),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6),
        ),
        errorStyle: const TextStyle(fontSize: _errorSz, height: 0.9),
      );

  @override
  void initState() {
    super.initState();
    final c = widget.cours;
    _dateCtrl       = TextEditingController(text: c?.dateCours ?? '');
    _heureDebutCtrl = TextEditingController(text: c?.heureDebut ?? '');
    _heureFinCtrl   = TextEditingController(text: c?.heureFin ?? '');
    _notesCtrl      = TextEditingController(text: c?.notes ?? '');
    _anneeCtrl      = TextEditingController(text: c?.anneeAcademique ?? '');
    _chargerDonnees();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _heureDebutCtrl.dispose();
    _heureFinCtrl.dispose();
    _notesCtrl.dispose();
    _anneeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    try {
      final results = await Future.wait([
        ApiService.getEcues(widget.ecoleId),
        ApiService.getClasses(widget.ecoleId),
        ApiService.getEnseignants(widget.ecoleId),
        ApiService.getSalles(widget.ecoleId),
        ApiService.getFilieres(widget.ecoleId),
        ApiService.getSemestres(widget.ecoleId),
        ApiService.getUes(widget.ecoleId),
      ]);
      if (!mounted) return;
      setState(() {
        _ecues       = List<Map<String, dynamic>>.from((results[0] as Map)['data'] ?? []);
        _classes     = List<Map<String, dynamic>>.from((results[1] as Map)['data'] ?? []);
        _enseignants = List<Map<String, dynamic>>.from(results[2] as List);
        _salles      = List<Map<String, dynamic>>.from((results[3] as Map)['data'] ?? []);
        _filieres    = List<Map<String, dynamic>>.from((results[4] as Map)['data'] ?? []);
        _semestres   = List<Map<String, dynamic>>.from((results[5] as Map)['data'] ?? []);
        _ues         = List<Map<String, dynamic>>.from((results[6] as Map)['data'] ?? []);
        _chargementDonnees = false;
        _preremplirEdition();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargementDonnees = false);
      _snackErr('Erreur chargement : ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _preremplirEdition() {
    final c = widget.cours;
    if (c == null) return;
    for (final e in _ecues) {
      if (e['code'] == c.ecueCode) { _ecueId = e['id'] as int; break; }
    }
    for (final e in _enseignants) {
      if (e['id'] == c.enseignantId) { _enseignantId = e['id'] as int; break; }
    }
    for (final cl in _classes) {
      if (cl['nom'] == c.classe) { _classeId = cl['id'] as int; break; }
    }
    for (final s in _salles) {
      if (s['code'] == c.salleCode) { _salleId = s['id'] as int; break; }
    }
  }

  Future<void> _creerFiliere() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CreerFilierePage(ecoleId: widget.ecoleId)),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _creerSemestre() async {
    if (!mounted) return;
    if (_filieres.isEmpty) {
      _snackErr('Créez d\'abord une filière');
      await _creerFiliere();
      if (_filieres.isEmpty) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreerSemestrePage(ecoleId: widget.ecoleId, filieres: _filieres),
      ),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _creerUe() async {
    if (!mounted) return;
    if (_semestres.isEmpty) {
      _snackErr('Créez d\'abord un semestre');
      await _creerSemestre();
      if (_semestres.isEmpty) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreerUePage(ecoleId: widget.ecoleId, semestres: _semestres),
      ),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _creerEcue() async {
    if (!mounted) return;
    if (_ues.isEmpty) {
      _snackErr('Créez d\'abord une UE');
      await _creerUe();
      if (_ues.isEmpty) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreerEcuePage(ecoleId: widget.ecoleId, ues: _ues),
      ),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _creerClasse() async {
    if (!mounted) return;
    if (_filieres.isEmpty) {
      _snackErr('Créez d\'abord une filière');
      await _creerFiliere();
      if (_filieres.isEmpty) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreerClassePage(
          ecoleId: widget.ecoleId,
          filieres: _filieres,
          anneeDefaut: _anneeCtrl.text,
        ),
      ),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _creerSalle() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CreerSallePage(ecoleId: widget.ecoleId)),
    );
    if (!mounted) return;
    await _chargerDonnees();
  }

  Future<void> _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: app.AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _dateCtrl.text =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectionnerHeure(TextEditingController ctrl) async {
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (heure != null) {
      setState(() {
        ctrl.text =
            '${heure.hour.toString().padLeft(2, '0')}:${heure.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _chargerSallesDisponibles() async {
    try {
      final result = await ApiService.getSallesDisponibles(
        widget.ecoleId,
        date: _dateCtrl.text,
        heureDebut: _heureDebutCtrl.text,
        heureFin: _heureFinCtrl.text,
      );
      setState(() {
        _salles = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _salleId = null;
      });
      _snackOk('${_salles.length} salle(s) disponible(s)');
    } catch (e) {
      _snackErr(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ecueId == null || _salleId == null || _classeId == null ||
        _enseignantId == null || _semestreId == null) {
      _snackErr('Veuillez remplir tous les champs obligatoires (*)');
      return;
    }
    setState(() => _chargement = true);
    final data = {
      'ecue_id':       _ecueId,
      'salle_id':      _salleId,
      'classe_id':     _classeId,
      'enseignant_id': _enseignantId,
      'date_cours':    _dateCtrl.text.trim(),
      'heure_debut':   _heureDebutCtrl.text.trim(),
      'heure_fin':     _heureFinCtrl.text.trim(),
      'semestre_id':   _semestreId,
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    try {
      if (widget.cours == null) {
        await ApiService.creerCours(widget.ecoleId, data);
      } else {
        await ApiService.modifierCours(widget.ecoleId, widget.cours!.id, data);
      }
      if (mounted) {
        _snackOk(widget.cours == null ? 'Cours créé !' : 'Cours modifié !');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snackErr(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double hPad = screenW * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: Text(widget.cours != null ? 'Modifier le cours' : 'Nouveau cours'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargementDonnees
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Chargement...', style: TextStyle(color: app.AppColors.textSub)),
                ],
              ),
            )
          : SafeArea(
              maintainBottomViewPadding: true,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      _titre('Matière & Enseignant'),
                      const SizedBox(height: _gap),

                      _DropdownAvecBouton<int>(
                        deco: _deco('ECUE (matière) *', icon: Icons.menu_book_outlined),
                        valeur: _ecueId,
                        items: _ecues.map((m) => DropdownMenuItem<int>(
                          value: m['id'] as int,
                          child: Text('${m['nom']} (${m['code']})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: _labelSz)),
                        )).toList(),
                        onChanged: (v) => setState(() => _ecueId = v),
                        tooltip: 'Créer un ECUE',
                        onAjouter: _creerEcue,
                      ),
                      const SizedBox(height: _gap),

                      _dropdownSimple<int>(
                        deco: _deco('Enseignant *', icon: Icons.person_outline),
                        valeur: _enseignantId,
                        items: _enseignants.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(
                            e['full_name'] ?? '${e['first_name']} ${e['last_name']}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: _labelSz),
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _enseignantId = v),
                      ),
                      const SizedBox(height: _gap),

                      _titre('Classe & Salle'),
                      const SizedBox(height: _gap),

                      _DropdownAvecBouton<int>(
                        deco: _deco('Classe *', icon: Icons.school_outlined),
                        valeur: _classeId,
                        items: _classes.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text('${c['nom']} (${c['code']})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: _labelSz)),
                        )).toList(),
                        onChanged: (v) => setState(() => _classeId = v),
                        tooltip: 'Créer une classe',
                        onAjouter: _creerClasse,
                      ),
                      const SizedBox(height: _gap),

                      _DropdownAvecDeuxBoutons<int>(
                        deco: _deco('Salle *', icon: Icons.location_on_outlined),
                        valeur: _salleId,
                        items: _salles.map((s) => DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text('${s['nom']} (cap. ${s['capacite']})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: _labelSz)),
                        )).toList(),
                        onChanged: (v) => setState(() => _salleId = v),
                        tooltip1: 'Salles disponibles',
                        icon1: Icons.search,
                        onBtn1: (_dateCtrl.text.isNotEmpty &&
                                _heureDebutCtrl.text.isNotEmpty &&
                                _heureFinCtrl.text.isNotEmpty)
                            ? _chargerSallesDisponibles
                            : null,
                        tooltip2: 'Créer une salle',
                        icon2: Icons.add_circle_outline,
                        onBtn2: _creerSalle,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Remplissez date & horaires puis 🔍 pour voir les salles libres',
                        style: TextStyle(fontSize: 11.0, color: app.AppColors.textSub),
                      ),
                      const SizedBox(height: _gap),

                      _titre('Date & Horaires'),
                      const SizedBox(height: _gap),

                      GestureDetector(
                        onTap: _selectionnerDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateCtrl,
                            style: const TextStyle(fontSize: _labelSz),
                            decoration: _deco('Date du cours *',
                                icon: Icons.calendar_today_outlined),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: _gap),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectionnerHeure(_heureDebutCtrl),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _heureDebutCtrl,
                                  style: const TextStyle(fontSize: _labelSz),
                                  decoration: _deco('Début *',
                                      icon: Icons.access_time_outlined),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Obligatoire' : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: _gap),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectionnerHeure(_heureFinCtrl),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _heureFinCtrl,
                                  style: const TextStyle(fontSize: _labelSz),
                                  decoration: _deco('Fin *',
                                      icon: Icons.access_time_outlined),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Obligatoire' : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _gap),

                      _titre('Semestre'),
                      const SizedBox(height: _gap),

                      _DropdownAvecBouton<int>(
                        deco: _deco('Semestre *', icon: Icons.category_outlined),
                        valeur: _semestreId,
                        items: _semestres.map((s) => DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text(
                            '${s['numero'] ?? ''} — ${s['annee_academique'] ?? ''}',
                            style: const TextStyle(fontSize: _labelSz),
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _semestreId = v),
                        tooltip: 'Créer un semestre',
                        onAjouter: _creerSemestre,
                      ),
                      const SizedBox(height: _gap),

                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(fontSize: _labelSz),
                        decoration: _deco('Notes (optionnel)', icon: Icons.notes_outlined),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _chargement ? null : _enregistrer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: _btnPad),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _chargement
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  widget.cours == null
                                      ? 'Créer le cours'
                                      : 'Enregistrer les modifications',
                                  style: const TextStyle(
                                      fontSize: 15.0, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _titre(String t) => Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: _titleSz,
          color: app.AppColors.primary,
          letterSpacing: 0.3,
        ),
      );

  Widget _dropdownSimple<T>({
    required InputDecoration deco,
    required T? valeur,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      DropdownButtonFormField<T>(
        key: ValueKey('$valeur'),
        initialValue: valeur, // ← CORRECTION : value → initialValue
        isExpanded: true,
        decoration: deco,
        style: const TextStyle(fontSize: _labelSz, color: app.AppColors.textMain),
        items: items,
        onChanged: onChanged,
      );

  void _snackOk(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: app.AppColors.green),
    );
  }

  void _snackErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: app.AppColors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS DROPDOWN RÉUTILISABLES
// ══════════════════════════════════════════════════════════════════════════════

class _DropdownAvecBouton<T> extends StatelessWidget {
  final InputDecoration deco;
  final T? valeur;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String tooltip;
  final VoidCallback onAjouter;

  const _DropdownAvecBouton({
    required this.deco,
    required this.valeur,
    required this.items,
    required this.onChanged,
    required this.tooltip,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            key: ValueKey(valeur),
            initialValue: valeur, // ← CORRECTION
            isExpanded: true,
            decoration: deco,
            style: const TextStyle(
                fontSize: _FormulaireCoursPageState._labelSz,
                color: app.AppColors.textMain),
            items: items,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onAjouter,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: app.AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: app.AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add, color: app.AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownAvecDeuxBoutons<T> extends StatelessWidget {
  final InputDecoration deco;
  final T? valeur;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String tooltip1;
  final IconData icon1;
  final VoidCallback? onBtn1;
  final String tooltip2;
  final IconData icon2;
  final VoidCallback onBtn2;

  const _DropdownAvecDeuxBoutons({
    required this.deco,
    required this.valeur,
    required this.items,
    required this.onChanged,
    required this.tooltip1,
    required this.icon1,
    required this.onBtn1,
    required this.tooltip2,
    required this.icon2,
    required this.onBtn2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            key: ValueKey(valeur),
            initialValue: valeur, // ← CORRECTION
            isExpanded: true,
            decoration: deco,
            style: const TextStyle(
                fontSize: _FormulaireCoursPageState._labelSz,
                color: app.AppColors.textMain),
            items: items,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip1,
          child: InkWell(
            onTap: onBtn1,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: onBtn1 != null
                    ? app.AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: onBtn1 != null
                      ? app.AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(icon1,
                  color: onBtn1 != null ? app.AppColors.primary : Colors.grey,
                  size: 19),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip2,
          child: InkWell(
            onTap: onBtn2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: app.AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: app.AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon2, color: app.AppColors.primary, size: 19),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER FILIÈRE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerFilierePage extends StatefulWidget {
  final int ecoleId;
  const _CreerFilierePage({required this.ecoleId});
  @override
  State<_CreerFilierePage> createState() => _CreerFilierePageState();
}

class _CreerFilierePageState extends State<_CreerFilierePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl  = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.creerFiliere(widget.ecoleId, {
        'nom': _nomCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle filière'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                  message: 'La filière regroupe les classes (ex: Informatique, Finance).',
                  couleur: Colors.blue,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nomCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _deco('Nom de la filière *', icon: Icons.folder_outlined),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _codeCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _deco('Code *', icon: Icons.tag),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer la filière',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER SEMESTRE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerSemestrePage extends StatefulWidget {
  final int ecoleId;
  final List<Map<String, dynamic>> filieres;
  const _CreerSemestrePage({required this.ecoleId, required this.filieres});
  @override
  State<_CreerSemestrePage> createState() => _CreerSemestrePageState();
}

class _CreerSemestrePageState extends State<_CreerSemestrePage> {
  final _formKey   = GlobalKey<FormState>();
  final _numCtrl   = TextEditingController();
  final _anneeCtrl = TextEditingController(text: '2025-2026');
  int? _filiereId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.filieres.isNotEmpty) {
      _filiereId = widget.filieres.first['id'] as int;
    }
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _anneeCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate() || _filiereId == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.creerSemestre(widget.ecoleId, {
        'numero': _numCtrl.text.trim(),
        'annee_academique': _anneeCtrl.text.trim(),
        'filiere_id': _filiereId,
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau semestre'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                    message: 'Le semestre est rattaché à une filière (ex: S1 — 2025-2026).',
                    couleur: Colors.green),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _numCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _deco('Numéro *', icon: Icons.format_list_numbered),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _anneeCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _deco('Année académique *', icon: Icons.calendar_today_outlined),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _filiereId, // ← CORRECTION
                  isExpanded: true,
                  decoration: _deco('Filière *', icon: Icons.folder_outlined),
                  style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                  items: widget.filieres.map((f) => DropdownMenuItem<int>(
                    value: f['id'] as int,
                    child: Text(f['nom'] ?? '', overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5)),
                  )).toList(),
                  onChanged: (v) => setState(() => _filiereId = v),
                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer le semestre',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER UE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerUePage extends StatefulWidget {
  final int ecoleId;
  final List<Map<String, dynamic>> semestres;
  const _CreerUePage({required this.ecoleId, required this.semestres});
  @override
  State<_CreerUePage> createState() => _CreerUePageState();
}

class _CreerUePageState extends State<_CreerUePage> {
  final _formKey     = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _creditsCtrl = TextEditingController(text: '6');

  List<Map<String, dynamic>> _semestres = [];
  int? _semestreId;
  bool _loading = false;
  bool _chargementSemestres = true;
  String? _erreurSemestres;

  @override
  void initState() {
    super.initState();
    _semestres = List.from(widget.semestres);
    if (_semestres.isNotEmpty) {
      _semestreId = _semestres.first['id'] as int;
      _chargementSemestres = false;
    }
    _rechargerSemestres();
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _codeCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechargerSemestres() async {
    try {
      final result = await ApiService.getSemestres(widget.ecoleId);
      final liste = List<Map<String, dynamic>>.from(
        (result as Map)['data'] ?? [],
      );
      if (!mounted) return;
      setState(() {
        _semestres = liste;
        if (_semestreId == null || !liste.any((s) => s['id'] == _semestreId)) {
          _semestreId = liste.isNotEmpty ? liste.first['id'] as int : null;
        }
        _chargementSemestres = false;
        _erreurSemestres = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargementSemestres = false;
        _erreurSemestres = 'Impossible de charger les semestres';
      });
    }
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_semestreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner un semestre'),
        backgroundColor: app.AppColors.red,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.creerUe(widget.ecoleId, {
        'libelle': _libelleCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
        'credits_ects': int.tryParse(_creditsCtrl.text) ?? 6,
        'semestre_id': _semestreId,
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle UE'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                    message: 'L\'UE (Unité d\'Enseignement) regroupe plusieurs ECUE.',
                    couleur: Colors.indigo),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _libelleCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Libellé *', icon: Icons.label_outline),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _codeCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Code *', icon: Icons.tag),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.characters),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _creditsCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    keyboardType: TextInputType.number,
                    decoration: _deco('Crédits ECTS *', icon: Icons.star_outline),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null),
                const SizedBox(height: 10),

                if (_chargementSemestres)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: app.AppColors.primary),
                        ),
                        SizedBox(width: 10),
                        Text('Chargement des semestres…',
                            style: TextStyle(fontSize: 13.5, color: app.AppColors.textSub)),
                      ],
                    ),
                  )
                else if (_erreurSemestres != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: app.AppColors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: app.AppColors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: app.AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_erreurSemestres!,
                            style: const TextStyle(color: app.AppColors.red, fontSize: 12))),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _chargementSemestres = true;
                              _erreurSemestres = null;
                            });
                            _rechargerSemestres();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (_semestres.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucun semestre disponible. Revenez en arrière et créez d\'abord un semestre.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    key: ValueKey(_semestres.length),
                    initialValue: _semestreId, // ← CORRECTION
                    isExpanded: true,
                    decoration: _deco('Semestre *', icon: Icons.category_outlined),
                    style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                    items: _semestres.map((s) => DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(
                        '${s['numero'] ?? ''} — ${s['annee_academique'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _semestreId = v),
                    validator: (v) => v == null ? 'Champ obligatoire' : null,
                  ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_loading || _chargementSemestres || _semestres.isEmpty)
                      ? null
                      : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer l\'UE',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER ECUE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerEcuePage extends StatefulWidget {
  final int ecoleId;
  final List<Map<String, dynamic>> ues;
  const _CreerEcuePage({required this.ecoleId, required this.ues});
  @override
  State<_CreerEcuePage> createState() => _CreerEcuePageState();
}

class _CreerEcuePageState extends State<_CreerEcuePage> {
  final _formKey     = GlobalKey<FormState>();
  final _nomCtrl     = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _creditsCtrl = TextEditingController(text: '3');
  final _volCtrl     = TextEditingController(text: '30');
  String _type   = 'CM';
  String _niveau = 'L1';

  List<Map<String, dynamic>> _ues = [];
  int? _ueId;
  bool _loading = false;
  bool _chargementUes = true;
  String? _erreurUes;

  @override
  void initState() {
    super.initState();
    _ues = List.from(widget.ues);
    if (_ues.isNotEmpty) {
      _ueId = _ues.first['id'] as int;
      _chargementUes = false;
    }
    _rechargerUes();
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _codeCtrl.dispose();
    _creditsCtrl.dispose(); _volCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechargerUes() async {
    try {
      final result = await ApiService.getUes(widget.ecoleId);
      final liste = List<Map<String, dynamic>>.from(
        (result as Map)['data'] ?? [],
      );
      if (!mounted) return;
      setState(() {
        _ues = liste;
        if (_ueId == null || !liste.any((u) => u['id'] == _ueId)) {
          _ueId = liste.isNotEmpty ? liste.first['id'] as int : null;
        }
        _chargementUes = false;
        _erreurUes = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargementUes = false;
        _erreurUes = 'Impossible de charger les UEs';
      });
    }
  }

  Future<void> _creerNouvelleUe() async {
    if (!mounted) return;
    List<Map<String, dynamic>> semestres = [];
    try {
      final result = await ApiService.getSemestres(widget.ecoleId);
      semestres = List<Map<String, dynamic>>.from(
        (result as Map)['data'] ?? [],
      );
    } catch (_) {}
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreerUePage(
          ecoleId: widget.ecoleId,
          semestres: semestres,
        ),
      ),
    );
    if (!mounted) return;
    setState(() { _chargementUes = true; _erreurUes = null; });
    await _rechargerUes();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une UE'),
        backgroundColor: app.AppColors.red,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.creerEcue(widget.ecoleId, {
        'nom': _nomCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
        'credits': int.tryParse(_creditsCtrl.text) ?? 3,
        'volume_horaire': int.tryParse(_volCtrl.text) ?? 30,
        'type': _type,
        'niveau': _niveau,
        'ue_id': _ueId,
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvel ECUE'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                    message: 'L\'ECUE est la matière enseignée, rattachée à une UE.',
                    couleur: Colors.teal),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _nomCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Nom *', icon: Icons.menu_book_outlined),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _codeCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Code *', icon: Icons.tag),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.characters),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                        controller: _creditsCtrl,
                        style: const TextStyle(fontSize: 13.5),
                        keyboardType: TextInputType.number,
                        decoration: _deco('Crédits *', icon: Icons.star_outline),
                        validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                        controller: _volCtrl,
                        style: const TextStyle(fontSize: 13.5),
                        keyboardType: TextInputType.number,
                        decoration: _deco('Vol. horaire *', icon: Icons.timer_outlined),
                        validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type, // ← CORRECTION
                      decoration: _deco('Type', icon: Icons.category_outlined),
                      style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                      items: ['CM', 'TD', 'TP'].map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 13.5)))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _niveau, // ← CORRECTION
                      decoration: _deco('Niveau', icon: Icons.layers_outlined),
                      style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                      items: ['L1', 'L2', 'L3', 'M1', 'M2'].map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(n, style: const TextStyle(fontSize: 13.5)))).toList(),
                      onChanged: (v) => setState(() => _niveau = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                if (_chargementUes)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: app.AppColors.primary),
                        ),
                        SizedBox(width: 10),
                        Text('Chargement des UEs…',
                            style: TextStyle(fontSize: 13.5, color: app.AppColors.textSub)),
                      ],
                    ),
                  )
                else if (_erreurUes != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: app.AppColors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: app.AppColors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: app.AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_erreurUes!,
                            style: const TextStyle(color: app.AppColors.red, fontSize: 12))),
                        TextButton(
                          onPressed: () {
                            setState(() { _chargementUes = true; _erreurUes = null; });
                            _rechargerUes();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(_ues.length),
                          initialValue: _ueId, // ← CORRECTION
                          isExpanded: true,
                          decoration: _deco('UE *', icon: Icons.account_tree_outlined),
                          style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                          items: _ues.map((e) => DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(e['libelle'] ?? e['nom'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5)),
                          )).toList(),
                          onChanged: (v) => setState(() => _ueId = v),
                          validator: (v) => v == null ? 'Sélectionnez ou créez une UE' : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Créer une UE',
                        child: InkWell(
                          onTap: _creerNouvelleUe,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: app.AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: app.AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.add, color: app.AppColors.primary, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_loading || _chargementUes) ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer l\'ECUE',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER CLASSE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerClassePage extends StatefulWidget {
  final int ecoleId;
  final List<Map<String, dynamic>> filieres;
  final String anneeDefaut;
  const _CreerClassePage({
    required this.ecoleId,
    required this.filieres,
    required this.anneeDefaut,
  });
  @override
  State<_CreerClassePage> createState() => _CreerClassePageState();
}

class _CreerClassePageState extends State<_CreerClassePage> {
  final _formKey  = GlobalKey<FormState>();
  final _nomCtrl  = TextEditingController();
  final _codeCtrl = TextEditingController();
  late TextEditingController _anneeCtrl;
  final _coutCtrl = TextEditingController(text: '0');
  String _niveau  = 'L1';
  int? _filiereId;
  bool _loading   = false;

  @override
  void initState() {
    super.initState();
    _anneeCtrl = TextEditingController(
        text: widget.anneeDefaut.isNotEmpty ? widget.anneeDefaut : '2025-2026');
    if (widget.filieres.isNotEmpty) {
      _filiereId = widget.filieres.first['id'] as int;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _codeCtrl.dispose();
    _anneeCtrl.dispose(); _coutCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate() || _filiereId == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.creerClasse(widget.ecoleId, {
        'nom': _nomCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
        'niveau': _niveau,
        'filiere_id': _filiereId,
        'annee_academique': _anneeCtrl.text.trim(),
        'coutScolarite': double.tryParse(_coutCtrl.text) ?? 0,
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle classe'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                    message: 'La classe regroupe les étudiants d\'un même niveau et filière.',
                    couleur: Colors.purple),
                const SizedBox(height: 10),
                TextFormField(controller: _nomCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Nom *', icon: Icons.group_outlined),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.words),
                const SizedBox(height: 10),
                TextFormField(controller: _codeCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Code *', icon: Icons.tag),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.characters),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _niveau, // ← CORRECTION
                      decoration: _deco('Niveau', icon: Icons.layers_outlined),
                      style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                      items: ['L1', 'L2', 'L3', 'M1', 'M2'].map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(n, style: const TextStyle(fontSize: 13.5)))).toList(),
                      onChanged: (v) => setState(() => _niveau = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _filiereId, // ← CORRECTION
                      isExpanded: true,
                      decoration: _deco('Filière *', icon: Icons.folder_outlined),
                      style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                      items: widget.filieres.map((f) => DropdownMenuItem<int>(
                        value: f['id'] as int,
                        child: Text(f['nom'] ?? '', overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5)),
                      )).toList(),
                      onChanged: (v) => setState(() => _filiereId = v),
                      validator: (v) => v == null ? 'Obligatoire' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextFormField(controller: _anneeCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Année académique *', icon: Icons.calendar_today_outlined),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _coutCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    keyboardType: TextInputType.number,
                    decoration: _deco('Coût scolarité (FCFA)', icon: Icons.payments_outlined)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer la classe',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : CRÉER SALLE
// ══════════════════════════════════════════════════════════════════════════════

class _CreerSallePage extends StatefulWidget {
  final int ecoleId;
  const _CreerSallePage({required this.ecoleId});
  @override
  State<_CreerSallePage> createState() => _CreerSallePageState();
}

class _CreerSallePageState extends State<_CreerSallePage> {
  final _formKey  = GlobalKey<FormState>();
  final _nomCtrl  = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _capCtrl  = TextEditingController(text: '30');
  String _type    = 'salle';
  bool _loading   = false;

  @override
  void dispose() {
    _nomCtrl.dispose(); _codeCtrl.dispose(); _capCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13.5, color: app.AppColors.textSub),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: app.AppColors.primary) : null,
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: app.AppColors.primary, width: 1.6)),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
      );

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.creerSalle(widget.ecoleId, {
        'nom': _nomCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'capacite': int.tryParse(_capCtrl.text) ?? 30,
        'type': _type,
      });
      if (mounted) { Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: app.AppColors.red,
        ));
      }
    } finally {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = MediaQuery.of(context).size.width * 0.05;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle salle'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanniere(
                    message: 'La salle sera disponible pour planifier les cours.',
                    couleur: Colors.orange),
                const SizedBox(height: 14),
                TextFormField(controller: _nomCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Nom *', icon: Icons.meeting_room_outlined),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    textCapitalization: TextCapitalization.words),
                const SizedBox(height: 10),
                TextFormField(controller: _codeCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _deco('Code *', icon: Icons.tag),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextFormField(controller: _capCtrl,
                        style: const TextStyle(fontSize: 13.5),
                        keyboardType: TextInputType.number,
                        decoration: _deco('Capacité *', icon: Icons.people_outline),
                        validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type, // ← CORRECTION
                      decoration: _deco('Type', icon: Icons.category_outlined),
                      style: const TextStyle(fontSize: 13.5, color: app.AppColors.textMain),
                      items: ['salle', 'amphi', 'labo', 'salle_info'].map((t) =>
                          DropdownMenuItem(value: t,
                              child: Text(t, style: const TextStyle(fontSize: 13.5)))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Créer la salle',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET BANNIÈRE INFO
// ══════════════════════════════════════════════════════════════════════════════

class _InfoBanniere extends StatelessWidget {
  final String message;
  final Color couleur;
  const _InfoBanniere({required this.message, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: couleur, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: couleur),
            ),
          ),
        ],
      ),
    );
  }
}