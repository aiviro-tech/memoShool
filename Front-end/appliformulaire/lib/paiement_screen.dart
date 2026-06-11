// lib/paiement_screen.dart
import 'package:flutter/material.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/paiement_model.dart';
import 'package:appliformulaire/services/paiement_service.dart';
import 'package:appliformulaire/features/paiements/fedapay_webview_screen.dart';
import 'package:open_file/open_file.dart'; //  Remplace url_launcher

class _PC {
  static const bg          = Color(0xFFF5F7FA);
  static const vert        = Color(0xFF1B5E20);
  static const vertClair   = Color(0xFF2E7D32);
  static const vertAccent  = Color(0xFF43A047);
  static const mtn         = Color(0xFFFFCC00);
  static const moov        = Color(0xFF0057A8);
  static const rouge       = Color(0xFFC62828);
  static const orange      = Color(0xFFE65100);
  static const texte       = Color(0xFF1A1A2E);
  static const texteSub    = Color(0xFF6B7280);
  static const blanc       = Colors.white;
}

class PaiementsScreen extends StatefulWidget {
  const PaiementsScreen({super.key});
  @override
  State<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends State<PaiementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PaiementService();
  final _session = SessionUtilisateur();

  FraisEtudiantModel? _frais;
  List<PaiementModel> _historique = [];
  bool _loading     = true;
  String? _error;
  bool _loadingAction = false;

  final Set<int> _recuEnCours = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Chargement ────────────────────────────────────────────────────────────

