import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/services/api_service.dart';

// Données locales retirées car remplacées par API.

// ================================================
// PAGE SUPER ADMIN
// ================================================
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerEcoles();
  }

  Future<void> _chargerEcoles() async {
    setState(() => _isLoading = true);
    try {
      final pending = await ApiService.ecolesEnAttente();
      final traitees = await ApiService.getEcolesTraitees();
      setState(() {
        _enAttente = pending;
        _traitees = traitees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${compte['nom_officiel']} activée"),
          backgroundColor: AppColors.green,
        ),
      );
      _chargerEcoles();
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ ${compte['nom_officiel']} supprimée"),
          backgroundColor: AppColors.green,
        ),
      );
      _chargerEcoles();
    } catch (e) {
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
              Navigator.pop(context);
              try {
                await ApiService.refuserEcole(
                  compte['id'],
                  motifController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ \${compte['nom_officiel']} refusée"),
                    backgroundColor: AppColors.red,
                  ),
                );
                _chargerEcoles();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur \$e"),
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
          // Onglet en attente
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _enAttente.length,
                  itemBuilder: (context, index) {
                    final compte = _enAttente[index];
                    return _CarteCompte(
                      compte: compte,
                      onActiver: () => _activer(compte),
                      onRefuser: () => _refuser(compte),
                    );
                  },
                ),

          // Onglet traitées
          _traitees.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun historique traité",
                    style: TextStyle(color: AppColors.textSub),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _traitees.length,
                  itemBuilder: (context, index) {
                    final compte = _traitees[index];
                    return _CarteCompteTraite(
                      compte: compte,
                      onSupprimer: () => _supprimer(compte),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _CarteCompte extends StatelessWidget {
  final dynamic compte;
  final VoidCallback onActiver;
  final VoidCallback onRefuser;

  const _CarteCompte({
    required this.compte,
    required this.onActiver,
    required this.onRefuser,
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
            // École
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
                        "${compte['ville'] ?? ''} • ${compte['type_etablissement'] ?? ''}",
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

            // Admin responsable
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
                Text(
                  compte['email_principal'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
                const Spacer(),
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

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(compte['nom_officiel'] ?? 'Détails'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Responsable: ${compte['nom_responsable'] ?? ''} (${compte['titre_responsable'] ?? ''})",
                                ),
                                Text(
                                  "Email Principal: ${compte['email_principal'] ?? ''}",
                                ),
                                Text(
                                  "Téléphone: ${compte['tel_fixe'] ?? ''} / ${compte['tel_mobile'] ?? ''}",
                                ),
                                Text(
                                  "Adresse: ${compte['adresse'] ?? ''}, ${compte['ville'] ?? ''}, ${compte['pays'] ?? ''}",
                                ),
                                Text(
                                  "Type: ${compte['type_etablissement'] ?? ''}",
                                ),
                                Text("Site Web: ${compte['site_web'] ?? ''}"),
                                const SizedBox(height: 10),
                                Text(
                                  "Description: ${compte['description_complete'] ?? compte['description_courte'] ?? ''}",
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
                    },
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
}

class _CarteCompteTraite extends StatelessWidget {
  final dynamic compte;
  final VoidCallback onSupprimer;
  const _CarteCompteTraite({required this.compte, required this.onSupprimer});

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
                      ? AppColors.green.withOpacity(0.1)
                      : AppColors.red.withOpacity(0.1),
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
                        ? AppColors.green.withOpacity(0.1)
                        : AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estActive ? "Activée" : "Refusée",
                    style: TextStyle(
                      fontSize: 11,
                      color: estActive ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
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
      ),
    );
  }
}
