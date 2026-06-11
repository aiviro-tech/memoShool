// ============================================================
// FICHIER : lib/features/ecue/ecue_tab.dart
// Page de gestion des ECUE pour l'admin
// Le formulaire de création d'ECUE intègre un bouton
// "+ Nouvelle UE" pour créer une UE sans quitter l'écran.
// ============================================================

import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';

class EcueTab extends StatefulWidget {
  const EcueTab({super.key});

  @override
  State<EcueTab> createState() => _EcueTabState();
}

class _EcueTabState extends State<EcueTab> {
  final _session = SessionUtilisateur();
  List<dynamic> _ecues = [];
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
      final res = await ApiService.getEcues(_session.ecoleId);
      setState(() {
        _ecues = res['data'] as List? ?? [];
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _creerEcue() async {
    // Charger UE et semestres en parallèle
    List<dynamic> ues = [];
    List<dynamic> semestres = [];
    try {
      final resUe = await ApiService.getUes(_session.ecoleId);
      final resSem = await ApiService.getSemestres(_session.ecoleId);
      ues = resUe['data'] as List? ?? [];
      semestres = resSem['data'] as List? ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement : ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final resultat = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogCreerEcue(
        ues: ues,
        semestres: semestres,
        ecoleId: _session.ecoleId,
      ),
    );

    if (resultat == null || !mounted) return;

    try {
      await ApiService.creerEcue(_session.ecoleId, resultat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ECUE créée avec succès !'),
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

  Future<void> _supprimerEcue(int ecueId, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'ECUE "$nom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiService.supprimerEcue(_session.ecoleId, ecueId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ECUE supprimée.'),
              backgroundColor: AppColors.green),
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
                : _ecues.isEmpty
                    ? _buildVide()
                    : _buildListe(),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'fab_ecue',
            onPressed: _creerEcue,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Créer une ECUE',
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
        itemCount: _ecues.length,
        itemBuilder: (_, i) {
          final ecue = _ecues[i] as Map<String, dynamic>;
          final ue = ecue['ue'] as Map<String, dynamic>? ?? {};
          final semestre =
              ue['semestre'] as Map<String, dynamic>? ?? {};
          final filiere =
              semestre['filiere'] as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                    color: AppColors.primary.withOpacity(0.6), width: 4),
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
                    child: const Icon(Icons.book,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ecue['nom'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code : ${ecue['code'] ?? ''} • ${ecue['credits'] ?? 0} crédits',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub),
                        ),
                        Text(
                          'UE : ${ue['libelle'] ?? ''} • S${semestre['numero'] ?? ''} • ${filiere['nom'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.red, size: 20),
                    onPressed: () => _supprimerEcue(
                      ecue['id'] as int,
                      ecue['nom'] ?? '',
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
                Icon(Icons.book_outlined,
                    size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Aucune ECUE créée.',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez d\'abord une UE, puis ajoutez vos ECUEs.',
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
// Dialog création ECUE avec bouton "+ Nouvelle UE" intégré
// ─────────────────────────────────────────────────────────────
class _DialogCreerEcue extends StatefulWidget {
  final List<dynamic> ues;
  final List<dynamic> semestres;
  final int ecoleId;

  const _DialogCreerEcue({
    required this.ues,
    required this.semestres,
    required this.ecoleId,
  });

  @override
  State<_DialogCreerEcue> createState() => _DialogCreerEcueState();
}

class _DialogCreerEcueState extends State<_DialogCreerEcue> {
  final _codeCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  final _coeffCtrl = TextEditingController();
  int? _ueId;
  late List<dynamic> _ues;

  @override
  void initState() {
    super.initState();
    _ues = List.from(widget.ues);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _creditsCtrl.dispose();
    _coeffCtrl.dispose();
    super.dispose();
  }

  // ── Créer une UE directement depuis ce dialog ──────────────
  Future<void> _creerUeALaVolee() async {
    if (widget.semestres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Aucun semestre disponible. Créez d\'abord une filière et un semestre.'),
          backgroundColor: AppColors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final resultat = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogCreerUeInline(semestres: widget.semestres),
    );

    if (resultat == null || !mounted) return;

    try {
      final res = await ApiService.creerUe(widget.ecoleId, resultat);
      final nouvelleUe = res['data'] as Map<String, dynamic>?;
      if (nouvelleUe != null && mounted) {
        setState(() {
          _ues.add(nouvelleUe);
          _ueId = nouvelleUe['id'] as int;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UE créée et sélectionnée !'),
            backgroundColor: AppColors.green,
          ),
        );
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

  void _valider() {
    if (_ueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner une UE'),
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
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un nom'),
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
    final coeff = double.tryParse(_coeffCtrl.text.trim().replaceAll(',', '.'));
    if (coeff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un coefficient valide'),
            backgroundColor: AppColors.orange),
      );
      return;
    }

    Navigator.pop(context, {
      'ue_id': _ueId,
      'code': _codeCtrl.text.trim().toUpperCase(),
      'nom': _nomCtrl.text.trim(),
      'credits': credits,
      'coefficient': coeff,
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
            child:
                const Icon(Icons.book, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Créer une ECUE', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Sélection UE + bouton créer UE ──
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _ueId,
                    isExpanded: true,
                    decoration: _deco('UE *', Icons.library_books),
                    items: _ues.map((u) {
                      return DropdownMenuItem<int>(
                        value: u['id'] as int,
                        child: Text(
                          '${u['code'] ?? ''} — ${u['libelle'] ?? ''}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _ueId = v),
                  ),
                ),
                const SizedBox(width: 6),
                // ← BOUTON CRÉER UE À LA VOLÉE
                Tooltip(
                  message: 'Créer une nouvelle UE',
                  child: InkWell(
                    onTap: _creerUeALaVolee,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.add,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            if (_ues.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 13, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Aucune UE. Cliquez sur + pour en créer une.',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Code
            TextFormField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _deco('Code ECUE * (ex: INF101)', Icons.tag),
            ),
            const SizedBox(height: 12),

            // Nom
            TextFormField(
              controller: _nomCtrl,
              decoration: _deco('Nom de l\'ECUE *', Icons.title),
            ),
            const SizedBox(height: 12),

            // Crédits
            TextFormField(
              controller: _creditsCtrl,
              keyboardType: TextInputType.number,
              decoration: _deco('Crédits *', Icons.stars_outlined),
            ),
            const SizedBox(height: 12),

            // Coefficient
            TextFormField(
              controller: _coeffCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  _deco('Coefficient * (ex: 1.5)', Icons.calculate_outlined),
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
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Créer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dialog création UE depuis l'intérieur du dialog ECUE
// (version allégée sans description)
// ─────────────────────────────────────────────────────────────
class _DialogCreerUeInline extends StatefulWidget {
  final List<dynamic> semestres;
  const _DialogCreerUeInline({required this.semestres});

  @override
  State<_DialogCreerUeInline> createState() => _DialogCreerUeInlineState();
}

class _DialogCreerUeInlineState extends State<_DialogCreerUeInline> {
  final _codeCtrl = TextEditingController();
  final _libelleCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  int? _semestreId;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _libelleCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_semestreId == null ||
        _codeCtrl.text.trim().isEmpty ||
        _libelleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Remplissez tous les champs obligatoires'),
            backgroundColor: AppColors.orange),
      );
      return;
    }
    final credits = int.tryParse(_creditsCtrl.text.trim());
    if (credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Crédits invalides'),
            backgroundColor: AppColors.orange),
      );
      return;
    }
    Navigator.pop(context, {
      'semestre_id': _semestreId,
      'code': _codeCtrl.text.trim().toUpperCase(),
      'libelle': _libelleCtrl.text.trim(),
      'credits_ects': credits,
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
      title: const Text('Nouvelle UE', style: TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    'S${s['numero'] ?? ''} — ${filiere['nom'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _semestreId = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _deco('Code UE *', Icons.tag),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _libelleCtrl,
              decoration: _deco('Libellé *', Icons.title),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _creditsCtrl,
              keyboardType: TextInputType.number,
              decoration: _deco('Crédits ECTS *', Icons.stars_outlined),
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
          onPressed: _valider,
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Créer UE',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}