  Future<void> _chargerDonnees() async {
    final ecoleId = _session.ecoleId;
    if (ecoleId == 0) return;
    setState(() { _loading = true; _error = null; });
    try {
      final frais      = await _service.getFraisEtudiant(ecoleId);
      final historique = await _service.getHistorique(ecoleId);
      setState(() {
        _frais      = frais;
        _historique = historique;
        _loading    = false;
      });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = msg.contains('inscription active')
            ? 'Aucune inscription active.\nContactez votre administration.'
            : msg;
        _loading = false;
      });
    }
  }

  // ── Vérifier statut ───────────────────────────────────────────────────────

  Future<void> _verifierStatut(PaiementModel p) async {
    setState(() => _loadingAction = true);
    try {
      final updated = await _service.verifierStatut(_session.ecoleId, p.id);
      if (updated != null && mounted) {
        await _chargerDonnees();
        _snack(
          'Statut : ${updated.libelleStatut}',
          couleur: updated.estApprouve ? _PC.vertClair : _PC.orange,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  // ── Télécharger / Générer reçu ────────────────────────────────────────────
  //
  //  CORRECTION : On télécharge le PDF en bytes via Dio (token Bearer inclus
  // automatiquement), on le sauvegarde en local, puis on l'ouvre avec open_file.
  // Avant : launchUrl ouvrait un navigateur externe sans token → 401.
  //
  Future<void> _obtenirRecu(PaiementModel p) async {
    if (_recuEnCours.contains(p.id)) return;
    setState(() => _recuEnCours.add(p.id));

    try {
      // Étape 1 : générer le reçu côté serveur si pas encore fait
      if (!p.aRecu) {
        final result = await _service.genererRecu(_session.ecoleId, p.id);
        if (!mounted) return;
        if (result['success'] != true) {
          _snack(
            result['message'] ?? 'Erreur lors de la génération',
            couleur: _PC.rouge,
          );
          return;
        }
        await _chargerDonnees();
      }

      if (!mounted) return;

      // Étape 2 : télécharger en local (Dio porte le token → pas de 401)
      final filePath = await _service.telechargerRecuEnLocal(
        _session.ecoleId,
        p.id,
      );

      if (!mounted) return;

      // Étape 3 : ouvrir le PDF avec l'app native (lecteur PDF du téléphone)
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        _snack(
          'Impossible d\'ouvrir le reçu : ${result.message}',
          couleur: _PC.rouge,
        );
      } else {
        _snack('Reçu ouvert avec succès', couleur: _PC.vertClair);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), couleur: _PC.rouge);
      }
    } finally {
      if (mounted) setState(() => _recuEnCours.remove(p.id));
    }
  }

  void _snack(String msg, {Color couleur = _PC.vertClair}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: couleur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Dialog paiement ───────────────────────────────────────────────────────

  void _afficherDialogPaiement() {
    if (_frais?.inscriptionId == null) {
      _snack(
        'Aucune inscription trouvée. Contactez l\'administration.',
        couleur: _PC.rouge,
      );
      return;
    }

    final fraisConfigures = _frais!.fraisConfigures;
    final soldeRestant    = _frais!.soldeRestant;
    final montantTotal    = _frais!.montantTotal;

    String modePaiement  = 'mtn_money';
    final montantCtrl    = TextEditingController(
      text: soldeRestant > 0 ? soldeRestant.toStringAsFixed(0) : '',
    );
    final telCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _PC.vertClair.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payment_rounded,
                            color: _PC.vertClair, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Effectuer un paiement',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _PC.texte),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Résumé solde
                  if (fraisConfigures && montantTotal > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _PC.vertClair.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _PC.vertClair.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _ligneResume('Total scolarité',
                              '${montantTotal.toStringAsFixed(0)} FCFA'),
                          const SizedBox(height: 4),
                          _ligneResume('Déjà payé',
                              '${_frais!.montantPaye.toStringAsFixed(0)} FCFA',
                              couleur: _PC.vertClair),
                          const Divider(height: 12),
                          _ligneResume(
                            'Reste à payer',
                            '${soldeRestant.toStringAsFixed(0)} FCFA',
                            couleur: soldeRestant > 0 ? _PC.rouge : _PC.vertClair,
                            gras: true,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _PC.orange.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _PC.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: _PC.orange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les frais de votre classe ne sont pas encore configurés. '
                              'Vous pouvez quand même effectuer un acompte.',
                              style: TextStyle(fontSize: 12, color: _PC.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Info tranche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous pouvez payer une tranche ou la totalité.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Montant
                  TextFormField(
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecor('Montant à payer (FCFA)', Icons.attach_money),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ obligatoire';
                      final m = double.tryParse(v);
                      if (m == null || m <= 0) return 'Montant invalide';
                      if (fraisConfigures && soldeRestant > 0 && m > soldeRestant) {
                        return 'Dépasse le solde restant (${soldeRestant.toStringAsFixed(0)} FCFA)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Téléphone
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecor('Numéro de téléphone', Icons.phone),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ obligatoire';
                      if (v.replaceAll(RegExp(r'\D'), '').length < 8) {
                        return 'Numéro invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mode paiement
                  const Text(
                    'Mode de paiement',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _PC.texte),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _modeOptionAvecLogo(
                        setLocal,
                        value: 'mtn_money',
                        label: 'MTN MoMo',
                        logoPath: 'assets/images/mtn_logo.png',
                        couleur: _PC.mtn,
                        selected: modePaiement,
                        onSelect: (v) => setLocal(() => modePaiement = v),
                      ),
                      const SizedBox(width: 10),
                      _modeOptionAvecLogo(
                        setLocal,
                        value: 'moov_money',
                        label: 'Moov Money',
                        logoPath: 'assets/images/moov_logo.png',
                        couleur: _PC.moov,
                        selected: modePaiement,
                        onSelect: (v) => setLocal(() => modePaiement = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bouton payer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_outline, size: 18, color: _PC.blanc),
                      label: const Text(
                        'Payer maintenant',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _PC.blanc),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _PC.vertClair,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        final montant = double.parse(montantCtrl.text);
                        setState(() => _loadingAction = true);
                        try {
                          final result = await _service.initierPaiement(
                            _session.ecoleId,
                            inscriptionId: _frais!.inscriptionId!,
                            montant: montant,
                            modePaiement: modePaiement,
                            telephone: telCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          if (result['success'] == true &&
                              result['payment_url'] != null) {
                            final paymentUrl = result['payment_url'] as String;
                            final res = await Navigator.push<FedaPayResultat>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FedaPayWebViewScreen(
                                  paymentUrl: paymentUrl,
                                  titre: modePaiement == 'mtn_money'
                                      ? 'MTN MoMo'
                                      : 'Moov Money',
                                ),
                              ),
                            );
                            await _chargerDonnees();
                            if (res == FedaPayResultat.approuve) {
                              _snack('Paiement approuvé !', couleur: _PC.vertClair);
                              _tabController.animateTo(1);
                            } else if (res == FedaPayResultat.annule) {
                              _snack('Paiement annulé', couleur: _PC.orange);
                            } else {
                              _snack('Vérifiez votre téléphone pour confirmer',
                                  couleur: _PC.orange);
                            }
                          } else {
                            _snack(result['message'] ?? 'Erreur lors de l\'initiation',
                                couleur: _PC.rouge);
                          }
                        } catch (e) {
                          if (mounted) {
                            _snack(e.toString().replaceAll('Exception: ', ''),
                                couleur: _PC.rouge);
                          }
                        } finally {
                          if (mounted) setState(() => _loadingAction = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _ligneResume(String label, String valeur,
      {Color? couleur, bool gras = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _PC.texteSub)),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 13,
              fontWeight: gras ? FontWeight.bold : FontWeight.w600,
              color: couleur ?? _PC.texte,
            ),
          ),
        ],
      );

  Widget _modeOptionAvecLogo(
    StateSetter setLocal, {
    required String value,
    required String label,
    required String logoPath,
    required Color couleur,
    required String selected,
    required Function(String) onSelect,
  }) {
    final ok = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: ok ? couleur.withOpacity(0.12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ok ? couleur : Colors.grey[300]!,
              width: ok ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  logoPath,
                  height: 36,
                  width: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.payment, color: couleur, size: 32),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: ok ? FontWeight.bold : FontWeight.normal,
                  color: ok ? couleur : _PC.texteSub,
                ),
                textAlign: TextAlign.center,
              ),
              if (ok) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle, color: couleur, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoMode(String modePaiement) {
    final logoPath = modePaiement == 'mtn_money'
        ? 'assets/images/mtn_logo.png'
        : 'assets/images/moov_logo.png';
    final couleur = modePaiement == 'mtn_money' ? _PC.mtn : _PC.moov;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        logoPath,
        height: 28,
        width: 44,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.payment, color: couleur, size: 24),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _PC.vertClair, size: 20),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _PC.vertClair, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      appBar: AppBar(
        title: const Text(
          'Paiements',
          style: TextStyle(fontWeight: FontWeight.bold, color: _PC.blanc),
        ),
        backgroundColor: _PC.vert,
        elevation: 0,
        iconTheme: const IconThemeData(color: _PC.blanc),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _chargerDonnees,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _PC.blanc,
          indicatorWeight: 3,
          labelColor: _PC.blanc,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Mon Solde'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Historique'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: _PC.vertClair))
              : _error != null
                  ? _buildErreur()
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildSoldeTab(), _buildHistoriqueTab()],
                    ),
          if (_loadingAction)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _PC.vertClair),
                        SizedBox(height: 12),
                        Text('Traitement en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          (!_loading && _error == null && _frais != null && !_session.estAdmin)
              ? FloatingActionButton.extended(
                  onPressed: _frais!.estSolde ? null : _afficherDialogPaiement,
                  backgroundColor:
                      _frais!.estSolde ? Colors.grey[600] : _PC.vertClair,
                  icon: Icon(
                    _frais!.estSolde ? Icons.check_rounded : Icons.payment_rounded,
                    color: _PC.blanc,
                  ),
                  label: Text(
                    _frais!.estSolde ? 'Scolarité soldée' : 'Payer une tranche',
                    style: const TextStyle(
                        color: _PC.blanc, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
    );
  }

  // ── Onglet Solde ──────────────────────────────────────────────────────────

  Widget _buildSoldeTab() {
    if (_frais == null) {
      return const Center(child: Text('Aucune inscription active'));
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: _PC.vertClair,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCarteSolde(),
            const SizedBox(height: 16),
            if (!_frais!.fraisConfigures)
              _buildAlerteFraisNonConfigures()
            else ...[
              _buildCarteDetailFrais(),
              const SizedBox(height: 16),
              if (_frais!.echeances.isNotEmpty) _buildCarteEcheances(),
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerteFraisNonConfigures() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _PC.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _PC.orange.withOpacity(0.4)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _PC.orange, size: 22),
                SizedBox(width: 10),
                Text(
                  'Frais non configurés',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _PC.orange),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Les frais de scolarité de votre classe ne sont pas encore définis par l\'administration.\n\n'
              'Vous pouvez quand même effectuer un paiement en appuyant sur "Payer une tranche" ci-dessous.',
              style: TextStyle(fontSize: 13, color: _PC.orange, height: 1.5),
            ),
          ],
        ),
      );

  Widget _buildCarteSolde() {
    final pct      = _frais!.pourcentagePaye;
    final estSolde = _frais!.estSolde;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estSolde
              ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
              : [_PC.vert, _PC.vertAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _PC.vertClair.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                estSolde
                    ? Icons.check_circle_rounded
                    : Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                estSolde ? 'Scolarité soldée ✓' : 'Solde restant à payer',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            !_frais!.fraisConfigures
                ? 'Non défini'
                : '${_frais!.soldeRestant.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              color: _PC.blanc,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (_frais!.anneeAcademique != null) ...[
            const SizedBox(height: 4),
            Text(
              'Année ${_frais!.anneeAcademique}'
              '${_frais!.nomClasse != null ? ' · ${_frais!.nomClasse}' : ''}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
          if (_frais!.fraisConfigures && _frais!.montantTotal > 0) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                  pct >= 1.0 ? Colors.white : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoSolde('Payé', _frais!.montantPaye, Colors.white70),
                _infoSolde('Total', _frais!.montantTotal, Colors.white54,
                    right: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoSolde(String label, double montant, Color couleur,
      {bool right = false}) =>
      Column(
        crossAxisAlignment:
            right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: couleur, fontSize: 11)),
          Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
                color: _PC.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      );

  Widget _buildCarteDetailFrais() => Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: _PC.vertClair, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Détail des frais',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _PC.texte),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_frais!.typesFrais.isEmpty)
                const Text('Aucun frais configuré pour votre classe.',
                    style: TextStyle(color: _PC.texteSub))
              else ...[
                ..._frais!.typesFrais.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: t.obligatoire ? _PC.vertClair : _PC.texteSub,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(t.libelle,
                                style: const TextStyle(
                                    fontSize: 14, color: _PC.texte)),
                          ),
                          if (t.obligatoire)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _PC.vertClair.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Obligatoire',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _PC.vertClair,
                                      fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(width: 8),
                          Text('${t.montant.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _PC.texte)),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total obligatoire',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${_frais!.montantTotal.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _PC.vertClair)),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildCarteEcheances() => Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_note_rounded,
                      color: _PC.vertClair, size: 20),
                  SizedBox(width: 8),
                  Text('Échéances de paiement',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _PC.texte)),
                ],
              ),
              const SizedBox(height: 14),
              ..._frais!.echeances.map((e) {
                final retard = e.estEnRetard;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: retard
                        ? _PC.rouge.withOpacity(0.06)
                        : _PC.vertClair.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: retard
                          ? _PC.rouge.withOpacity(0.3)
                          : _PC.vertClair.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        retard
                            ? Icons.warning_amber_rounded
                            : Icons.event_rounded,
                        color: retard ? _PC.rouge : _PC.vertClair,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.libelle ?? 'Échéance ${e.numero}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              retard
                                  ? 'En retard · ${e.dateLimiteFormatee}'
                                  : 'Avant le ${e.dateLimiteFormatee}',
                              style: TextStyle(
                                  color: retard ? _PC.rouge : _PC.texteSub,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text('${e.montant.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: retard ? _PC.rouge : _PC.vertClair)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  // ── Onglet Historique ─────────────────────────────────────────────────────

  Widget _buildHistoriqueTab() {
    if (_historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: _PC.vertClair.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Aucun paiement effectué',
                style: TextStyle(color: _PC.texteSub, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur "Payer une tranche" pour commencer',
              style: TextStyle(color: _PC.texteSub, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: _PC.vertClair,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historique.length,
        itemBuilder: (_, i) => _buildCartePaiement(_historique[i]),
      ),
    );
  }

  // ── Carte paiement ────────────────────────────────────────────────────────

  Widget _buildCartePaiement(PaiementModel p) {
    final enCours = _recuEnCours.contains(p.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (p.modePaiement == 'mtn_money' ? _PC.mtn : _PC.moov)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: _logoMode(p.modePaiement)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.libelleMode,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _PC.texte),
                      ),
                      Text(
                        p.dateFormatee,
                        style:
                            const TextStyle(color: _PC.texteSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _PC.texte),
                    ),
                    const SizedBox(height: 4),
                    _badgeStatut(p),
                  ],
                ),
              ],
            ),

            if (p.numeroRecu != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 13, color: _PC.texteSub),
                  const SizedBox(width: 4),
                  Text('Réf : ${p.numeroRecu}',
                      style:
                          const TextStyle(color: _PC.texteSub, fontSize: 11)),
                ],
              ),
            ],

            if (p.estEnAttente || p.estApprouve) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (p.estEnAttente)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Vérifier statut',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _PC.orange,
                          side: const BorderSide(color: _PC.orange),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _verifierStatut(p),
                      ),
                    ),

                  if (p.estApprouve) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: enCours
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: _PC.blanc,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                p.aRecu
                                    ? Icons.download_rounded
                                    : Icons.picture_as_pdf_rounded,
                                size: 16,
                                color: _PC.blanc,
                              ),
                        label: Text(
                          enCours
                              ? 'Téléchargement...'
                              : p.aRecu
                                  ? 'Télécharger le reçu'
                                  : 'Obtenir le reçu',
                          style: const TextStyle(
                              fontSize: 12,
                              color: _PC.blanc,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              p.aRecu ? _PC.vertClair : const Color(0xFF1565C0),
                          disabledBackgroundColor:
                              _PC.vertClair.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: enCours ? null : () => _obtenirRecu(p),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (!p.estEnAttente && !p.estApprouve) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _PC.rouge.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: _PC.rouge, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ce paiement n\'a pas abouti. Contactez l\'administration si besoin.',
                        style: TextStyle(fontSize: 11, color: _PC.rouge),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badgeStatut(PaiementModel p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: p.couleurStatut.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              p.estApprouve
                  ? Icons.check_circle
                  : p.estEnAttente
                      ? Icons.hourglass_top
                      : Icons.cancel,
              size: 10,
              color: p.couleurStatut,
            ),
            const SizedBox(width: 4),
            Text(
              p.libelleStatut,
              style: TextStyle(
                  color: p.couleurStatut,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  // ── Erreur ────────────────────────────────────────────────────────────────

  Widget _buildErreur() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: _PC.rouge),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _PC.rouge, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _PC.vertClair,
                  foregroundColor: _PC.blanc,
                ),
                onPressed: _chargerDonnees,
              ),
            ],
          ),
        ),
      );
}