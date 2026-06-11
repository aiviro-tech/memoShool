// lib/features/paiements/config_frais_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class _C {
  static const bg        = Color(0xFFF5F7FA);
  static const vert      = Color(0xFF1B5E20);
  static const vertClair = Color(0xFF2E7D32);
  static const vertLight = Color(0xFFE8F5E9);
  static const orange    = Color(0xFFE65100);
  static const rouge     = Color(0xFFC62828);
  static const texte     = Color(0xFF1A1A2E);
  static const texteSub  = Color(0xFF6B7280);
  static const blanc     = Colors.white;
  static const border    = Color(0xFFE5E7EB);
}

// ─── Modèles locaux ───────────────────────────────────────────────────────────

class _TypeFraisLocal {
  int?   id;
  final TextEditingController libelleCtrl;
  final TextEditingController montantCtrl;
  bool obligatoire;
  bool estNouveau;

  _TypeFraisLocal({
    this.id,
    String libelle = '',
    String montant = '',
    this.obligatoire = true,
    this.estNouveau = true,
  })  : libelleCtrl = TextEditingController(text: libelle),
        montantCtrl = TextEditingController(text: montant);

  void dispose() {
    libelleCtrl.dispose();
    montantCtrl.dispose();
  }
}

class _EcheanceLocal {
  final TextEditingController libelleCtrl;
  final TextEditingController montantCtrl;
  DateTime? dateLimite;
  int numero;

  _EcheanceLocal({
    String libelle = '',
    String montant = '',
    this.dateLimite,
    required this.numero,
  })  : libelleCtrl = TextEditingController(text: libelle),
        montantCtrl = TextEditingController(text: montant);

