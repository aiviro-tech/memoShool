import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _session = SessionUtilisateur();
  bool _loading = true;
  String? _error;
  List<dynamic> _inscriptions = [];
  List<dynamic> _classes = [];
  List<dynamic> _etudiants = [];
  String _filtreStatut = 'tous';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ecoleId = _session.ecoleId;
      final inscrResult = await ApiService.getInscriptions(ecoleId);
      final classeResult = await ApiService.getClasses(ecoleId);
      
      List<dynamic> etudiants = [];
      try {
        etudiants = await ApiService.getMembres(ecoleId, role: 'etudiant');
      } catch (_) {}

      setState(() {
        _inscriptions = (inscrResult['data'] as List?) ?? [];
        _classes = (classeResult['data'] as List?) ?? [];
        _etudiants = etudiants;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _inscriptionsFiltrees {
    if (_filtreStatut == 'tous') return _inscriptions;
    return _inscriptions.where((i) => i['statut'] == _filtreStatut).toList();
  }

  // NOUVEAU : Supprimer une inscription
  Future<void> _supprimerInscription(int id, String nomEtudiant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'inscription de "$nomEtudiant" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Appel API pour supprimer l'inscription
      await ApiService.supprimerInscription(_session.ecoleId, id);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription supprimée ✓'), backgroundColor: app.AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _inscrireEtudiant() async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord une classe'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_etudiants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun étudiant dans cette école'), backgroundColor: Colors.orange),
      );
      return;
    }

    int? etudiantId;
    int? classeId = _classes.first['id'] as int;
    final anneeCtrl = TextEditingController(text: '2025-2026');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Inscrire un étudiant', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: etudiantId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Étudiant *',
                    border: OutlineInputBorder(),
                  ),
                  items: _etudiants.map((e) {
                    final user = e['user'] ?? e;
                    final nom = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                    final id = (user['id'] ?? e['user_id']) as int;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(nom.isNotEmpty ? nom : 'ID: $id', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setS(() => etudiantId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: classeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Classe *',
                    border: OutlineInputBorder(),
                  ),
                  items: _classes.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text('${c['nom']} (${c['niveau'] ?? ''})'),
                  )).toList(),
                  onChanged: (v) => setS(() => classeId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: anneeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Année académique *',
                    hintText: 'ex: 2025-2026',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Inscrire')),
          ],
        ),
      ),
    );

    if (result != true || etudiantId == null || classeId == null) return;
    try {
      await ApiService.creerInscription(_session.ecoleId, {
        'classe_id': classeId,
        'annee_academique': anneeCtrl.text.trim(),
        'etudiant_id': etudiantId,
      });
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant inscrit avec succès ✓'), backgroundColor: app.AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _valider(int id) async {
    try {
      await ApiService.validerInscription(_session.ecoleId, id);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription validée ✓'), backgroundColor: app.AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _rejeter(int id) async {
    final motifCtrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: motifCtrl,
          decoration: const InputDecoration(
            hintText: 'Raison du rejet...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motifCtrl.text.isNotEmpty ? motifCtrl.text : 'Rejeté'),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (motif == null) return;
    try {
      await ApiService.rejeterInscription(_session.ecoleId, id, motif);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription rejetée'), backgroundColor: app.AppColors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.estAdmin;

    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: Text(isAdmin ? 'Gestion des inscriptions' : 'Mes inscriptions'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: app.AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filtreStatut,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'tous', child: Text('Tous statuts')),
                                    DropdownMenuItem(value: 'soumise', child: Text('Soumise')),
                                    DropdownMenuItem(value: 'validee', child: Text('Validée')),
                                    DropdownMenuItem(value: 'rejetee', child: Text('Rejetée')),
                                  ],
                                  onChanged: (v) => setState(() => _filtreStatut = v!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${_inscriptionsFiltrees.length} inscription(s)',
                              style: const TextStyle(color: app.AppColors.textSub, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: _inscriptionsFiltrees.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 100),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.school_outlined, size: 64, color: app.AppColors.primary.withValues(alpha: 0.3)),
                                        const SizedBox(height: 16),
                                        const Text('Aucune inscription',
                                            style: TextStyle(fontSize: 16, color: app.AppColors.textSub)),
                                        if (isAdmin) ...[
                                          const SizedBox(height: 8),
                                          const Text('Inscrivez des étudiants dans les classes',
                                              style: TextStyle(fontSize: 13, color: app.AppColors.textSub)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: _inscriptionsFiltrees.length,
                                itemBuilder: (_, i) {
                                  final insc = _inscriptionsFiltrees[i];
                                  final etudiant = insc['etudiant'] as Map<String, dynamic>? ?? {};
                                  final classe = insc['classe'] as Map<String, dynamic>? ?? {};
                                  final nom = '${etudiant['first_name'] ?? ''} ${etudiant['last_name'] ?? ''}'.trim();
                                  final statut = insc['statut'] ?? 'soumise';
                                  final id = insc['id'] as int;

                                  Color couleur;
                                  switch (statut) {
                                    case 'validee': couleur = app.AppColors.green; break;
                                    case 'rejetee': couleur = app.AppColors.red; break;
                                    default: couleur = app.AppColors.orange;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border(left: BorderSide(color: couleur, width: 4)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline, size: 20, color: app.AppColors.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(nom.isNotEmpty ? nom : 'Étudiant #${etudiant['id']}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: couleur.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(statut.toUpperCase(),
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: couleur)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.school_outlined, size: 14, color: app.AppColors.textSub),
                                              const SizedBox(width: 4),
                                              Text('${classe['nom'] ?? ''} (${classe['niveau'] ?? ''})',
                                                  style: const TextStyle(fontSize: 12, color: app.AppColors.textSub)),
                                              const Spacer(),
                                              Text(insc['annee_academique'] ?? '',
                                                  style: const TextStyle(fontSize: 12, color: app.AppColors.textSub)),
                                            ],
                                          ),
                                          if (isAdmin && statut == 'soumise') ...[
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _valider(id),
                                                    icon: const Icon(Icons.check, size: 16),
                                                    label: const Text('Valider'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: app.AppColors.green,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _rejeter(id),
                                                    icon: const Icon(Icons.close, size: 16),
                                                    label: const Text('Rejeter'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: app.AppColors.red,
                                                      side: const BorderSide(color: app.AppColors.red),
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          // NOUVEAU : Bouton Supprimer pour l'admin (tous statuts)
                                          if (isAdmin) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _supprimerInscription(id, nom),
                                                    icon: const Icon(Icons.delete_outline, size: 16),
                                                    label: const Text('Supprimer'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: app.AppColors.red,
                                                      side: const BorderSide(color: app.AppColors.red),
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (statut == 'rejetee' && insc['motif_rejet'] != null) ...[
                                            const SizedBox(height: 8),
                                            Text('Motif: ${insc['motif_rejet']}',
                                                style: const TextStyle(fontSize: 12, color: app.AppColors.red, fontStyle: FontStyle.italic)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _inscrireEtudiant,
              backgroundColor: app.AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Inscrire', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}