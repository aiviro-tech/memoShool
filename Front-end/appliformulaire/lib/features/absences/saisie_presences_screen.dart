import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class SaisiePresencesScreen extends StatefulWidget {
  const SaisiePresencesScreen({super.key});

  @override
  State<SaisiePresencesScreen> createState() => _SaisiePresencesScreenState();
}

class _SaisiePresencesScreenState extends State<SaisiePresencesScreen> {
  final _session = SessionUtilisateur();
  
  List<dynamic> _cours = [];
  List<dynamic> _etudiants = [];
  List<dynamic> _classes = [];
  
  int? _classeFiltre;
  int? _coursFiltre;
  
  final Map<int, bool> _presences = {};
  final Map<int, TextEditingController> _observationControllers = {};
  
  bool _loading = true;
  bool _loadingEtudiants = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    for (var controller in _observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    try {
      final ecoleId = _session.ecoleId;
      
      final classesRes = await ApiService.getClasses(ecoleId);
      _classes = classesRes['data'] as List? ?? [];
      
      final coursRes = await ApiService.getCours(ecoleId);
      _cours = coursRes['data'] as List? ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chargerEtudiants() async {
    if (_classeFiltre == null) {
      setState(() => _etudiants = []);
      return;
    }
    
    setState(() => _loadingEtudiants = true);
    try {
      final etudiants = await ApiService.getEtudiantsByClasse(_session.ecoleId, _classeFiltre!);
      setState(() => _etudiants = etudiants);
      _presences.clear();
      _observationControllers.clear();
      for (var etudiant in etudiants) {
        final id = etudiant['id'] as int;
        _presences[id] = true;
        _observationControllers[id] = TextEditingController();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEtudiants = false);
    }
  }

  Future<void> _enregistrerPresences() async {
    if (_coursFiltre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un cours'), backgroundColor: AppColors.orange),
      );
      return;
    }
    
    setState(() => _submitting = true);
    
    final presencesData = <Map<String, dynamic>>[];
    for (var etudiant in _etudiants) {
      final id = etudiant['id'] as int;
      presencesData.add({
        'etudiant_id': id,
        'present': _presences[id] ?? true,
        'observation': _observationControllers[id]?.text.trim() ?? '',
      });
    }
    
    try {
      await ApiService.saisirPresences(
        _session.ecoleId,
        _coursFiltre!,
        presencesData,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Présences enregistrées avec succès'), backgroundColor: AppColors.green),
        );
        _chargerEtudiants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toutMarquer(bool present) async {
    setState(() {
      for (var etudiant in _etudiants) {
        final id = etudiant['id'] as int;
        _presences[id] = present;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saisie des présences', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerDonnees),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltres(),
                Expanded(
                  child: _loadingEtudiants
                      ? const Center(child: CircularProgressIndicator())
                      : _etudiants.isEmpty
                          ? const Center(child: Text('Aucun étudiant trouvé', style: TextStyle(color: AppColors.textSub)))
                          : Column(
                              children: [
                                _buildActions(),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _etudiants.length,
                                    itemBuilder: (_, index) => _buildCarteEtudiant(_etudiants[index]),
                                  ),
                                ),
                                _buildBoutonEnregistrer(),
                              ],
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Classe *', border: OutlineInputBorder()),
            initialValue: _classeFiltre,
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('Sélectionnez une classe')),
              ..._classes.map((c) => DropdownMenuItem<int>(
                value: c['id'] as int,
                child: Text(c['nom'] ?? ''),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _classeFiltre = value;
                _coursFiltre = null;
              });
              _chargerEtudiants();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Cours *', border: OutlineInputBorder()),
            initialValue: _coursFiltre,
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('Sélectionnez un cours')),
              ..._cours.where((c) => c['classe_id'] == _classeFiltre).map((c) {
                final ecue = c['ecue'] as Map<String, dynamic>? ?? {};
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text('${ecue['nom'] ?? ''} - ${c['date_cours']}'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _coursFiltre = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toutMarquer(true),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Tous présents'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toutMarquer(false),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Tous absents'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteEtudiant(Map<String, dynamic> etudiant) {
    final id = etudiant['id'] as int;
    final nom = etudiant['full_name'] ?? '${etudiant['first_name'] ?? ''} ${etudiant['last_name'] ?? ''}'.trim();
    final present = _presences[id] ?? true;
    final observationCtrl = _observationControllers[id] ?? TextEditingController();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: present ? AppColors.green.withValues(alpha: 0.1) : AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Icon(
                    present ? Icons.check : Icons.close,
                    color: present ? AppColors.green : AppColors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        etudiant['matricule'] ?? 'Matricule non défini',
                        style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: present,
                  activeThumbColor: AppColors.green,
                  activeTrackColor: AppColors.green.withValues(alpha: 0.3),
                  onChanged: (val) {
                    setState(() {
                      _presences[id] = val;
                    });
                  },
                ),
              ],
            ),
            if (!present) ...[
              const SizedBox(height: 8),
              TextField(
                controller: observationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Motif de l\'absence (optionnel)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonEnregistrer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _enregistrerPresences,
          icon: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_submitting ? 'Enregistrement...' : 'Enregistrer les présences'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}