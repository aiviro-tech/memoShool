import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/services/api_service.dart';

class FormulaireCoursPage extends StatefulWidget {
  final int ecoleId;
  final CoursModel? cours; // null = création

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

  // Données des listes déroulantes
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _salles = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _enseignants = [];
  List<Map<String, dynamic>> _filieres = [];

  // Valeurs sélectionnées
  int? _matiereId;
  int? _salleId;
  int? _classeId;
  int? _enseignantId;
  String _semestre = 'S1';

  // Controllers
  late TextEditingController _dateCtrl;
  late TextEditingController _heureDebutCtrl;
  late TextEditingController _heureFinCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _anneeCtrl;

  @override
  void initState() {
    super.initState();

    final c = widget.cours;
    _dateCtrl = TextEditingController(text: c?.dateCours ?? '');
    _heureDebutCtrl = TextEditingController(text: c?.heureDebut ?? '');
    _heureFinCtrl = TextEditingController(text: c?.heureFin ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _anneeCtrl = TextEditingController(text: c?.anneeAcademique ?? '');
    _semestre = c?.semestre ?? 'S1';

    _chargerDonnees();
  }

  /// Pré-remplir les IDs des dropdowns après chargement des données (mode édition)
  void _preremplirEdition() {
    final c = widget.cours;
    if (c == null) return;

    // On cherche les IDs correspondants dans les listes chargées
    // L'API retourne les objets liés, donc on peut recouper par nom
    for (final m in _matieres) {
      if (m['nom'] == c.matiere || m['code'] == c.matiereCode) {
        _matiereId = m['id'] as int;
        break;
      }
    }
    for (final e in _enseignants) {
      final fullName = e['full_name'] ?? '${e['first_name']} ${e['last_name']}';
      if (e['id'] == c.enseignantId || fullName == c.enseignant) {
        _enseignantId = e['id'] as int;
        break;
      }
    }
    for (final cl in _classes) {
      if (cl['nom'] == c.classe) {
        _classeId = cl['id'] as int;
        break;
      }
    }
    for (final s in _salles) {
      if (s['nom'] == c.salle || s['code'] == c.salleCode) {
        _salleId = s['id'] as int;
        break;
      }
    }
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
        ApiService.getMatieres(widget.ecoleId),
        ApiService.getClasses(widget.ecoleId),
        ApiService.getEnseignants(widget.ecoleId),
        ApiService.getSalles(widget.ecoleId),
        ApiService.getFilieres(widget.ecoleId),
      ]);

      final matiereData = results[0] as Map<String, dynamic>;
      final classeData = results[1] as Map<String, dynamic>;
      final enseignantData = results[2] as List<dynamic>;
      final salleData = results[3] as Map<String, dynamic>;
      final filiereData = results[4] as Map<String, dynamic>;