  void dispose() {
    libelleCtrl.dispose();
    montantCtrl.dispose();
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────────

class ConfigFraisScreen extends StatefulWidget {
  final int classeId;
  final String classeNom;

  const ConfigFraisScreen({
    super.key,
    required this.classeId,
    required this.classeNom,
  });

  @override
  State<ConfigFraisScreen> createState() => _ConfigFraisScreenState();
}

class _ConfigFraisScreenState extends State<ConfigFraisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _session = SessionUtilisateur();

  // Frais
  final List<_TypeFraisLocal> _frais = [];
  bool _loadingFrais      = true;
  bool _savingFrais       = false;
  // Les champs _erreurFrais et _erreurEcheances sont supprimés car inutilisés

  // Échéances
  final List<_EcheanceLocal> _echeances = [];
  bool _loadingEcheances  = true;
  bool _savingEcheances   = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _chargerFrais();
    _chargerEcheances();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final f in _frais) f.dispose();
    for (final e in _echeances) e.dispose();
    super.dispose();
  }

  // ── Chargement frais ──────────────────────────────────────────────────────
  Future<void> _chargerFrais() async {
    setState(() { _loadingFrais = true; });
    try {
      final res = await ApiService.getTypesFrais(
        _session.ecoleId,
        widget.classeId,
      );
      final liste = (res['data']?['types_frais'] ?? res['data'] ?? []) as List;

      for (final f in _frais) { f.dispose(); }
      _frais.clear();

      for (final item in liste) {
        _frais.add(_TypeFraisLocal(
          id:          item['id'] as int?,
          libelle:     item['libelle'] as String? ?? '',
          montant:     _toStr(item['montant']),
          obligatoire: item['obligatoire'] == true || item['obligatoire'] == 1,
          estNouveau:  false,
        ));
      }

      setState(() => _loadingFrais = false);
    } catch (e) {
      setState(() {
        _loadingFrais = false;
      });
      _snack(e.toString().replaceAll('Exception: ', ''), couleur: _C.rouge);
    }
  }

  // ── Chargement échéances ──────────────────────────────────────────────────
  Future<void> _chargerEcheances() async {
    setState(() { _loadingEcheances = true; });
    try {
      final res = await ApiService.getEcheances(
        _session.ecoleId,
        widget.classeId,
      );
      final liste = (res['data'] ?? []) as List;

      for (final e in _echeances) { e.dispose(); }
      _echeances.clear();

      for (final item in liste) {
        _echeances.add(_EcheanceLocal(
          libelle:    item['libelle'] as String? ?? '',
          montant:    _toStr(item['montant']),
          dateLimite: item['date_limite'] != null
              ? DateTime.tryParse(item['date_limite'].toString())
              : null,
          numero: item['numero'] as int? ?? (_echeances.length + 1),
        ));
      }

      setState(() => _loadingEcheances = false);
    } catch (e) {
      setState(() {
        _loadingEcheances = false;
      });
      _snack(e.toString().replaceAll('Exception: ', ''), couleur: _C.rouge);
    }
  }

  String _toStr(dynamic v) {
    if (v == null) return '';
    if (v is String) return double.tryParse(v)?.toStringAsFixed(0) ?? v;
    if (v is num)   return v.toInt().toString();
    return v.toString();
  }

  // ── Sauvegarder frais ─────────────────────────────────────────────────────
  Future<void> _sauvegarderFrais() async {
    // Validation
    for (int i = 0; i < _frais.length; i++) {
      final f = _frais[i];
      if (f.libelleCtrl.text.trim().isEmpty) {
        _snack('Le libellé du frais ${i + 1} est vide', couleur: _C.rouge);
        return;
      }
      final m = double.tryParse(f.montantCtrl.text.trim());
      if (m == null || m < 0) {
        _snack('Montant invalide pour le frais ${i + 1}', couleur: _C.rouge);
        return;
      }
    }

    setState(() => _savingFrais = true);

    try {
      // Pour chaque frais : créer ou mettre à jour
      for (final f in _frais) {
        final body = {
          'libelle':     f.libelleCtrl.text.trim(),
          'montant':     double.parse(f.montantCtrl.text.trim()),
          'obligatoire': f.obligatoire,
        };

        if (f.estNouveau || f.id == null) {
          // Création
          final res = await ApiService.creerTypeFrais(
            _session.ecoleId,
            widget.classeId,
            body,
          );
          f.id        = res['data']?['id'] as int?;
          f.estNouveau = false;
        } else {
          // Mise à jour
          await ApiService.modifierTypeFrais(
            _session.ecoleId,
            widget.classeId,
            f.id!,
            body,
          );
        }
      }

      _snack('Frais enregistrés avec succès ✓', couleur: _C.vertClair);
      await _chargerFrais(); // Recharger pour avoir les IDs à jour
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), couleur: _C.rouge);
    } finally {
      if (mounted) setState(() => _savingFrais = false);
    }
  }

  // ── Supprimer un frais ────────────────────────────────────────────────────
  Future<void> _supprimerFrais(int index) async {
    final f = _frais[index];

    if (!f.estNouveau && f.id != null) {
      // Supprimer côté serveur
      final confirmed = await _confirmer(
        'Supprimer ce frais ?',
        'Cette action est irréversible.',
      );
      if (!confirmed) return;

      try {
        await ApiService.supprimerTypeFrais(
          _session.ecoleId,
          widget.classeId,
          f.id!,
        );
      } catch (e) {
        _snack(e.toString().replaceAll('Exception: ', ''), couleur: _C.rouge);
        return;
      }
    }

    setState(() {
      _frais[index].dispose();
      _frais.removeAt(index);
    });
  }

  // ── Sauvegarder échéances ─────────────────────────────────────────────────
  Future<void> _sauvegarderEcheances() async {
    if (_echeances.isEmpty) {
      _snack('Ajoutez au moins une échéance', couleur: _C.orange);
      return;
    }

    for (int i = 0; i < _echeances.length; i++) {
      final e = _echeances[i];
      if (e.dateLimite == null) {
        _snack('Date manquante pour l\'échéance ${i + 1}', couleur: _C.rouge);
        return;
      }
      final m = double.tryParse(e.montantCtrl.text.trim());
      if (m == null || m < 0) {
        _snack('Montant invalide pour l\'échéance ${i + 1}', couleur: _C.rouge);
        return;
      }
    }

    setState(() => _savingEcheances = true);

    try {
      final echeancesData = _echeances.asMap().entries.map((entry) {
        return {
          'numero':      entry.key + 1,
          'libelle':     entry.value.libelleCtrl.text.trim().isEmpty
              ? 'Échéance ${entry.key + 1}'
              : entry.value.libelleCtrl.text.trim(),
          'montant':     double.parse(entry.value.montantCtrl.text.trim()),
          'date_limite': entry.value.dateLimite!.toIso8601String().split('T')[0],
        };
      }).toList();

      await ApiService.upsertEcheances(
        _session.ecoleId,
        widget.classeId,
        echeancesData,
      );

      _snack('Échéances enregistrées avec succès ✓', couleur: _C.vertClair);
      await _chargerEcheances();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), couleur: _C.rouge);
    } finally {
      if (mounted) setState(() => _savingEcheances = false);
    }
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────
  void _snack(String msg, {Color couleur = _C.vertClair}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _C.blanc)),
      backgroundColor: couleur,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<bool> _confirmer(String titre, String contenu) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(titre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Text(contenu),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _C.rouge),
                child: const Text('Supprimer',
                    style: TextStyle(color: _C.blanc)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _choisirDate(int index) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _echeances[index].dateLimite ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _C.vertClair),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _echeances[index].dateLimite = picked);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Choisir une date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  double get _totalFraisObligatoires {
    double total = 0;
    for (final f in _frais) {
      if (f.obligatoire) {
        total += double.tryParse(f.montantCtrl.text) ?? 0;
      }
    }
    return total;
  }

  double get _totalEcheances {
    double total = 0;
    for (final e in _echeances) {
      total += double.tryParse(e.montantCtrl.text) ?? 0;
    }
    return total;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Configuration des frais',
              style: TextStyle(
                  color: _C.blanc, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(widget.classeNom,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        backgroundColor: _C.vert,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.blanc),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _C.blanc,
          indicatorWeight: 3,
          labelColor: _C.blanc,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Types de frais'),
            Tab(icon: Icon(Icons.event_note_rounded, size: 18), text: 'Échéances'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildOngletFrais(), _buildOngletEcheances()],
      ),
    );
  }

  // ── Onglet Frais ──────────────────────────────────────────────────────────
  Widget _buildOngletFrais() {
    if (_loadingFrais) {
      return const Center(child: CircularProgressIndicator(color: _C.vertClair));
    }

    return Column(children: [
      // Résumé total
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.vert, Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Total frais obligatoires',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '${_totalFraisObligatoires.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                  color: _C.blanc,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ])),
          Text('${_frais.length} frais',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ),

      // Liste frais
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            if (_frais.isEmpty)
              _buildEtatVide(
                icone: Icons.list_alt_outlined,
                message: 'Aucun frais configuré',
                sousMessage:
                    'Appuyez sur + pour ajouter un frais de scolarité',
              ),
            ..._frais.asMap().entries.map((e) => _buildCarteFrais(e.key)),
          ],
        ),
      ),

      // Barre d'actions
      _buildBarreActions(
        onAjouter: () => setState(() => _frais.add(_TypeFraisLocal())),
        onSauvegarder: _savingFrais ? null : _sauvegarderFrais,
        saving: _savingFrais,
      ),
    ]);
  }

  Widget _buildCarteFrais(int index) {
    final f = _frais[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10), // remplace withOpacity(0.04)
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête carte
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _C.vertClair.withAlpha(26), // remplace withOpacity(0.1)
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: _C.vertClair,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Type de frais',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _C.texte)),
            ),
            // Switch obligatoire
            Row(children: [
              Text(
                f.obligatoire ? 'Obligatoire' : 'Facultatif',
                style: TextStyle(
                    fontSize: 11,
                    color: f.obligatoire ? _C.vertClair : _C.texteSub),
              ),
              const SizedBox(width: 4),
              Switch(
                value: f.obligatoire,
                onChanged: (v) => setState(() => f.obligatoire = v),
                activeThumbColor: _C.vertClair, // remplace activeColor
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: _C.rouge, size: 20),
              onPressed: () => _supprimerFrais(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 12),

          // Libellé
          _champTexte(
            controller: f.libelleCtrl,
            label: 'Libellé (ex: Frais de scolarité)',
            icone: Icons.label_outline,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Montant
          _champMontant(
            controller: f.montantCtrl,
            label: 'Montant (FCFA)',
            onChanged: (_) => setState(() {}),
          ),

          // Badge obligatoire
          if (f.obligatoire) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _C.vertLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline,
                    color: _C.vertClair, size: 12),
                SizedBox(width: 4),
                Text('Inclus dans le total obligatoire',
                    style: TextStyle(color: _C.vertClair, fontSize: 11)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Onglet Échéances ──────────────────────────────────────────────────────
  Widget _buildOngletEcheances() {
    if (_loadingEcheances) {
      return const Center(child: CircularProgressIndicator(color: _C.vertClair));
    }

    return Column(children: [
      // Résumé
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.event_note_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Total des échéances',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '${_totalEcheances.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                  color: _C.blanc,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ])),
          Text('${_echeances.length} échéance(s)',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ),

      // Avertissement si total != total frais
      if (_frais.isNotEmpty &&
          _totalEcheances > 0 &&
          (_totalEcheances - _totalFraisObligatoires).abs() > 1)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _C.orange.withAlpha(20), // remplace withOpacity(0.08)
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.orange.withAlpha(77)), // remplace withOpacity(0.3)
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: _C.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Le total des échéances (${_totalEcheances.toStringAsFixed(0)} FCFA) '
                'diffère du total des frais obligatoires '
                '(${_totalFraisObligatoires.toStringAsFixed(0)} FCFA).',
                style:
                    const TextStyle(color: _C.orange, fontSize: 11),
              ),
            ),
          ]),
        ),

      // Liste échéances
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            if (_echeances.isEmpty)
              _buildEtatVide(
                icone: Icons.event_note_outlined,
                message: 'Aucune échéance configurée',
                sousMessage:
                    'Définissez les dates limites de paiement par tranche',
              ),
            ..._echeances.asMap().entries.map((e) => _buildCarteEcheance(e.key)),
          ],
        ),
      ),

      _buildBarreActions(
        onAjouter: () => setState(() => _echeances.add(
              _EcheanceLocal(numero: _echeances.length + 1),
            )),
        onSauvegarder: _savingEcheances ? null : _sauvegarderEcheances,
        saving: _savingEcheances,
        labelAjouter: 'Ajouter une échéance',
      ),
    ]);
  }

  Widget _buildCarteEcheance(int index) {
    final e = _echeances[index];
    final dateOk = e.dateLimite != null;
    final estRetard = dateOk && e.dateLimite!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: estRetard
                ? _C.rouge.withAlpha(102) // remplace withOpacity(0.4)
                : _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10), // remplace withOpacity(0.04)
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(26), // remplace withOpacity(0.1)
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Tranche ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _C.texte)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: _C.rouge, size: 20),
              onPressed: () => setState(() {
                _echeances[index].dispose();
                _echeances.removeAt(index);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 12),

          // Libellé (optionnel)
          _champTexte(
            controller: e.libelleCtrl,
            label: 'Libellé (optionnel, ex: 1ère tranche)',
            icone: Icons.label_outline,
          ),
          const SizedBox(height: 10),

          // Montant
          _champMontant(
            controller: e.montantCtrl,
            label: 'Montant (FCFA)',
          ),
          const SizedBox(height: 10),

          // Date limite
          GestureDetector(
            onTap: () => _choisirDate(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: !dateOk
                        ? _C.orange.withAlpha(128) // remplace withOpacity(0.5)
                        : estRetard
                            ? _C.rouge.withAlpha(102) // remplace withOpacity(0.4)
                            : Colors.transparent),
              ),
              child: Row(children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: !dateOk
                      ? _C.orange
                      : estRetard
                          ? _C.rouge
                          : _C.vertClair,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(e.dateLimite),
                    style: TextStyle(
                      fontSize: 14,
                      color: !dateOk
                          ? _C.orange
                          : estRetard
                              ? _C.rouge
                              : _C.texte,
                    ),
                  ),
                ),
                Text(
                  !dateOk
                      ? 'Requis'
                      : estRetard
                          ? 'Date passée'
                          : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: !dateOk ? _C.orange : _C.rouge,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Widgets réutilisables ─────────────────────────────────────────────────
  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icone, color: _C.vertClair, size: 18),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.vertClair, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(fontSize: 13),
        ),
      );

  Widget _champMontant({
    required TextEditingController controller,
    required String label,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.attach_money_rounded, color: _C.vertClair, size: 18),
          suffixText: 'FCFA',
          suffixStyle:
              const TextStyle(color: _C.texteSub, fontSize: 12),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.vertClair, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(fontSize: 13),
        ),
      );

  Widget _buildEtatVide({
    required IconData icone,
    required String message,
    required String sousMessage,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(children: [
            Icon(icone, size: 56, color: _C.texteSub.withAlpha(77)), // remplace withOpacity(0.3)
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    color: _C.texteSub,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(sousMessage,
                style: const TextStyle(color: _C.texteSub, fontSize: 12),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildBarreActions({
    required VoidCallback onAjouter,
    required VoidCallback? onSauvegarder,
    required bool saving,
    String labelAjouter = 'Ajouter un frais',
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: _C.blanc,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20), // remplace withOpacity(0.08)
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            // Bouton ajouter
            OutlinedButton.icon(
              onPressed: onAjouter,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(labelAjouter,
                  style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.vertClair,
                side: const BorderSide(color: _C.vertClair),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            // Bouton sauvegarder
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSauvegarder,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: _C.blanc, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded,
                        size: 18, color: _C.blanc),
                label: Text(
                  saving ? 'Enregistrement...' : 'Enregistrer',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _C.blanc),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      onSauvegarder == null ? Colors.grey : _C.vertClair,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      );
}