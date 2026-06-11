import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/notes_model.dart';
import 'package:appliformulaire/services/notes_service.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/moyennes_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NoteService _service = NoteService();
  final _session = SessionUtilisateur();

  // Données
  List<NoteModel> _notes = [];
  List<DevoirModel> _devoirs = [];
  List<dynamic> _releves = [];
  List<dynamic> _absences = [];

  bool _loading = true;
  bool _loadingAbsences = false;
  bool _generatingReleve = false;
  String? _error;

  int _selectedSession = 1;
  bool? _filtreJustifiee;

  // Infos étudiant récupérées une fois
  int? _classeId;
  int? _semestreIdActif;
  List<dynamic> _semestres = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _absences.isEmpty && !_loadingAbsences) {
        _chargerAbsences();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _recupererContexte(ecoleId);

      final notes = await _service.getNotesEtudiant(
        ecoleId,
        session: _selectedSession,
      );
      final devoirs = await _service.getDevoirs(
        ecoleId,
        session: _selectedSession,
      );
      final releves = await _service.getRelevesList(ecoleId);

      setState(() {
        _notes = notes;
        _devoirs = devoirs;
        _releves = releves;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _loading = false;
      });
    }
  }

  Future<void> _recupererContexte(int ecoleId) async {
    try {
      final inscRes = await ApiService.getInscriptions(ecoleId);
      final inscriptions = inscRes['data'] as List? ?? [];
      dynamic inscValidee;
      for (final i in inscriptions) {
        final iId =
            i['etudiant_id'] as int? ?? (i['etudiant'] as Map?)?['id'] as int?;
        if (i['statut'] == 'validee' && iId == _session.id) {
          inscValidee = i;
          break;
        }
      }
      inscValidee ??= inscriptions.firstWhere(
        (i) => i['statut'] == 'validee',
        orElse: () => null,
      );
      if (inscValidee != null) _classeId = inscValidee['classe_id'] as int?;

      final semRes = await ApiService.getSemestres(ecoleId);
      _semestres = semRes['data'] as List? ?? [];
      if (_semestres.isNotEmpty)
        _semestreIdActif = _semestres.first['id'] as int;
    } catch (_) {}
  }

  Future<void> _chargerAbsences() async {
    setState(() {
      _loadingAbsences = true;
    });
    try {
      final params = <String, dynamic>{};
      if (_filtreJustifiee != null)
        params['justifiee'] = _filtreJustifiee! ? 1 : 0;
      final response = await ApiService.dio.get(
        '/api/ecoles/${_session.ecoleId}/absences',
        queryParameters: params,
      );
      List<dynamic> absences = (response.data['data'] as List? ?? [])
          .where((a) => a['present'] == false)
          .toList();

      if (_semestreIdActif != null) {
        absences = absences.where((a) {
          final cours = a['cours'] as Map<String, dynamic>?;
          return cours?['semestre_id'] == _semestreIdActif;
        }).toList();
      }

      setState(() {
        _absences = absences;
        _loadingAbsences = false;
      });
    } catch (e) {
      setState(() {
        _loadingAbsences = false;
      });
    }
  }

  Future<void> _genererReleve() async {
    if (_classeId == null || _semestreIdActif == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de générer : classe ou semestre introuvable.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    int sessionChoisie = _selectedSession;
    int? semestreChoisi = _semestreIdActif;

    final session = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Générer mon relevé'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_semestres.length > 1)
                DropdownButtonFormField<int>(
                  value: semestreChoisi,
                  decoration: const InputDecoration(
                    labelText: 'Semestre',
                    border: OutlineInputBorder(),
                  ),
                  items: _semestres
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text('Semestre ${s['numero'] ?? s['id']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      semestreChoisi = v;
                      setDialogState(() {});
                    }
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: sessionChoisie,
                decoration: const InputDecoration(
                  labelText: 'Session',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Session 1')),
                  DropdownMenuItem(value: 2, child: Text('Session 2')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    sessionChoisie = v;
                    setDialogState(() {});
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, sessionChoisie),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Générer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (session == null) return;
    setState(() => _generatingReleve = true);

    try {
      await _service.genererReleve(
        _session.ecoleId,
        etudiantId: _session.id,
        semestreId: semestreChoisi!,
        classeId: _classeId!,
        session: session,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relevé généré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
        _tabController.animateTo(3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingReleve = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Suivi Académique',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade_outlined, size: 20, color: Colors.white),
                  SizedBox(height: 3),
                  Text(
                    'Notes',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Devoirs',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Absences',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Relevés',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (val) {
              setState(() => _selectedSession = val);
              _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 1, child: Text('Session 1')),
              const PopupMenuItem(value: 2, child: Text('Session 2')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildDevoirsTab(),
                _buildAbsencesTab(),
                _buildRelevesTab(),
              ],
            ),
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: Color(0xFF90CAF9)),
            SizedBox(height: 16),
            Text(
              'Aucune note disponible',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            label: const Text(
              'Voir mes moyennes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoyennesScreen()),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _notes.length,
              itemBuilder: (_, index) => _buildNoteCard(_notes[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    final couleur = _getCouleurNote(note.noteSur20);
    final devoir = note.devoir;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: couleur, width: 2),
              ),
              child: Center(
                child: note.absent
                    ? const Text(
                        'ABS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      )
                    : Text(
                        note.noteSur20.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: couleur,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    devoir?.titre ?? 'Devoir',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    devoir?.ecue?.nom ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _tag(devoir?.type ?? '', Colors.blue),
                      const SizedBox(width: 6),
                      _tag('Session ${devoir?.session ?? 1}', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  note.valeur.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
                Text(
                  '/${devoir?.bareme.toStringAsFixed(0) ?? '20'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevoirsTab() {
    if (_devoirs.isEmpty) {
      return const Center(
        child: Text('Aucun devoir', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _devoirs.length,
        itemBuilder: (_, index) => _buildDevoirCard(_devoirs[index]),
      ),
    );
  }

  Widget _buildDevoirCard(DevoirModel devoir) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.assignment, color: Color(0xFF1565C0)),
        ),
        title: Text(
          devoir.titre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(devoir.ecue?.nom ?? ''),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _tag(devoir.type, Colors.blue),
                _tag('${devoir.bareme.toStringAsFixed(0)} pts', Colors.green),
                _tag('Session ${devoir.session}', Colors.purple),
              ],
            ),
          ],
        ),
        trailing: Text(
          devoir.dateEvaluation.length >= 10
              ? devoir.dateEvaluation.substring(0, 10)
              : devoir.dateEvaluation,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAbsencesTab() {
    final total = _absences.length;
    final justifiees = _absences.where((a) => a['justifiee'] == true).length;
    final nonJust = total - justifiees;

    return Column(
      children: [
        if (_semestres.length > 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButtonFormField<int>(
              value: _semestreIdActif,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Semestre',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: _semestres
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text('Semestre ${s['numero'] ?? s['id']}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _semestreIdActif = v);
                _chargerAbsences();
              },
            ),
          ),
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total', total.toString(), Colors.blue),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              _statItem('Justifiées', justifiees.toString(), Colors.green),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              _statItem('Non justifiées', nonJust.toString(), Colors.red),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _filtreChip('Toutes', null),
              const SizedBox(width: 8),
              _filtreChip('Justifiées', true),
              const SizedBox(width: 8),
              _filtreChip('Non justifiées', false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingAbsences
              ? const Center(child: CircularProgressIndicator())
              : _absences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune absence enregistrée',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerAbsences,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _absences.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        _buildCarteAbsence(_absences[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCarteAbsence(dynamic absence) {
    final cours = absence['cours'] as Map<String, dynamic>? ?? {};
    final ecue = cours['ecue'] as Map<String, dynamic>? ?? {};
    final justifiee = absence['justifiee'] == true;
    final typeJust = absence['type_justification'] as String?;
    final observation = absence['observation'] as String?;
    final justifiePar = absence['justifie_par'] as Map<String, dynamic>?;
    final nomJust = justifiePar != null
        ? (justifiePar['full_name'] ??
              '${justifiePar['first_name'] ?? ''} ${justifiePar['last_name'] ?? ''}'
                  .trim())
        : null;
    final date = cours['date_cours'] as String? ?? '';
    final heureDebut = cours['heure_debut'] as String?;
    final heureFin = cours['heure_fin'] as String?;
    final couleur = justifiee ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: justifiee ? Colors.green.shade200 : Colors.red.shade100,
        ),
      ),
      elevation: 1,
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
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    justifiee ? Icons.check_circle : Icons.cancel_outlined,
                    color: couleur,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ecue['nom'] as String? ?? 'ECUE inconnue',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ecue['code'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    justifiee
                        ? (typeJust == 'permission'
                              ? 'Permission'
                              : 'Justifiée')
                        : 'Non justifiée',
                    style: TextStyle(
                      color: couleur,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (heureDebut != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '$heureDebut — $heureFin',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
            if (observation != null && observation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '📝 $observation',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            if (justifiee && nomJust != null && nomJust.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 13,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Justifié par : $nomJust',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filtreChip(String label, bool? value) {
    final selected = _filtreJustifiee == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filtreJustifiee = value);
        _chargerAbsences();
      },
      selectedColor: const Color(0xFF1565C0).withOpacity(0.15),
      checkmarkColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1565C0) : Colors.grey.shade700,
        fontSize: 12,
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildRelevesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _generatingReleve
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              _generatingReleve
                  ? 'Génération en cours...'
                  : 'Générer un relevé',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _generatingReleve ? null : _genererReleve,
          ),
        ),
        Expanded(
          child: _releves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Color(0xFF90CAF9),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun relevé disponible',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cliquez sur "Générer un relevé" ci-dessus',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _releves.length,
                    itemBuilder: (_, index) {
                      final releve = _releves[index];
                      final semestre =
                          releve['semestre'] as Map<String, dynamic>? ?? {};
                      final numero =
                          semestre['numero'] ?? releve['semestre_id'];
                      final session = releve['session'];
                      final date =
                          (releve['created_at'] as String? ?? '').length >= 10
                          ? (releve['created_at'] as String).substring(0, 10)
                          : '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFF1565C0),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            'Semestre $numero — Session $session',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Généré le $date',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Color(0xFF1565C0),
                            ),
                            onPressed: () {
                              final url = ApiService.getTelechargementReleveUrl(
                                _session.ecoleId,
                                releve['id'],
                                token: _session.token,
                              );
                              launchUrl(Uri.parse(url));
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCouleurNote(double note) {
    if (note >= 14) return Colors.green;
    if (note >= 10) return Colors.orange;
    return Colors.red;
  }
}
