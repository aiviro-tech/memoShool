// ============================================================
// FICHIER : lib/features/ue/ue_tab.dart
// Page de gestion des UE pour l'admin
// ============================================================

import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class UeTab extends StatefulWidget {
  const UeTab({super.key});

  @override
  State<UeTab> createState() => _UeTabState();
}

class _UeTabState extends State<UeTab> {
  final _session = SessionUtilisateur();
  List<dynamic> _ues = [];
  List<dynamic> _semestres = [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _chargement = true; _erreur = null; });
    try {
      final resUes = await ApiService.getUes(_session.ecoleId);
      final resSem = await ApiService.getSemestres(_session.ecoleId);
      setState(() {
        _ues = resUes['data'] as List? ?? [];
        _semestres = resSem['data'] as List? ?? [];
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _creerUe() async {
    if (_semestres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun semestre disponible.\n'
            'Créez d\'abord une filière puis un semestre.',
          ),
          backgroundColor: AppColors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final resultat = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogCreerUe(semestres: _semestres),
    );

    if (resultat == null || !mounted) return;

    try {
      await ApiService.creerUe(_session.ecoleId, resultat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UE créée avec succès !'),
            backgroundColor: AppColors.green,
          ),
        );
        _charger();
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

  Future<void> _supprimerUe(int ueId, String libelle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous supprimer l\'UE "$libelle" ?\n\n'
          'Attention : cette action est impossible si des ECUEs y sont rattachées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiService.supprimerUe(_session.ecoleId, ueId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UE supprimée.'),
            backgroundColor: AppColors.green,
          ),
        );
        _charger();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _chargement
            ? const Center(child: CircularProgressIndicator())
            : _erreur != null
                ? _buildErreur()
                : _ues.isEmpty
                    ? _buildVide()
                    : _buildListe(),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'fab_ue',
            onPressed: _creerUe,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Créer une UE',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildListe() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _ues.length,
        itemBuilder: (_, i) {
          final ue = _ues[i] as Map<String, dynamic>;
          final semestre = ue['semestre'] as Map<String, dynamic>? ?? {};
          final filiere =
              semestre['filiere'] as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.library_books,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ue['libelle'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code : ${ue['code'] ?? ''} • ${ue['credits_ects'] ?? 0} crédits',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub),
                        ),
                        Text(
                          'Semestre ${semestre['numero'] ?? ''} • ${filiere['nom'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.red, size: 20),
                    onPressed: () => _supprimerUe(
                      ue['id'] as int,
                      ue['libelle'] ?? '',
                    ),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          );
        },
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined,
                    size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Aucune UE créée.',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez d\'abord une filière et un semestre,\npuis ajoutez vos UE.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSub),
                ),
              ],
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
            const Icon(Icons.error_outline, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text(_erreur!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 16),
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
}

// ─────────────────────────────────────────────────────────────
// Dialog création UE
// ─────────────────────────────────────────────────────────────
class _DialogCreerUe extends StatefulWidget {
  final List<dynamic> semestres;
  const _DialogCreerUe({required this.semestres});

  @override
  State<_DialogCreerUe> createState() => _DialogCreerUeState();
}

class _DialogCreerUeState extends State<_DialogCreerUe> {
  final _codeCtrl = TextEditingController();
  final _libelleCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _semestreId;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _libelleCtrl.dispose();
    _creditsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_semestreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un semestre'),
            backgroundColor: AppColors.orange),
      );
      return;
    }
    if (_codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un code'),
            backgroundColor: AppColors.orange),
      );
      return;
    }
    if (_libelleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un libellé'),
            backgroundColor: AppColors.orange),
      );
      return;
    }
    final credits = int.tryParse(_creditsCtrl.text.trim());
    if (credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un nombre de crédits valide'),
            backgroundColor: AppColors.orange),
      );
      return;
    }

    Navigator.pop(context, {
      'semestre_id': _semestreId,
      'code': _codeCtrl.text.trim().toUpperCase(),
      'libelle': _libelleCtrl.text.trim(),
      'credits_ects': credits,
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    });
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.library_books,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Créer une UE', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Semestre
            DropdownButtonFormField<int>(
              value: _semestreId,
              isExpanded: true,
              decoration: _deco('Semestre *', Icons.calendar_month),
              items: widget.semestres.map((s) {
                final filiere =
                    s['filiere'] as Map<String, dynamic>? ?? {};
                return DropdownMenuItem<int>(
                  value: s['id'] as int,
                  child: Text(
                    'S${s['numero'] ?? ''} — ${filiere['nom'] ?? 'Sans filière'}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _semestreId = v),
            ),
            const SizedBox(height: 12),

            // Code
            TextFormField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _deco('Code UE * (ex: UE-INFO1)', Icons.tag),
            ),
            const SizedBox(height: 12),

            // Libellé
            TextFormField(
              controller: _libelleCtrl,
              decoration: _deco('Libellé *', Icons.title),
            ),
            const SizedBox(height: 12),

            // Crédits
            TextFormField(
              controller: _creditsCtrl,
              keyboardType: TextInputType.number,
              decoration: _deco('Crédits ECTS *', Icons.stars_outlined),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _deco('Description (optionnel)', Icons.description),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: AppColors.textSub)),
        ),
        ElevatedButton(
          onPressed: _valider,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary),
          child: const Text('Créer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}