      setState(() {
        _matieres = List<Map<String, dynamic>>.from(matiereData['data'] ?? []);
        _classes = List<Map<String, dynamic>>.from(classeData['data'] ?? []);
        _enseignants = List<Map<String, dynamic>>.from(enseignantData);
        _salles = List<Map<String, dynamic>>.from(salleData['data'] ?? []);
        _filieres = List<Map<String, dynamic>>.from(filiereData['data'] ?? []);
        _chargementDonnees = false;

        // Pré-remplir les IDs si mode édition
        _preremplirEdition();
      });
    } catch (e) {
      setState(() => _chargementDonnees = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement donnees : ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  /// Si aucune filière n'existe, demande à l'admin d'en créer une
  Future<void> _demanderCreerFiliere() async {
    if (_filieres.isNotEmpty) return;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Aucune filière', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Vous devez d\'abord créer au moins une filière pour pouvoir continuer.\n\n'
          'Cliquez sur "Créer" pour ajouter une filière.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer une filière'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _creerFiliere();
    }
  }

  Future<void> _creerFiliere() async {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Nouvelle filière', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'ex: Sciences de l\'Ingénieur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Code *',
                hintText: 'ex: SI',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (result != true || nomCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
    try {
      await ApiService.creerFiliere(widget.ecoleId, {
        'nom': nomCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
      });
      await _chargerDonnees();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filière créée'),
            backgroundColor: AppColors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
    }
  }

  Future<void> _creerMatiere() async {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    final volumeCtrl = TextEditingController(text: '30');
    String type = 'CM';
    String niveau = 'L1';
    bool troncCommun = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Nouvelle matière', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Code *',
                    hintText: 'ex: MATH101',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: creditsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Crédits *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: volumeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Vol. horaire *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['CM', 'TD', 'TP']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setS(() => type = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: niveau,
                        decoration: const InputDecoration(
                          labelText: 'Niveau',
                          border: OutlineInputBorder(),
                        ),
                        items: ['L1', 'L2', 'L3', 'M1', 'M2']
                            .map(
                              (n) => DropdownMenuItem(value: n, child: Text(n)),
                            )
                            .toList(),
                        onChanged: (v) => setS(() => niveau = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tronc commun ?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Oui'),
                      selected: troncCommun,
                      onSelected: (selected) =>
                          setS(() => troncCommun = selected),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Non'),
                      selected: !troncCommun,
                      onSelected: (selected) =>
                          setS(() => troncCommun = !selected),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (result != true || nomCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
    try {
      await ApiService.creerMatiere(widget.ecoleId, {
        'nom': nomCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'credits': int.tryParse(creditsCtrl.text) ?? 3,
        'volume_horaire': int.tryParse(volumeCtrl.text) ?? 30,
        'type': type,
        'niveau': niveau,
        if (!troncCommun) 'tronc_commun': true,
      });
      await _chargerDonnees();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matière créée'),
            backgroundColor: AppColors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
    }
  }

  Future<void> _creerClasse() async {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final anneeCtrl = TextEditingController(text: _anneeCtrl.text);
    String niveau = 'L1';
    int? filiereId;

    // Si pas de filières, proposer d'en créer automatiquement
    if (_filieres.isEmpty) {
      await _demanderCreerFiliere();
      if (_filieres.isEmpty) return; // L'utilisateur a refusé
    }

    filiereId = _filieres.first['id'] as int;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Nouvelle classe', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'ex: L1 Info A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Code *',
                    hintText: 'ex: L1-INFO-A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: niveau,
                  decoration: const InputDecoration(
                    labelText: 'Niveau',
                    border: OutlineInputBorder(),
                  ),
                  items: ['L1', 'L2', 'L3', 'M1', 'M2']
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) => setS(() => niveau = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: filiereId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filière *',
                    border: OutlineInputBorder(),
                  ),
                  items: _filieres
                      .map(
                        (f) => DropdownMenuItem<int>(
                          value: f['id'] as int,
                          child: Text(f['nom'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => filiereId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: anneeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Année académique *',
                    hintText: '2024-2025',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (result != true ||
        nomCtrl.text.isEmpty ||
        codeCtrl.text.isEmpty ||
        filiereId == null)
      return;
    try {
      await ApiService.creerClasse(widget.ecoleId, {
        'nom': nomCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'niveau': niveau,
        'filiere_id': filiereId,
        'annee_academique': anneeCtrl.text.trim(),
      });
      await _chargerDonnees();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classe créée'),
            backgroundColor: AppColors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
    }
  }

  Future<void> _creerSalle() async {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '30');
    String type = 'salle';
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Nouvelle salle', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'ex: Salle 101',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  hintText: 'ex: S101',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['salle', 'amphi', 'labo', 'salle_info']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => type = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (result != true || nomCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
    try {
      await ApiService.creerSalle(widget.ecoleId, {
        'nom': nomCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'capacite': int.tryParse(capCtrl.text) ?? 30,
        'type': type,
      });
      await _chargerDonnees();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle créée'),
            backgroundColor: AppColors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
    }
  }

  Future<void> _selectionnerDate() async {
    // pas besoin de mettre locale ici car MaterialApp gere deja ca
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (heure != null) {
      ctrl.text =
          '${heure.hour.toString().padLeft(2, '0')}:${heure.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validations manuelles des dropdowns
    if (_matiereId == null ||
        _salleId == null ||
        _classeId == null ||
        _enseignantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _chargement = true);

    final data = {
      'matiere_id': _matiereId,
      'salle_id': _salleId,
      'classe_id': _classeId,
      'enseignant_id': _enseignantId,
      'date_cours': _dateCtrl.text.trim(),
      'heure_debut': _heureDebutCtrl.text.trim(),
      'heure_fin': _heureFinCtrl.text.trim(),
      'semestre': _semestre,
      'annee_academique': _anneeCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    try {
      if (widget.cours == null) {
        await ApiService.creerCours(widget.ecoleId, data);
      } else {
        await ApiService.modifierCours(widget.ecoleId, widget.cours!.id, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.cours == null
                  ? 'Cours créé avec succès'
                  : 'Cours modifié avec succès',
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estModif = widget.cours != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(estModif ? 'Modifier le cours' : 'Nouveau cours'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargementDonnees
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des données...',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Matiere
                    _DropdownChamp<int>(
                      label: 'Matière *',
                      icone: Icons.menu_book_outlined,
                      valeur: _matiereId,
                      items: _matieres
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m['id'] as int,
                              child: Text(
                                '${m['nom']} (${m['code']})',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _matiereId = v),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Créer une matière',
                            onPressed: _creerMatiere,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.folder_open,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                            tooltip: 'Créer une filière',
                            onPressed: _creerFiliere,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Enseignant
                    _DropdownChamp<int>(
                      label: 'Enseignant *',
                      icone: Icons.person_outline,
                      valeur: _enseignantId,
                      items: _enseignants
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e['id'] as int,
                              child: Text(
                                e['full_name'] ??
                                    '${e['first_name']} ${e['last_name']}',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _enseignantId = v),
                    ),
                    const SizedBox(height: 14),

                    // Classe
                    _DropdownChamp<int>(
                      label: 'Classe *',
                      icone: Icons.school_outlined,
                      valeur: _classeId,
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(
                                '${c['nom']} (${c['code']})',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _classeId = v),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Créer une classe',
                        onPressed: _creerClasse,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Salle
                    _DropdownChamp<int>(
                      label: 'Salle *',
                      icone: Icons.location_on_outlined,
                      valeur: _salleId,
                      items: _salles
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text(
                                '${s['nom']} (cap. ${s['capacite']})',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _salleId = v),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Chercher salles disponibles',
                            onPressed:
                                _dateCtrl.text.isNotEmpty &&
                                    _heureDebutCtrl.text.isNotEmpty &&
                                    _heureFinCtrl.text.isNotEmpty
                                ? () => _chargerSallesDisponibles()
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Creer une salle',
                            onPressed: _creerSalle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Remplissez date et horaires, puis cliquez sur la loupe pour voir les salles libres',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 14),

                    // Date
                    GestureDetector(
                      onTap: _selectionnerDate,
                      child: AbsorbPointer(
                        child: _ChampTexte(
                          label: 'Date du cours *',
                          controller: _dateCtrl,
                          icone: Icons.calendar_today_outlined,
                          hintText: 'Toucher pour sélectionner',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Horaires
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectionnerHeure(_heureDebutCtrl),
                            child: AbsorbPointer(
                              child: _ChampTexte(
                                label: 'Début *',
                                controller: _heureDebutCtrl,
                                icone: Icons.access_time_outlined,
                                hintText: '08:00',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectionnerHeure(_heureFinCtrl),
                            child: AbsorbPointer(
                              child: _ChampTexte(
                                label: 'Fin *',
                                controller: _heureFinCtrl,
                                icone: Icons.access_time_outlined,
                                hintText: '10:00',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Semestre
                    _DropdownChamp<String>(
                      label: 'Semestre *',
                      icone: Icons.category_outlined,
                      valeur: _semestre,
                      items:
                          [
                                'S1',
                                'S2',
                                'S3',
                                'S4',
                                'S5',
                                'S6',
                                'S7',
                                'S8',
                                'S9',
                                'S10',
                              ]
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _semestre = v!),
                    ),
                    const SizedBox(height: 14),

                    // Année académique
                    _ChampTexte(
                      label: 'Année académique *',
                      controller: _anneeCtrl,
                      icone: Icons.calendar_month_outlined,
                      hintText: 'ex: 2024-2025',
                      obligatoire: true,
                    ),
                    const SizedBox(height: 14),

                    // Notes (optionnel)
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (optionnel)',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes_outlined, size: 18),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Bouton soumettre
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _chargement ? null : _enregistrer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _chargement
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                estModif
                                    ? 'Enregistrer les modifications'
                                    : 'Créer le cours',
                                style: const TextStyle(fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_salles.length} salle(s) disponible(s) trouvée(s)',
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }
}

// Widgets réutilisables du formulaire
class _DropdownChamp<T> extends StatelessWidget {
  final String label;
  final IconData icone;
  final T? valeur;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final Widget? trailing;

  const _DropdownChamp({
    required this.label,
    required this.icone,
    required this.valeur,
    required this.items,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            key: ValueKey('${label}_$valeur'),
            initialValue: valeur,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icone, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ChampTexte extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icone;
  final String? hintText;
  final bool obligatoire;

  const _ChampTexte({
    required this.label,
    required this.controller,
    this.icone,
    this.hintText,
    this.obligatoire = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icone != null ? Icon(icone, size: 18) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      validator: obligatoire
          ? (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null
          : null,
    );
  }
}
