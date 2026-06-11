import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/cours_model.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import '../cours/detail_cours_page.dart';
import '../cours/formulaire_cours_page.dart';

class ListeCoursTab extends StatefulWidget {
  const ListeCoursTab({super.key});

  @override
  State<ListeCoursTab> createState() => _ListeCoursTabState();
}

class _ListeCoursTabState extends State<ListeCoursTab> {
  final _session = SessionUtilisateur();
  List<CoursModel> _cours = [];
  bool _chargement = true;
  String? _erreur;
  String? _messageVide;

  // Filtres
  String? _filtreStatut;
  String? _filtreClasseId;
  List<dynamic> _classes = [];

  List<Map<String, String>> get _statutsDisponibles {
    if (_session.estAdmin) {
      return [
        {'label': 'Tous', 'value': ''},
        {'label': 'Planifié', 'value': 'planifie'},
        {'label': 'Confirmé', 'value': 'confirme'},
        {'label': 'Reporté', 'value': 'reporte'},
        {'label': 'Terminé', 'value': 'termine'},
        {'label': 'Annulé', 'value': 'annule'},
      ];
    }
    return [
      {'label': 'Tous', 'value': ''},
      {'label': 'Reporté', 'value': 'reporte'},
      {'label': 'Terminé', 'value': 'termine'},
      {'label': 'Annulé', 'value': 'annule'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _chargerClasses();
    _charger();
  }

  Future<void> _chargerClasses() async {
    try {
      final res = await ApiService.getClasses(_session.ecoleId);
      setState(() {
        _classes = res['data'] as List? ?? [];
      });
    } catch (_) {}
  }

  Future<void> _charger() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) {
      setState(() {
        _erreur = 'Aucune école sélectionnée.';
        _chargement = false;
      });
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
      _messageVide = null;
    });

    try {
      final result = await ApiService.getCours(ecoleId);
      final data = result['data'] as List? ?? [];

      String? msgVide;
      if (data.isEmpty) {
        if (_session.estEtudiant) {
          msgVide = result['message'] as String? ??
              'Aucun cours trouvé.\n\n'
              'Si vous venez d\'être inscrit, votre inscription est peut-être '
              'en attente de validation par l\'administration.\n'
              'Actualisez pour vérifier.';
        } else if (_session.estEnseignant) {
          msgVide = 'Aucun cours ne vous a été assigné pour le moment.';
        } else {
          msgVide = 'Aucun cours n\'a été créé pour cette école.';
        }
      }

      List<CoursModel> tousLesCours = data
          .map((e) => CoursModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filtre par classe
      if (_filtreClasseId != null && _filtreClasseId!.isNotEmpty) {
        tousLesCours = tousLesCours.where((c) =>
            c.classeId.toString() == _filtreClasseId).toList();
      }

      // Filtre par statut
      if (_filtreStatut != null && _filtreStatut!.isNotEmpty) {
        tousLesCours = tousLesCours
            .where((c) => c.statut == _filtreStatut)
            .toList();
      }

      setState(() {
        _cours = tousLesCours;
        _messageVide = msgVide;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  void _ouvrirFormulaire() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaireCoursPage(
          ecoleId: _session.ecoleId,
          cours: null,
        ),
      ),
    ).then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildFiltres(),
            Expanded(
              child: _chargement
                  ? const Center(child: CircularProgressIndicator())
                  : _erreur != null
                      ? _buildErreur()
                      : _cours.isEmpty
                          ? _buildVide()
                          : _buildListe(),
            ),
          ],
        ),
        if (_session.estAdmin)
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'fab_cours',
              onPressed: _ouvrirFormulaire,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Créer un cours'),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltres() {
    final statuts = _statutsDisponibles;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          if (_classes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String>(
                value: _filtreClasseId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrer par classe',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Toutes les classes')),
                  ..._classes.map((c) => DropdownMenuItem<String>(
                    value: c['id'].toString(),
                    child: Text(c['nom'] ?? ''),
                  )),
                ],
                onChanged: (value) {
                  setState(() => _filtreClasseId = value);
                  _charger();
                },
              ),
            ),
          Row(
            children: [
              const Text('Statut :', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statuts.map((s) {
                      final selected = _filtreStatut == s['value'] ||
                          (_filtreStatut == null && s['value'] == '');
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(s['label']!, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _filtreStatut = s['value']!.isEmpty ? null : s['value']);
                            _charger();
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVide() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _session.estEtudiant
                        ? Icons.school_outlined
                        : Icons.calendar_today_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _messageVide ?? 'Aucun cours trouvé.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  if (_session.estEtudiant) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                      onPressed: _charger,
                    ),
                  ],
                  if (_session.estAdmin) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un cours'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _ouvrirFormulaire,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.red),
            const SizedBox(height: 16),
            Text(
              _erreur!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.red, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _charger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, _session.estAdmin ? 88 : 12),
        itemCount: _cours.length,
        itemBuilder: (_, i) => _buildCarte(_cours[i]),
      ),
    );
  }

  Widget _buildCarte(CoursModel cours) {
    final couleurStatut = _couleurStatut(cours.statut);
    final libelleStatut = _libelleStatut(cours.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: cours.statut == 'annule'
            ? BorderSide(color: AppColors.red.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailCoursPage(
                cours: cours, ecoleId: _session.ecoleId),
          ),
        ).then((_) => _charger()),
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours.ecue,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cours.ecueCode,
                          style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: couleurStatut.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      libelleStatut,
                      style: TextStyle(
                        color: couleurStatut,
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
                  _infoItem(Icons.calendar_today_outlined,
                      cours.dateFormatee),
                  const SizedBox(width: 16),
                  _infoItem(
                      Icons.access_time_outlined, cours.horaireFormate),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _infoItem(Icons.location_on_outlined, cours.salle),
                  const SizedBox(width: 16),
                  _infoItem(Icons.school_outlined, cours.classe),
                ],
              ),
              const SizedBox(height: 6),
              _infoItem(Icons.person_outline, cours.enseignant),
              const SizedBox(height: 6),
              _infoItem(
                Icons.account_tree_outlined,
                '${cours.filiere} • ${cours.ecueCredits} crédits',
              ),
              if (cours.statut == 'annule' &&
                  cours.motifAnnulation != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.red, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cours.motifAnnulation!,
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icone, String texte) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: AppColors.textSub),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texte,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSub),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'confirme':
        return AppColors.green;
      case 'annule':
        return AppColors.red;
      case 'reporte':
        return AppColors.orange;
      case 'termine':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'planifie':
        return 'Planifié';
      case 'confirme':
        return 'Confirmé';
      case 'annule':
        return 'Annulé';
      case 'reporte':
        return 'Reporté';
      case 'termine':
        return 'Terminé';
      default:
        return statut;
    }
  }
}