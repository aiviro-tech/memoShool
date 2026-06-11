import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/services/api_service.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _enAttente = [];
  List<dynamic> _traitees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerEcoles();
  }

  Future<void> _chargerEcoles() async {
    try {
      final pending = await ApiService.ecolesEnAttente();
      final traitees = await ApiService.getEcolesTraitees();
      if (!mounted) return;
      setState(() {
        _enAttente = pending;
        _traitees = traitees;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _activer(dynamic compte) async {
    try {
      await ApiService.activerEcole(compte['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${compte['nom_officiel']} activée"),
          backgroundColor: AppColors.green,
        ),
      );
      _chargerEcoles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur $e"), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _supprimer(dynamic compte) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer l'école"),
        content: const Text(
          "Voulez-vous vraiment supprimer cette école et toutes ses données ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirmation != true) return;
    try {
      await ApiService.supprimerEcole(compte['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ ${compte['nom_officiel']} supprimée"),
          backgroundColor: AppColors.green,
        ),
      );
      _chargerEcoles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur $e"), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _refuser(dynamic compte) async {
    final motifController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Motif du refus"),
        content: TextField(
          controller: motifController,
          decoration: const InputDecoration(
            hintText: "Expliquez la raison du refus...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await ApiService.refuserEcole(
                  compte['id'],
                  motifController.text,
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("❌ ${compte['nom_officiel']} refusée"),
                    backgroundColor: AppColors.red,
                  ),
                );
                _chargerEcoles();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Erreur $e"),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Refuser"),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORRECTION PRINCIPALE : téléchargement via Dio (avec token Bearer)
  // au lieu de launchUrl qui échoue sur HTTP local et sans authentification
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _telechargerDocument(int ecoleId, String documentType) async {
    // Afficher un indicateur de chargement
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Téléchargement en cours...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // 1. Récupérer les bytes du fichier via Dio
      //    Le token Bearer est déjà dans les headers de ApiService.dio
      //    La route utilise ?token= mais on peut aussi passer par l'endpoint
      //    normal en ajoutant le token dans les headers Dio
      final response = await ApiService.dio.get(
        '/api/ecoles/$ecoleId/document/$documentType',
        queryParameters: {'token': ApiService.getToken()},
        options: Options(responseType: ResponseType.bytes),
      );

      // 2. Déterminer l'extension à partir du Content-Type ou du nom
      final contentType =
          response.headers.value('content-type') ?? 'application/octet-stream';
      final extension = _extensionDepuisContentType(contentType);

      // 3. Sauvegarder dans le dossier temporaire de l'appareil
      final tempDir = await getTemporaryDirectory();
      final nomFichier = '${documentType}_ecole_$ecoleId$extension';
      final fichier = File('${tempDir.path}/$nomFichier');
      await fichier.writeAsBytes(response.data as List<int>);

      if (!mounted) return;
      // Masquer le snackbar de chargement
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 4. Ouvrir le fichier avec l'application native (visionneuse PDF, galerie…)
      final result = await OpenFile.open(fichier.path);

      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d\'ouvrir le fichier : ${result.message}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String message = 'Erreur lors du téléchargement';
      if (e.response?.statusCode == 401) {
        message = 'Non autorisé — token invalide ou expiré';
      } else if (e.response?.statusCode == 404) {
        message = 'Document introuvable sur le serveur';
      } else if (e.response?.statusCode == 403) {
        message = 'Accès refusé';
      } else {
        message = 'Erreur réseau : ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Déduit l'extension du fichier à partir du Content-Type HTTP
  String _extensionDepuisContentType(String contentType) {
    if (contentType.contains('pdf')) return '.pdf';
    if (contentType.contains('jpeg') || contentType.contains('jpg')) {
      return '.jpg';
    }
    if (contentType.contains('png')) return '.png';
    if (contentType.contains('gif')) return '.gif';
    if (contentType.contains('webp')) return '.webp';
    // Fallback : on laisse sans extension, OpenFile se débrouille
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, size: 20),
            SizedBox(width: 8),
            Text("Super Admin", style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Connexion()),
              (r) => false,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.hourglass_empty, size: 18),
              text: "En attente (${_enAttente.length})",
            ),
            Tab(
              icon: const Icon(Icons.done_all, size: 18),
              text: "Traitées (${_traitees.length})",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Onglet "En attente" ──────────────────────────────────────────
          _enAttente.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Aucune demande en attente",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerEcoles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enAttente.length,
                    itemBuilder: (context, index) {
                      final compte = _enAttente[index];
                      return _CarteCompte(
                        compte: compte,
                        onActiver: () => _activer(compte),
                        onRefuser: () => _refuser(compte),
                        onTelecharger: (documentType) =>
                            _telechargerDocument(compte['id'], documentType),
                      );
                    },
                  ),
                ),

          // ── Onglet "Traitées" ────────────────────────────────────────────
          _traitees.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun historique traité",
                    style: TextStyle(color: AppColors.textSub),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerEcoles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _traitees.length,
                    itemBuilder: (context, index) {
                      final compte = _traitees[index];
                      return _CarteCompteTraite(
                        compte: compte,
                        onSupprimer: () => _supprimer(compte),
                        onTelecharger: (documentType) =>
                            _telechargerDocument(compte['id'], documentType),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget carte école en attente
// ─────────────────────────────────────────────────────────────────────────────
class _CarteCompte extends StatelessWidget {
  final dynamic compte;
  final VoidCallback onActiver;
  final VoidCallback onRefuser;
  final Function(String) onTelecharger;

  const _CarteCompte({
    required this.compte,
    required this.onActiver,
    required this.onRefuser,
    required this.onTelecharger,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête école ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compte['nom_officiel'] ?? 'École',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        "${compte['ville'] ?? ''}  ${compte['type_etablissement'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Responsable & email ────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 6),
                Text(
                  "Responsable : ${compte['nom_responsable'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    compte['email_principal'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  (compte['created_at'] ?? '').toString().split('T')[0],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Boutons d'action ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _afficherDetails(context),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text("Détails"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.textSub),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefuser,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Refuser"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onActiver,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Activer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _afficherDetails(BuildContext context) {
    _showDetailsDialog(context, compte, onTelecharger);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fonction partagée : dialog de détails
// ─────────────────────────────────────────────────────────────────────────────
void _showDetailsDialog(
  BuildContext context,
  dynamic compte,
  Function(String) onTelecharger,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(compte['nom_officiel'] ?? 'Détails'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoLigneShared(
              "Responsable",
              "${compte['nom_responsable'] ?? ''} (${compte['titre_responsable'] ?? ''})",
            ),
            _infoLigneShared(
              "Email principal",
              compte['email_principal'] ?? '',
            ),
            _infoLigneShared(
              "Téléphone",
              "${compte['tel_fixe'] ?? ''} / ${compte['tel_mobile'] ?? ''}",
            ),
            _infoLigneShared(
              "Adresse",
              "${compte['adresse'] ?? ''}, ${compte['ville'] ?? ''}, ${compte['pays'] ?? ''}",
            ),
            _infoLigneShared("Type", compte['type_etablissement'] ?? ''),
            _infoLigneShared("Site Web", compte['site_web'] ?? ''),
            const SizedBox(height: 8),
            _infoLigneShared(
              "Description",
              compte['description_complete'] ??
                  compte['description_courte'] ??
                  '',
            ),

            if (compte['statut'] != null) ...[
              const SizedBox(height: 8),
              _infoLigneShared("Statut", compte['statut']),
            ],

            if (compte['motif_refus'] != null) ...[
              const SizedBox(height: 4),
              _infoLigneShared("Motif du refus", compte['motif_refus']),
            ],

            // Section documents
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "📎 Documents justificatifs",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            if (compte['autorisation_fichier'] != null)
              _buildDocumentButtonShared(
                "📄 Autorisation d'ouverture",
                () => onTelecharger('autorisation'),
              ),
            if (compte['registre_commerce_fichier'] != null)
              _buildDocumentButtonShared(
                '📑 Registre de commerce',
                () => onTelecharger('registre_commerce'),
              ),
            if (compte['ifu_fichier'] != null)
              _buildDocumentButtonShared('📄 IFU', () => onTelecharger('ifu')),
            if (compte['logo_fichier'] != null)
              _buildDocumentButtonShared(
                "🖼️ Logo de l'établissement",
                () => onTelecharger('logo'),
              ),
            if (compte['façade_fichier'] != null)
              _buildDocumentButtonShared(
                '🏫 Photo de façade',
                () => onTelecharger('façade'),
              ),
            if (compte['piece_identite_fichier'] != null)
              _buildDocumentButtonShared(
                "🆔 Pièce d'identité du responsable",
                () => onTelecharger('piece_identite'),
              ),
            if (compte['cachet_fichier'] != null)
              _buildDocumentButtonShared(
                '🖊️ Cachet officiel',
                () => onTelecharger('cachet'),
              ),

            if (compte['autorisation_fichier'] == null &&
                compte['registre_commerce_fichier'] == null &&
                compte['ifu_fichier'] == null &&
                compte['logo_fichier'] == null &&
                compte['façade_fichier'] == null &&
                compte['piece_identite_fichier'] == null &&
                compte['cachet_fichier'] == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Aucun document soumis.",
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Fermer"),
        ),
      ],
    ),
  );
}

// Helpers partagés
Widget _infoLigneShared(String label, String valeur) {
  if (valeur.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textMain),
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: valeur),
        ],
      ),
    ),
  );
}

Widget _buildDocumentButtonShared(String label, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download_rounded, size: 16),
        label: Text(label, textAlign: TextAlign.left),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget carte école traitée
// ─────────────────────────────────────────────────────────────────────────────
class _CarteCompteTraite extends StatelessWidget {
  final dynamic compte;
  final VoidCallback onSupprimer;
  final Function(String) onTelecharger;

  const _CarteCompteTraite({
    required this.compte,
    required this.onSupprimer,
    required this.onTelecharger,
  });

  @override
  Widget build(BuildContext context) {
    final estActive = compte['statut'] == 'active';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: estActive
                      ? AppColors.green.withValues(alpha: 0.1)
                      : AppColors.red.withValues(alpha: 0.1),
                  child: Icon(
                    estActive ? Icons.check_circle : Icons.cancel,
                    color: estActive ? AppColors.green : AppColors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compte['nom_officiel'] ?? 'École',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compte['nom_responsable'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estActive
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estActive ? "Active" : "Refusée",
                    style: TextStyle(
                      fontSize: 11,
                      color: estActive ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (!estActive && compte['motif_refus'] != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  "Motif : ${compte['motif_refus']}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showDetailsDialog(context, compte, onTelecharger),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text("Détails"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text("Supprimer"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
