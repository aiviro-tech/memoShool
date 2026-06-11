import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/services/notes_service.dart';

class AutoriserNotesScreen extends StatefulWidget {
  const AutoriserNotesScreen({super.key});

  @override
  State<AutoriserNotesScreen> createState() => _AutoriserNotesScreenState();
}

class _AutoriserNotesScreenState extends State<AutoriserNotesScreen> {
  final _session = SessionUtilisateur();
  final _service = NoteService();

  List<dynamic> _enseignants = [];
  List<dynamic> _semestres = [];
  List<dynamic> _autorisations = [];

  int? _enseignantId;
  int? _semestreId;
  String? _nomEnseignant;
  final _dateExpirationCtrl = TextEditingController();
  final _observationCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _dateExpirationCtrl.dispose();
    _observationCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _loading = true;
    });
    try {
      final ecoleId = _session.ecoleId;
      final enseignants = await ApiService.getEnseignants(ecoleId);
      final semestresRes = await ApiService.getSemestres(ecoleId);
      final autorisations = await _service.getAutorisations(ecoleId);

      setState(() {
        _enseignants = enseignants;
        _semestres = semestresRes['data'] as List? ?? [];
        _autorisations = autorisations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _autoriser() async {
    if (_enseignantId == null || _semestreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un enseignant et un semestre.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.autoriserSaisieNotes(_session.ecoleId, {
        'enseignant_id': _enseignantId,
        'semestre_id': _semestreId,
        if (_dateExpirationCtrl.text.isNotEmpty) 'date_expiration': _dateExpirationCtrl.text,
        if (_observationCtrl.text.isNotEmpty) 'observation': _observationCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autorisation accordée à $_nomEnseignant'),
            backgroundColor: AppColors.green,
          ),
        );
        _dateExpirationCtrl.clear();
        _observationCtrl.clear();
        setState(() {
          _enseignantId = null;
          _semestreId = null;
          _nomEnseignant = null;
        });
        _chargerDonnees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _revoquer(int autorisationId, String nomEnseignant) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Révoquer l\'autorisation'),
        content: Text('Voulez-vous révoquer l\'autorisation de $nomEnseignant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Révoquer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await ApiService.revoquerAutorisation(_session.ecoleId, autorisationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorisation révoquée'),
            backgroundColor: AppColors.orange,
          ),
        );
        _chargerDonnees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _choisirDateExpiration() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateExpirationCtrl.text = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Autoriser saisie de notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulaire d'autorisation
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nouvelle autorisation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 14),

                          // Enseignant
                          const Text(
                            'Enseignant *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _enseignantId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Sélectionner un enseignant',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: _enseignants.map((e) {
                              final nom = e['full_name'] ??
                                  '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                              return DropdownMenuItem<int>(
                                value: e['id'] as int,
                                child: Text(
                                  nom,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() {
                                _enseignantId = v;
                                _nomEnseignant = _enseignants.firstWhere(
                                  (e) => e['id'] == v,
                                  orElse: () => {'full_name': ''},
                                )['full_name'];
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Semestre
                          const Text(
                            'Semestre *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _semestreId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Sélectionner un semestre',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: _semestres.map((s) => DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text(
                                'Semestre ${s['numero'] ?? s['id']} — ${s['annee_academique'] ?? ''}',
                              ),
                            )).toList(),
                            onChanged: (v) => setState(() => _semestreId = v),
                          ),
                          const SizedBox(height: 12),

                          // Date expiration
                          const Text(
                            'Date d\'expiration (optionnel)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dateExpirationCtrl,
                            readOnly: true,
                            onTap: _choisirDateExpiration,
                            decoration: InputDecoration(
                              hintText: 'Aucune expiration',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                              suffixIcon: _dateExpirationCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() => _dateExpirationCtrl.clear()),
                                    )
                                  : const Icon(Icons.calendar_today, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Observation
                          const Text(
                            'Observation (optionnel)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _observationCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Remarques...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.security, color: Colors.white),
                            label: Text(
                              _submitting ? 'Traitement...' : 'Accorder l\'autorisation',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _submitting ? null : _autoriser,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Liste des autorisations actives
                  if (_autorisations.isNotEmpty) ...[
                    const Text(
                      'Autorisations actives',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 12),
                    ..._autorisations.map((a) {
                      final enseignant = a['enseignant'] as Map<String, dynamic>? ?? {};
                      final semestre = a['semestre'] as Map<String, dynamic>? ?? {};
                      final nom = enseignant['full_name'] ??
                          '${enseignant['first_name'] ?? ''} ${enseignant['last_name'] ?? ''}'.trim();
                      final actif = a['actif'] == true;
                      final dateExp = a['date_expiration'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: actif ? Colors.green.shade200 : Colors.grey.shade200),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: actif ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  actif ? Icons.check_circle : Icons.cancel,
                                  color: actif ? Colors.green : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nom,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Semestre ${semestre['numero'] ?? ''} — ${semestre['annee_academique'] ?? ''}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    if (dateExp != null)
                                      Text(
                                        'Expire le $dateExp',
                                        style: const TextStyle(color: Colors.orange, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              if (actif)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                                  tooltip: 'Révoquer',
                                  onPressed: () => _revoquer(a['id'] as int, nom),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}