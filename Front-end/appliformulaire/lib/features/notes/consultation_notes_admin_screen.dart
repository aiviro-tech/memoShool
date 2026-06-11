import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/notes_model.dart';
import 'package:appliformulaire/services/notes_service.dart';
import 'package:appliformulaire/services/api_service.dart';

class ConsultationNotesAdminScreen extends StatefulWidget {
  const ConsultationNotesAdminScreen({super.key});

  @override
  State<ConsultationNotesAdminScreen> createState() =>
      _ConsultationNotesAdminScreenState();
}

class _ConsultationNotesAdminScreenState
    extends State<ConsultationNotesAdminScreen> {
  final NoteService _service = NoteService();
  final _session = SessionUtilisateur();

  List<DevoirModel> _devoirs  = [];
  List<dynamic>     _classes  = [];
  List<dynamic>     _ecues    = [];

  int?          _selectedDevoirId;
  DevoirModel?  _selectedDevoir;
  List<Map<String, dynamic>> _etudiants = [];
  Map<int, dynamic> _notesByEtudiant    = {};

  bool   _loading         = true;
  bool   _chargementNotes = false;
  String? _error;

  int? _filtreClasseId;
  int? _filtreEcueId;
  int? _filtreSession;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ecoleId    = _session.ecoleId;
      final devoirsRes = await _service.getDevoirs(ecoleId);
      final classesRes = await ApiService.getClasses(ecoleId);
      final ecuesRes   = await ApiService.getEcues(ecoleId);
      setState(() {
        _devoirs = devoirsRes;
        _classes = classesRes['data'] as List? ?? [];
        _ecues   = ecuesRes['data']   as List? ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Erreur : $e'; _loading = false; });
    }
  }

  Future<void> _chargerNotesPourDevoir() async {
    if (_selectedDevoirId == null) return;
    setState(() { _chargementNotes = true; });
    try {
      final ecoleId = _session.ecoleId;
      final devoir  = _devoirs.firstWhere((d) => d.id == _selectedDevoirId);
      _selectedDevoir = devoir;

      final inscriptionsRes = await ApiService.getInscriptions(ecoleId, statut: 'validee');
      final inscriptions    = (inscriptionsRes['data'] as List? ?? [])
          .where((ins) => ins['classe_id'] == devoir.classeId)
          .toList();

      final etudiantsList   = <Map<String, dynamic>>[];
      final notesMap        = <int, dynamic>{};

      for (var ins in inscriptions) {
        final etudiant   = ins['etudiant'] as Map<String, dynamic>? ?? {};
        final etudiantId = etudiant['id'] as int?;
        if (etudiantId == null) continue;

        final nom = etudiant['full_name'] ??
            '${etudiant['first_name'] ?? ''} ${etudiant['last_name'] ?? ''}'.trim();
        etudiantsList.add({'id': etudiantId, 'nom': nom});

        try {
          final notesRes  = await ApiService.getNotesEtudiant(ecoleId, etudiantId: etudiantId);
          final notesList = notesRes['data'] as List? ?? [];
          for (var note in notesList) {
            if (note['devoir_id'] == devoir.id) { notesMap[etudiantId] = note; break; }
          }
        } catch (_) {}
      }

      setState(() {
        _etudiants       = etudiantsList;
        _notesByEtudiant = notesMap;
        _chargementNotes = false;
      });
    } catch (e) {
      setState(() { _error = 'Erreur : $e'; _chargementNotes = false; });
    }
  }

  List<DevoirModel> get _devoirsFiltres {
    var liste = _devoirs;
    if (_filtreClasseId != null) liste = liste.where((d) => d.classeId == _filtreClasseId).toList();
    if (_filtreEcueId   != null) liste = liste.where((d) => d.ecueId   == _filtreEcueId).toList();
    if (_filtreSession  != null) liste = liste.where((d) => d.session  == _filtreSession).toList();
    return liste;
  }

  int get _nbNotesSaisies => _notesByEtudiant.values.where((n) => n != null).length;
  int get _nbAbsents      => _notesByEtudiant.values.where((n) => n != null && n['absent'] == true).length;
  int get _nbNonSaisies   => _etudiants.length - _nbNotesSaisies;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation des notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerDonnees)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _devoirs.isEmpty
              ? _buildError()
              : Column(children: [
                  _buildFiltres(),
                  _buildSelectionDevoir(),
                  if (_etudiants.isNotEmpty && !_chargementNotes) _buildStatsResume(),
                  Expanded(
                    child: _chargementNotes
                        ? const Center(child: CircularProgressIndicator())
                        : _etudiants.isEmpty
                            ? Center(child: Text(_selectedDevoirId == null ? 'Sélectionnez un devoir' : 'Aucun étudiant', style: const TextStyle(color: Colors.grey)))
                            : _buildTableauNotes(),
                  ),
                ]),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _buildDropdownFiltre<int>(label: 'Classe', value: _filtreClasseId,
            items: _classes.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['nom'] ?? ''))).toList(),
            onChanged: (v) => setState(() { _filtreClasseId = v; _selectedDevoirId = null; _etudiants = []; _notesByEtudiant = {}; })),
          const SizedBox(width: 8),
          _buildDropdownFiltre<int>(label: 'ECUE', value: _filtreEcueId,
            items: _ecues.map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['nom'] ?? ''))).toList(),
            onChanged: (v) => setState(() { _filtreEcueId = v; _selectedDevoirId = null; _etudiants = []; _notesByEtudiant = {}; })),
          const SizedBox(width: 8),
          _buildDropdownFiltre<int>(label: 'Session', value: _filtreSession, width: 120,
            items: const [DropdownMenuItem(value: 1, child: Text('Session 1')), DropdownMenuItem(value: 2, child: Text('Session 2'))],
            onChanged: (v) => setState(() { _filtreSession = v; _selectedDevoirId = null; _etudiants = []; _notesByEtudiant = {}; })),
        ]),
      ),
    );
  }

  Widget _buildDropdownFiltre<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, double width = 150}) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        hint: const Text('Tous'),
        items: [DropdownMenuItem<T>(value: null, child: const Text('Tous')), ...items],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSelectionDevoir() {
    final devoirsFiltres = _devoirsFiltres;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sélectionner un devoir', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _selectedDevoirId,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            hint: Text(devoirsFiltres.isEmpty ? 'Aucun devoir' : 'Choisir...'),
            items: devoirsFiltres.map((d) => DropdownMenuItem<int>(
              value: d.id,
              child: Text('${d.titre} — ${d.ecue?.nom ?? ''} (${d.type})', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) { setState(() { _selectedDevoirId = v; _etudiants = []; _notesByEtudiant = {}; }); if (v != null) _chargerNotesPourDevoir(); },
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsResume() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('Total',        _etudiants.length.toString(),  Colors.blueGrey),
        Container(width: 1, height: 36, color: Colors.grey.shade200),
        _statItem('Saisies',      _nbNotesSaisies.toString(),    AppColors.primary),
        Container(width: 1, height: 36, color: Colors.grey.shade200),
        _statItem('Absents',      _nbAbsents.toString(),         Colors.orange),
        Container(width: 1, height: 36, color: Colors.grey.shade200),
        _statItem('Non saisies',  _nbNonSaisies.toString(),      Colors.grey),
      ]),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

  Widget _buildTableauNotes() {
    final bareme = _selectedDevoir?.bareme ?? 20;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
          columns: const [
            DataColumn(label: Text('Étudiant',    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Note / Barème', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Statut',      style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Observation', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _etudiants.map((etudiant) {
            final userId    = etudiant['id']  as int;
            final nom       = etudiant['nom'] as String;
            final note      = _notesByEtudiant[userId];
            final noteExiste = note != null;
            final estAbsent  = noteExiste && note['absent'] == true;
            final noteSaisie = noteExiste && !estAbsent;

            String valeurAffichee;
            if (!noteExiste)    { valeurAffichee = '—'; }
            else if (estAbsent) { valeurAffichee = 'Absent'; }
            else {
              final v = note['valeur'];
              valeurAffichee = '${v != null ? double.tryParse(v.toString())?.toStringAsFixed(2) ?? v.toString() : '—'} / $bareme';
            }

            Widget statutWidget;
            if (!noteExiste) {
              statutWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: const Text('Non saisie', style: TextStyle(color: Colors.grey, fontSize: 11)),
              );
            } else if (estAbsent) {
              statutWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Absent', style: TextStyle(color: Colors.green, fontSize: 11)),
                ]),
              );
            } else {
              statutWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Présent', style: TextStyle(color: Colors.red, fontSize: 11)),
                ]),
              );
            }

            Color? rowColor = estAbsent ? Colors.green.shade50 : noteSaisie ? Colors.red.shade50 : Colors.grey.shade100;

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(SizedBox(width: 180, child: Text(nom, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)))),
                DataCell(Text(valeurAffichee, style: TextStyle(color: estAbsent ? Colors.green : !noteExiste ? Colors.grey : Colors.black87, fontWeight: noteSaisie ? FontWeight.bold : FontWeight.normal))),
                DataCell(statutWidget),
                DataCell(SizedBox(width: 160, child: Text(noteExiste ? (note['observation'] ?? '') : '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: AppColors.red),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _chargerDonnees, child: const Text('Réessayer')),
    ]));
  }
}