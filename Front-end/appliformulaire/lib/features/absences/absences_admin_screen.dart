import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class AbsencesAdminScreen extends StatefulWidget {
  const AbsencesAdminScreen({super.key});

  @override
  State<AbsencesAdminScreen> createState() => _AbsencesAdminScreenState();
}

class _AbsencesAdminScreenState extends State<AbsencesAdminScreen> {
  final _session = SessionUtilisateur();

  List<dynamic> _absences   = [];
  List<dynamic> _classes    = [];
  List<dynamic> _etudiants  = [];
  List<dynamic> _ecues      = [];

  int?  _classeFiltre;
  int?  _etudiantFiltre;
  int?  _ecueFiltre;
  bool? _justifieeFiltre;

  bool _loading         = true;
  bool _loadingAbsences = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    try {
      final ecoleId    = _session.ecoleId;
      final classesRes = await ApiService.getClasses(ecoleId);
      final ecuesRes   = await ApiService.getEcues(ecoleId);
      _classes = classesRes['data'] as List? ?? [];
      _ecues   = ecuesRes['data']   as List? ?? [];
      await _chargerAbsences();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), erreur: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chargerAbsences() async {
    setState(() => _loadingAbsences = true);
    try {
      final ecoleId = _session.ecoleId;
      final params  = <String, dynamic>{};
      if (_etudiantFiltre  != null) params['etudiant_id'] = _etudiantFiltre;
      if (_ecueFiltre      != null) params['ecue_id']     = _ecueFiltre;
      if (_justifieeFiltre != null) params['justifiee']   = _justifieeFiltre! ? 1 : 0;

      final response = await ApiService.dio.get(
        '/api/ecoles/$ecoleId/absences',
        queryParameters: params,
      );
      _absences = response.data['data'] as List? ?? [];
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), erreur: true);
    } finally {
      if (mounted) setState(() => _loadingAbsences = false);
    }
  }

  Future<void> _chargerEtudiantsParClasse(int classeId) async {
    if (classeId == 0) { setState(() => _etudiants = []); return; }
    try {
      final etudiants = await ApiService.getEtudiantsByClasse(_session.ecoleId, classeId);
      setState(() => _etudiants = etudiants);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), erreur: true);
    }
  }

  Future<void> _justifierAbsence(int absenceId, String type, {String? obs}) async {
    try {
      await ApiService.justifierAbsence(
        _session.ecoleId, absenceId,
        typeJustification: type,
        observation: obs,
      );
      if (mounted) {
        _snack('Absence justifiée avec succès');
        _chargerAbsences();
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), erreur: true);
    }
  }

  void _afficherDialogJustification(int absenceId) {
    final typeCtrl = TextEditingController();
    final obsCtrl  = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Justifier l\'absence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Type de justification *',
                  hintText: 'Ex: Certificat médical',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observation (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _justifierAbsence(
                  absenceId,
                  typeCtrl.text.trim(),
                  obs: obsCtrl.text.trim().isNotEmpty ? obsCtrl.text.trim() : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Justifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erreur ? AppColors.red : AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final s = raw.split(RegExp(r'[T ]'))[0];
    final parts = s.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des absences', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerAbsences),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltres(),
                Expanded(
                  child: _loadingAbsences
                      ? const Center(child: CircularProgressIndicator())
                      : _absences.isEmpty
                          ? const Center(
                              child: Text('Aucune absence trouvée', style: TextStyle(color: AppColors.textSub)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _absences.length,
                              itemBuilder: (_, i) => _buildCarteAbsence(_absences[i]),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'Classe',
                  initialValue: _classeFiltre,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Toutes', overflow: TextOverflow.ellipsis)),
                    ..._classes.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['nom'] ?? '', overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _classeFiltre = v;
                      _etudiantFiltre = null;
                    });
                    _chargerEtudiantsParClasse(v ?? 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown<int>(
                  label: 'Étudiant',
                  initialValue: _etudiantFiltre,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Tous', overflow: TextOverflow.ellipsis)),
                    ..._etudiants.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(
                            e['full_name'] ?? '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _etudiantFiltre = v);
                    _chargerAbsences();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'ECUE',
                  initialValue: _ecueFiltre,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Tous', overflow: TextOverflow.ellipsis)),
                    ..._ecues.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(e['nom'] ?? '', overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _ecueFiltre = v);
                    _chargerAbsences();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown<bool>(
                  label: 'Statut',
                  initialValue: _justifieeFiltre,
                  items: const [
                    DropdownMenuItem<bool>(value: null, child: Text('Toutes')),
                    DropdownMenuItem<bool>(value: false, child: Text('Non justifiées')),
                    DropdownMenuItem<bool>(value: true, child: Text('Justifiées')),
                  ],
                  onChanged: (v) {
                    setState(() => _justifieeFiltre = v);
                    _chargerAbsences();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      isExpanded: true,
      menuMaxHeight: 300,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCarteAbsence(Map<String, dynamic> absence) {
    final etudiant  = absence['etudiant'] as Map<String, dynamic>? ?? {};
    final ecue      = absence['ecue']     as Map<String, dynamic>? ?? {};
    final cours     = absence['cours']    as Map<String, dynamic>? ?? {};
    final justifiee = absence['justifiee'] == true;

    final nom = etudiant['full_name'] ??
        '${etudiant['first_name'] ?? ''} ${etudiant['last_name'] ?? ''}'.trim();

    final dateAff = _formatDate(
      cours['date_cours'] as String? ?? absence['date_absence'] as String? ?? '',
    );

    final heureDebut = cours['heure_debut'] as String? ?? '';
    final heureFin   = cours['heure_fin']   as String? ?? '';
    final horaire    = (heureDebut.isNotEmpty && heureFin.isNotEmpty)
        ? '$heureDebut - $heureFin'
        : 'Horaire non renseigné';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: justifiee
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    justifiee ? Icons.check_circle : Icons.error_outline,
                    color: justifiee ? AppColors.green : AppColors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ecue['nom'] as String? ?? 'Cours inconnu',
                        style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: justifiee
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    justifiee ? 'Justifiée' : 'Non justifiée',
                    style: TextStyle(
                      color: justifiee ? AppColors.green : AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: AppColors.textSub),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    dateAff.isNotEmpty ? dateAff : 'Date inconnue',
                    style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 13, color: AppColors.textSub),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    horaire,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (absence['type_justification'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.description, size: 13, color: AppColors.textSub),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Justifié par : ${absence['type_justification']}',
                      style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (!justifiee) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _afficherDialogJustification(absence['id'] as int),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Justifier cette absence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}