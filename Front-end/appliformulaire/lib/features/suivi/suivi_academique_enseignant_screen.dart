import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/notes_model.dart';
import 'package:appliformulaire/services/notes_service.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/notes/creer_devoir_screen.dart';

class SuiviAcademiqueEnseignantScreen extends StatefulWidget {
  const SuiviAcademiqueEnseignantScreen({super.key});

  @override
  State<SuiviAcademiqueEnseignantScreen> createState() =>
      _SuiviAcademiqueEnseignantScreenState();
}

class _SuiviAcademiqueEnseignantScreenState
    extends State<SuiviAcademiqueEnseignantScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _session = SessionUtilisateur();
  final _service = NoteService();

  // ── Onglet Notes ──────────────────────────────────────────────────────────
  List<DevoirModel> _devoirs = [];
  int? _selectedDevoirId;
  DevoirModel? _selectedDevoir;
  List<Map<String, dynamic>> _etudiants = [];
  final Map<int, TextEditingController> _noteControllers = {};
  final Map<int, bool> _absentStatus = {};
  bool _loadingDevoirs = true;
  bool _chargementEtudiants = false;
  bool _enregistrementNotes = false;
  int? _semestreId;

  // ── Onglet Présences ──────────────────────────────────────────────────────
  List<dynamic> _cours = [];
  int? _selectedCoursId;
  List<Map<String, dynamic>> _etudiantsPresences = [];
  final Map<int, bool> _presences = {};
  final Map<int, TextEditingController> _observationControllers = {};
  bool _loadingCours = true;
  bool _chargementPresences = false;
  bool _enregistrementPresences = false;

  // Absences du cours sélectionné
  List<dynamic> _absencesCours = [];
  bool _chargementAbsences = false;
  bool? _filtreJustifiee;
  int? _coursAbsencesId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDevoirs();
    _chargerCours();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _noteControllers.values) {
      c.dispose();
    }
    for (var c in _observationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // NOTES
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _chargerDevoirs() async {
    setState(() {
      _loadingDevoirs = true;
    });
    try {
      final devoirs = await _service.getDevoirsEnseignant(_session.ecoleId);
      setState(() {
        _devoirs = devoirs;
        _loadingDevoirs = false;
      });
    } catch (e) {
      setState(() {
        _loadingDevoirs = false;
      });
    }
  }

  Future<int?> _recupererSemestreId(int devoirId) async {
    try {
      final res = await ApiService.getDevoirs(_session.ecoleId);
      final list = res['data'] as List? ?? [];
      final d = list.firstWhere((d) => d['id'] == devoirId, orElse: () => null);
      if (d == null) {
        return null;
      }
      final ecue = d['ecue'] as Map<String, dynamic>?;
      final ue = ecue?['ue'] as Map<String, dynamic>?;
      return ue?['semestre_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _chargerEtudiantsPourDevoir() async {
    if (_selectedDevoirId == null) {
      return;
    }
    setState(() {
      _chargementEtudiants = true;
    });
    try {
      final ecoleId = _session.ecoleId;
      final devoir = _devoirs.firstWhere((d) => d.id == _selectedDevoirId);
      _selectedDevoir = devoir;
      _semestreId = await _recupererSemestreId(devoir.id);

      final inscRes = await ApiService.getInscriptions(
        ecoleId,
        statut: 'validee',
      );
      final inscriptions = (inscRes['data'] as List? ?? [])
          .where((i) => i['classe_id'] == devoir.classeId)
          .toList();

      final Map<int, dynamic> notesByEtudiant = {};
      for (var ins in inscriptions) {
        final e = ins['etudiant'] as Map<String, dynamic>? ?? {};
        final eId = e['id'];
        if (eId != null) {
          try {
            final notesRes = await ApiService.getNotesEtudiant(
              ecoleId,
              etudiantId: eId,
            );
            final notesList = notesRes['data'] as List? ?? [];
            for (var n in notesList) {
              if (n['devoir_id'] == devoir.id) {
                notesByEtudiant[eId] = n;
                break;
              }
            }
          } catch (_) {}
        }
      }

      _noteControllers.clear();
      _absentStatus.clear();
      final liste = <Map<String, dynamic>>[];

      for (var ins in inscriptions) {
        final e = ins['etudiant'] as Map<String, dynamic>? ?? {};
        final userId = e['id'] as int?;
        if (userId == null) {
          continue;
        }
        final nom =
            e['full_name'] ??
            '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
        final noteExistante = notesByEtudiant[userId];
        final ctrl = TextEditingController();
        if (noteExistante != null && !(noteExistante['absent'] ?? false)) {
          final v = noteExistante['valeur'];
          if (v != null) {
            ctrl.text = v.toString();
          }
        }
        _noteControllers[userId] = ctrl;
        _absentStatus[userId] = noteExistante?['absent'] ?? false;
        liste.add({'id': userId, 'nom': nom});
      }

      setState(() {
        _etudiants = liste;
        _chargementEtudiants = false;
      });
    } catch (e) {
      setState(() {
        _chargementEtudiants = false;
      });
    }
  }

  Future<void> _enregistrerNotes() async {
    if (_selectedDevoir == null) {
      return;
    }
    setState(() => _enregistrementNotes = true);

    final notes = _etudiants.map((e) {
      final userId = e['id'] as int;
      final estAbsent = _absentStatus[userId] ?? false;
      final valeur = double.tryParse(_noteControllers[userId]?.text ?? '');
      return {
        'etudiant_id': userId,
        'valeur': estAbsent ? 0 : (valeur ?? 0),
        'absent': estAbsent,
        'observation': estAbsent ? 'Absent' : null,
      };
    }).toList();

    try {
      await _service.saisirNotes(
        _session.ecoleId,
        _selectedDevoir!.id,
        notes,
        semestreId: _semestreId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes enregistrées avec succès'),
            backgroundColor: app.AppColors.green,
          ),
        );
        _chargerEtudiantsPourDevoir();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enregistrementNotes = false);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRÉSENCES
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _chargerCours() async {
    setState(() {
      _loadingCours = true;
    });
    try {
      final res = await ApiService.getCours(_session.ecoleId);
      final tous = res['data'] as List? ?? [];
      setState(() {
        _cours = tous.where((c) => c['enseignant_id'] == _session.id).toList();
        _loadingCours = false;
      });
    } catch (_) {
      setState(() {
        _loadingCours = false;
      });
    }
  }

  Future<void> _chargerEtudiantsCours() async {
    if (_selectedCoursId == null) {
      return;
    }
    setState(() {
      _chargementPresences = true;
    });
    try {
      final ecoleId = _session.ecoleId;
      final cours = _cours.firstWhere((c) => c['id'] == _selectedCoursId);
      final classeId = cours['classe_id'];

      final inscRes = await ApiService.getInscriptions(
        ecoleId,
        statut: 'validee',
      );
      final inscriptions = (inscRes['data'] as List? ?? [])
          .where((i) => i['classe_id'] == classeId)
          .toList();

      final presRes = await ApiService.getPresencesCours(
        ecoleId,
        _selectedCoursId!,
      );
      final presences = presRes['data'] as List? ?? [];

      final Map<int, bool> presExistantes = {};
      final Map<int, String> obsExistantes = {};
      for (var p in presences) {
        final id = p['etudiant_id'] as int?;
        if (id != null) {
          presExistantes[id] = p['present'] == true;
          obsExistantes[id] = p['observation'] ?? '';
        }
      }

      for (var c in _observationControllers.values) {
        c.dispose();
      }
      _observationControllers.clear();
      _presences.clear();

      final liste = <Map<String, dynamic>>[];
      for (var ins in inscriptions) {
        final e = ins['etudiant'] as Map<String, dynamic>? ?? {};
        final userId = e['id'] as int?;
        if (userId == null) {
          continue;
        }
        final nom =
            e['full_name'] ??
            '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
        liste.add({'id': userId, 'nom': nom});
        _presences[userId] = presExistantes[userId] ?? true;
        _observationControllers[userId] = TextEditingController(
          text: obsExistantes[userId] ?? '',
        );
      }

      setState(() {
        _etudiantsPresences = liste;
        _chargementPresences = false;
      });
    } catch (_) {
      setState(() {
        _chargementPresences = false;
      });
    }
  }

  Future<void> _enregistrerPresences() async {
    if (_selectedCoursId == null || _etudiantsPresences.isEmpty) {
      return;
    }
    setState(() => _enregistrementPresences = true);

    final data = _etudiantsPresences.map((e) {
      final userId = e['id'] as int;
      return {
        'etudiant_id': userId,
        'present': _presences[userId] ?? true,
        'observation': _observationControllers[userId]?.text.isNotEmpty == true
            ? _observationControllers[userId]!.text
            : null,
      };
    }).toList();

    try {
      await ApiService.saisirPresences(
        _session.ecoleId,
        _selectedCoursId!,
        data,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présences enregistrées avec succès'),
            backgroundColor: app.AppColors.green,
          ),
        );
        await _chargerEtudiantsCours();
        await _chargerAbsencesCours(_selectedCoursId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enregistrementPresences = false);
      }
    }
  }

  Future<void> _chargerAbsencesCours(int coursId) async {
    setState(() {
      _chargementAbsences = true;
      _coursAbsencesId = coursId;
    });
    try {
      final res = await ApiService.getPresencesCours(_session.ecoleId, coursId);
      final toutes = res['data'] as List? ?? [];
      var absences = toutes.where((a) => a['present'] == false).toList();
      if (_filtreJustifiee != null) {
        absences = absences
            .where((a) => (a['justifiee'] == true) == _filtreJustifiee)
            .toList();
      }
      setState(() {
        _absencesCours = absences;
        _chargementAbsences = false;
      });
    } catch (_) {
      setState(() {
        _chargementAbsences = false;
      });
    }
  }

  Future<void> _justifierAbsence(dynamic absence) async {
    String typeJustification = 'justificatif';
    final obsCtrl = TextEditingController(text: absence['observation'] ?? '');

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Justifier l\'absence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type de justification',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _typeBtn(
                      'justificatif',
                      'Justificatif',
                      typeJustification,
                      (v) {
                        setD(() => typeJustification = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _typeBtn(
                      'permission',
                      'Permission',
                      typeJustification,
                      (v) {
                        setD(() => typeJustification = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observation (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
              style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.green),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirme != true) {
      return;
    }
    try {
      await ApiService.justifierAbsence(
        _session.ecoleId,
        absence['id'] as int,
        typeJustification: typeJustification,
        observation: obsCtrl.text.isNotEmpty ? obsCtrl.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absence justifiée'),
            backgroundColor: app.AppColors.green,
          ),
        );
        if (_coursAbsencesId != null) {
          _chargerAbsencesCours(_coursAbsencesId!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  Widget _typeBtn(
    String value,
    String label,
    String current,
    void Function(String) onTap,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? app.AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? app.AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Suivi Académique',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task, color: Colors.white),
            tooltip: 'Créer un devoir',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreerDevoirScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: const [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade_outlined, size: 22, color: Colors.white),
                  SizedBox(height: 3),
                  Text(
                    'Notes',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist_rounded, size: 22, color: Colors.white),
                  SizedBox(height: 3),
                  Text(
                    'Présences',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOngletNotes(), _buildOngletPresences()],
      ),
    );
  }

  // ── ONGLET NOTES ──────────────────────────────────────────────────────────
  Widget _buildOngletNotes() {
    if (_loadingDevoirs) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sélection devoir
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionner un devoir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selectedDevoirId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: 'Choisir un devoir...',
                  ),
                  items: _devoirs.map((d) {
                    return DropdownMenuItem<int>(
                      value: d.id,
                      child: Text(
                        '${d.titre} — ${d.ecue?.nom ?? ''} (${d.type})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedDevoirId = v;
                      _etudiants = [];
                    });
                    if (v != null) {
                      _chargerEtudiantsPourDevoir();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _chargementEtudiants
              ? const Center(child: CircularProgressIndicator())
              : _etudiants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedDevoirId == null
                            ? 'Sélectionnez un devoir'
                            : 'Aucun étudiant dans cette classe',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildTableauNotes(),
        ),
        if (_selectedDevoir != null && _etudiants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: app.AppColors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _enregistrementNotes
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _enregistrementNotes
                    ? 'Enregistrement...'
                    : 'Enregistrer les notes',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: _enregistrementNotes ? null : _enregistrerNotes,
            ),
          ),
      ],
    );
  }

  Widget _buildTableauNotes() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _etudiants.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final e = _etudiants[index];
        final userId = e['id'] as int;
        final estAbsent = _absentStatus[userId] ?? false;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e['nom'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _noteControllers[userId],
                    keyboardType: TextInputType.number,
                    enabled: !estAbsent,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixText:
                          '/${_selectedDevoir?.bareme.toStringAsFixed(0) ?? '20'}',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Absent',
                      style: TextStyle(
                        fontSize: 12,
                        color: estAbsent ? Colors.red : Colors.grey,
                      ),
                    ),
                    Checkbox(
                      value: estAbsent,
                      activeColor: Colors.red,
                      onChanged: (v) {
                        setState(() {
                          _absentStatus[userId] = v ?? false;
                          if (v == true) {
                            _noteControllers[userId]?.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ONGLET PRÉSENCES ──────────────────────────────────────────────────────
  Widget _buildOngletPresences() {
    if (_loadingCours) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sélection cours
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionner un cours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selectedCoursId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: 'Choisir un cours...',
                  ),
                  items: _cours.map((c) {
                    final ecue = c['ecue'] as Map<String, dynamic>? ?? {};
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(
                        '${ecue['nom'] ?? 'Cours'} — ${c['date_cours'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCoursId = v;
                      _etudiantsPresences = [];
                      _absencesCours = [];
                    });
                    if (v != null) {
                      _chargerEtudiantsCours();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        // Actions rapides si étudiants chargés
        if (_etudiantsPresences.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_presences.values.where((v) => v).length} / ${_etudiantsPresences.length} présent(s)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Tous présents'),
                  onPressed: () {
                    setState(() {
                      for (var e in _etudiantsPresences) {
                        _presences[e['id'] as int] = true;
                      }
                    });
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Tous absents'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      for (var e in _etudiantsPresences) {
                        _presences[e['id'] as int] = false;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: _chargementPresences
              ? const Center(child: CircularProgressIndicator())
              : _etudiantsPresences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedCoursId == null
                            ? 'Sélectionnez un cours'
                            : 'Aucun étudiant inscrit',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildListePresences(),
        ),
        // Bouton enregistrer
        if (_selectedCoursId != null && _etudiantsPresences.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: app.AppColors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _enregistrementPresences
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _enregistrementPresences
                    ? 'Enregistrement...'
                    : 'Enregistrer les présences',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: _enregistrementPresences
                  ? null
                  : _enregistrerPresences,
            ),
          ),
        // Section absences à justifier
        if (_absencesCours.isNotEmpty || _coursAbsencesId != null)
          _buildSectionAbsences(),
      ],
    );
  }

  Widget _buildListePresences() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _etudiantsPresences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final e = _etudiantsPresences[index];
        final userId = e['id'] as int;
        final estPresent = _presences[userId] ?? true;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: estPresent ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: estPresent ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e['nom'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      estPresent ? 'Présent' : 'Absent',
                      style: TextStyle(
                        color: estPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Switch(
                      value: estPresent,
                      activeThumbColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.shade100,
                      onChanged: (v) => setState(() => _presences[userId] = v),
                    ),
                  ],
                ),
                if (!estPresent) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _observationControllers[userId],
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Motif / observation (optionnel)',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      isDense: true,
                      fillColor: Colors.red.shade50,
                      filled: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionAbsences() {
    if (_chargementAbsences) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    final total = _absencesCours.length;
    final justifiees = _absencesCours
        .where((a) => a['justifiee'] == true)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Absences du cours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '$total absence(s) · $justifiees justifiée(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _filtreChip('Toutes', null),
              const SizedBox(width: 6),
              _filtreChip('Justifiées', true),
              const SizedBox(width: 6),
              _filtreChip('Non justifiées', false),
            ],
          ),
          const SizedBox(height: 10),
          if (_absencesCours.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Aucune absence',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._absencesCours.map((a) => _buildCarteAbsence(a)),
        ],
      ),
    );
  }

  Widget _filtreChip(String label, bool? value) {
    final selected = _filtreJustifiee == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) {
        setState(() => _filtreJustifiee = value);
        if (_coursAbsencesId != null) {
          _chargerAbsencesCours(_coursAbsencesId!);
        }
      },
      selectedColor: app.AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: app.AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? app.AppColors.primary : Colors.grey.shade700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildCarteAbsence(dynamic absence) {
    final etudiant = absence['etudiant'] as Map<String, dynamic>? ?? {};
    final nom =
        etudiant['full_name'] ??
        '${etudiant['first_name'] ?? ''} ${etudiant['last_name'] ?? ''}'.trim();
    final justifiee = absence['justifiee'] == true;
    final typeJust = absence['type_justification'] as String?;
    final observation = absence['observation'] as String?;
    final couleur = justifiee ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            justifiee ? Icons.check_circle : Icons.cancel_outlined,
            color: couleur,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom.isNotEmpty ? nom : 'Étudiant',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (observation != null && observation.isNotEmpty)
                  Text(
                    '📝 $observation',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (justifiee)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                typeJust == 'permission' ? 'Permission' : 'Justifiée',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _justifierAbsence(absence),
              child: const Text('Justifier', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}