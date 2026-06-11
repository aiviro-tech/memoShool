import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/services/notes_service.dart';

class ReleveAdminScreen extends StatefulWidget {
  const ReleveAdminScreen({super.key});

  @override
  State<ReleveAdminScreen> createState() => _ReleveAdminScreenState();
}

class _ReleveAdminScreenState extends State<ReleveAdminScreen> {
  final _session = SessionUtilisateur();
  final _service = NoteService();

  // Données de sélection
  List<dynamic> _classes = [];
  List<dynamic> _semestres = [];
  List<Map<String, dynamic>> _etudiants = [];

  int? _classeId;
  int? _semestreId;
  int? _etudiantId;
  int _sessionChoisie = 1;
  String? _nomEtudiant;

  // Relevés de l'étudiant sélectionné
  List<dynamic> _releves = [];

  bool _chargementInitial = true;
  bool _chargementEtudiants = false;
  bool _chargementReleves = false;
  bool _generation = false;

  @override
  void initState() {
    super.initState();
    _chargerInitial();
  }

  // ── Chargement initial ───────────────────────────────────────────────────
  Future<void> _chargerInitial() async {
    setState(() {
      _chargementInitial = true;
    });
    try {
      final ecoleId = _session.ecoleId;
      final classesRes = await ApiService.getClasses(ecoleId);
      final semestresRes = await ApiService.getSemestres(ecoleId);
      setState(() {
        _classes = classesRes['data'] as List? ?? [];
        _semestres = semestresRes['data'] as List? ?? [];
        if (_semestres.isNotEmpty) {
          _semestreId = _semestres.first['id'] as int;
        }
        _chargementInitial = false;
      });
    } catch (e) {
      setState(() {
        _chargementInitial = false;
      });
    }
  }

  // ── Charger étudiants d'une classe ──────────────────────────────────────
  Future<void> _chargerEtudiants(int classeId) async {
    setState(() {
      _chargementEtudiants = true;
      _etudiants = [];
      _etudiantId = null;
      _releves = [];
    });
    try {
      final res = await ApiService.getInscriptions(
        _session.ecoleId,
        statut: 'validee',
        classeId: classeId,
      );
      final inscriptions = res['data'] as List? ?? [];
      final liste = <Map<String, dynamic>>[];
      for (final ins in inscriptions) {
        final e = ins['etudiant'] as Map<String, dynamic>? ?? {};
        if (e['id'] != null) {
          liste.add({
            'id': e['id'],
            'nom': e['full_name'] ??
                '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim(),
          });
        }
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

  // ── Charger relevés d'un étudiant ────────────────────────────────────────
  Future<void> _chargerReleves() async {
    if (_etudiantId == null) return;
    setState(() {
      _chargementReleves = true;
    });
    try {
      final data = await _service.getRelevesList(_session.ecoleId,
          etudiantId: _etudiantId);
      setState(() {
        _releves = data;
        _chargementReleves = false;
      });
    } catch (e) {
      setState(() {
        _chargementReleves = false;
      });
    }
  }

  // ── Générer le relevé ────────────────────────────────────────────────────
  Future<void> _genererReleve() async {
    if (_etudiantId == null || _semestreId == null || _classeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sélectionnez une classe, un semestre et un étudiant.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _generation = true);
    try {
      await _service.genererReleve(
        _session.ecoleId,
        etudiantId: _etudiantId!,
        semestreId: _semestreId!,
        classeId: _classeId!,
        session: _sessionChoisie,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relevé de $_nomEtudiant généré avec succès !'),
            backgroundColor: AppColors.green,
          ),
        );
        _chargerReleves();
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
      if (mounted) setState(() => _generation = false);
    }
  }

  // ── Télécharger un relevé ────────────────────────────────────────────────
  void _telechargerReleve(int releveId) {
    final url = ApiService.getTelechargementReleveUrl(_session.ecoleId, releveId,
        token: _session.token);
    launchUrl(Uri.parse(url));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Gestion des relevés',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerInitial,
          ),
        ],
      ),
      body: _chargementInitial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPanneauSelection(),
                _buildPanneauGeneration(),
                const Divider(height: 1),
                Expanded(child: _buildListeReleves()),
              ],
            ),
    );
  }

  // ── Panneau sélection ─────────────────────────────────────────────────────
  Widget _buildPanneauSelection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Ligne 1 : Classe + Semestre
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'Classe',
                  value: _classeId,
                  items: _classes.map((c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(
                          c['nom'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _classeId = v;
                      _etudiantId = null;
                      _releves = [];
                    });
                    if (v != null) _chargerEtudiants(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown<int>(
                  label: 'Semestre',
                  value: _semestreId,
                  items: _semestres.map((s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          'Sem. ${s['numero'] ?? s['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                  onChanged: (v) => setState(() => _semestreId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 2 : Étudiant
          _chargementEtudiants
              ? const LinearProgressIndicator()
              : _dropdown<int>(
                  label: 'Étudiant',
                  value: _etudiantId,
                  items: _etudiants.map((e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text(
                          e['nom'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                  onChanged: _classeId == null
                      ? null
                      : (v) {
                          setState(() {
                            _etudiantId = v;
                            _nomEtudiant = _etudiants.firstWhere(
                              (e) => e['id'] == v,
                              orElse: () => {'nom': ''},
                            )['nom'] as String?;
                            _releves = [];
                          });
                          if (v != null) _chargerReleves();
                        },
                ),
        ],
      ),
    );
  }

  // ── Panneau génération ────────────────────────────────────────────────────
  Widget _buildPanneauGeneration() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text(
            'Générer un relevé',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Sélecteur session
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'Session',
                  value: _sessionChoisie,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Session 1')),
                    DropdownMenuItem(value: 2, child: Text('Session 2')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _sessionChoisie = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Bouton générer
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _etudiantId != null ? AppColors.primary : Colors.grey,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _generation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(
                    _generation ? 'Génération...' : 'Générer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed:
                      _generation || _etudiantId == null ? null : _genererReleve,
                ),
              ),
            ],
          ),
          // Info étudiant sélectionné
          if (_nomEtudiant != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Étudiant sélectionné : $_nomEtudiant',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Liste des relevés ────────────────────────────────────────────────────
  Widget _buildListeReleves() {
    if (_etudiantId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _classeId == null
                  ? 'Sélectionnez une classe'
                  : 'Sélectionnez un étudiant',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_chargementReleves) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_releves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined,
                size: 64, color: Color(0xFF90CAF9)),
            const SizedBox(height: 16),
            Text(
              'Aucun relevé pour $_nomEtudiant',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez le bouton "Générer" ci-dessus',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Relevés de $_nomEtudiant (${_releves.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textMain,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _chargerReleves,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _releves.length,
              itemBuilder: (_, i) {
                final releve = _releves[i];
                final semestre =
                    releve['semestre'] as Map<String, dynamic>? ?? {};
                final numero = semestre['numero'] ?? releve['semestre_id'];
                final annee = semestre['annee_academique'] ?? '';
                final session = releve['session'];
                final date = (releve['created_at'] as String? ?? '').length >= 10
                    ? (releve['created_at'] as String).substring(0, 10)
                    : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semestre $numero — Session $session',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (annee.isNotEmpty)
                                Text(
                                  annee,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              Text(
                                'Généré le $date',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Bouton télécharger
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: AppColors.primary, size: 28),
                          tooltip: 'Télécharger',
                          onPressed: () =>
                              _telechargerReleve(releve['id'] as int),
                        ),
                      ],
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

  // ── Helper dropdown ───────────────────────────────────────────────────────
  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}