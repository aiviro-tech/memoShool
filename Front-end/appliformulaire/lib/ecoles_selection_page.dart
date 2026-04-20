import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/dashboard_screen.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class EcolesSelectionPage extends StatefulWidget {
  const EcolesSelectionPage({super.key});

  @override
  State<EcolesSelectionPage> createState() => _EcolesSelectionPageState();
}

class _EcolesSelectionPageState extends State<EcolesSelectionPage> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Restaurer le token depuis la session
    final session = SessionUtilisateur();
    if (session.token.isNotEmpty) {
      ApiService.setToken(session.token);
    }
    _dashboardFuture = ApiService.getDashboardAccueil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mes écoles"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: () async {
              try {
                await ApiService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Connexion()),
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Erreur de chargement",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _dashboardFuture = ApiService.getDashboardAccueil();
                    }),
                    child: const Text("Réessayer"),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final user = data['user'] as Map<String, dynamic>? ?? {};
          final ecolesActives = List.from(data['ecoles_actives'] ?? []);
          final demandesAttente = List.from(data['demandes_en_attente'] ?? []);
          final demandesRejetees = List.from(data['demandes_rejetees'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec accueil
                Text(
                  "Bienvenue ${user['nom_complet'] ?? 'Utilisateur'}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 30),

                // Écoles actives
                if (ecolesActives.isNotEmpty) ...[
                  const Text(
                    "VOS ÉCOLES",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ecolesActives.map(
                    (ecole) => _CarteEcole(
                      nom: ecole['nom'] ?? 'École sans nom',
                      ville: ecole['ville'] ?? '',
                      role: ecole['role'] ?? '',
                      ecoleId: ecole['ecole_id'] is int
                          ? ecole['ecole_id'] as int
                          : int.tryParse(ecole['ecole_id']?.toString() ?? '') ??
                                0,
                      onTap: () {
                        if ((ecole['role'] ?? '').toString().toLowerCase() ==
                            'admin') {
                          Navigator.pushNamed(
                            context,
                            '/admin-dashboard',
                            arguments: ecole['ecole_id']?.toString() ?? '0',
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardPrincipal(
                              nomEcole: ecole['nom']?.toString() ?? 'École',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Vous n'êtes rattaché à aucune école.",
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Demandes en attente
                if (demandesAttente.isNotEmpty) ...[
                  const Text(
                    "VOS DEMANDES EN ATTENTE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...demandesAttente.map(
                    (demande) => _CarteDemande(
                      nom: demande['nom'] ?? '',
                      role: demande['role'] ?? '',
                      statut: '⏳ En attente',
                      couleur: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Demandes rejetées
                if (demandesRejetees.isNotEmpty) ...[
                  const Text(
                    "VOS DEMANDES REJETÉES",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...demandesRejetees.map(
                    (demande) => _CarteDemande(
                      nom: demande['nom'] ?? '',
                      role: demande['role'] ?? '',
                      statut: demande['motif_rejet'] ?? 'Rejeté',
                      couleur: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Actions
                const Text(
                  "ACTIONS",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/rejoindre-ecole');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Rejoindre une nouvelle école"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/creer-ecole');
                    },
                    icon: const Icon(Icons.school_outlined),
                    label: const Text("Créer une école"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CarteEcole extends StatelessWidget {
  final String nom;
  final String ville;
  final String role;
  final int ecoleId;
  final VoidCallback onTap;

  const _CarteEcole({
    required this.nom,
    required this.ville,
    required this.role,
    required this.ecoleId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        "$ville • Rôle: $role",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final String nom;
  final String role;
  final String statut;
  final Color couleur;

  const _CarteDemande({
    required this.nom,
    required this.role,
    required this.statut,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: couleur, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(fontWeight: FontWeight.bold, color: couleur),
                ),
                Text(
                  "Rôle: $role • $statut",
                  style: TextStyle(
                    fontSize: 12,
                    color: couleur.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
