import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/dashboard_principal.dart';
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
    final session = SessionUtilisateur();
    if (session.token.isNotEmpty) {
      ApiService.setToken(session.token);
    }
    _dashboardFuture = ApiService.getDashboardAccueil();
  }

  void _recharger() {
    setState(() {
      _dashboardFuture = ApiService.getDashboardAccueil();
    });
  }

  //  CORRECTION : déconnexion → app.Connexion (main.dart)
  Future<void> _seDeconnecter() async {
    final navigator = Navigator.of(context);
    // On appelle logout API mais on déconnecte quand même si ça échoue
    try {
      await ApiService.logout();
    } catch (_) {}
    finally {
      SessionUtilisateur().vider();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const app.Connexion()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text("Mon espace"),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: _seDeconnecter,
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
                    color: app.AppColors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Erreur de chargement",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _recharger,
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

          // ── Détecter si l'utilisateur est admin dans au moins une école ──
          final bool estAdmin = ecolesActives.any(
            (e) =>
                (e['role']?.toString().toLowerCase() == 'admin') ||
                e['is_owner'] == true,
          );

          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EnTeteUtilisateur(
                    nomComplet: user['nom_complet'] ?? 'Utilisateur',
                    email: user['email'] ?? '',
                  ),
                  const SizedBox(height: 28),

                  // ── VOS ÉCOLES ──────────────────────────────────────────
                  if (ecolesActives.isNotEmpty) ...[
                    const _TitreSection(texte: "VOS ÉCOLES"),
                    const SizedBox(height: 12),
                    ...ecolesActives.map((ecole) {
                      final role = (ecole['role'] ?? '')
                          .toString()
                          .toLowerCase();
                      final isOwner = ecole['is_owner'] == true;
                      final ecoleId = ecole['ecole_id'] is int
                          ? ecole['ecole_id'] as int
                          : int.tryParse(
                                ecole['ecole_id']?.toString() ?? '',
                              ) ??
                              0;
                      final nomEcole = ecole['nom']?.toString() ?? 'École';

                      return _CarteEcole(
                        nom: nomEcole,
                        ville: ecole['ville'] ?? '',
                        role: role,
                        ecoleId: ecoleId,
                        isOwner: isOwner,
                        onTap: () {
                          SessionUtilisateur().setEcole(
                            nomEcole,
                            ecoleId,
                            owner: isOwner,
                          );
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DashboardPrincipal(
                                  nomEcole: nomEcole,
                                  ecoleId: ecoleId,
                                  isOwner: isOwner,
                                ),
                              ),
                            ).then((_) => _recharger());
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 28),
                  ] else ...[
                    // Aucune école
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Vous n'êtes rattaché à aucune école.\nRejoignez ou créez une école pour commencer.",
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── DEMANDES EN ATTENTE ─────────────────────────────────
                  if (demandesAttente.isNotEmpty) ...[
                    const _TitreSection(texte: "VOS DEMANDES EN ATTENTE"),
                    const SizedBox(height: 12),
                    ...demandesAttente.map(
                      (demande) => _CarteDemande(
                        nom: demande['nom'] ?? '',
                        role: demande['role'] ?? '',
                        statut: "⏳ En attente de validation",
                        couleur: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── DEMANDES REJETÉES ───────────────────────────────────
                  if (demandesRejetees.isNotEmpty) ...[
                    const _TitreSection(
                      texte: "VOS DEMANDES REJETÉES",
                      couleur: app.AppColors.red,
                    ),
                    const SizedBox(height: 12),
                    ...demandesRejetees.map(
                      (demande) => _CarteDemande(
                        nom: demande['nom'] ?? '',
                        role: demande['role'] ?? '',
                        statut: demande['motif_rejet'] ?? 'Rejeté',
                        couleur: app.AppColors.red,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── ACTIONS ─────────────────────────────────────────────
                  const _TitreSection(texte: "ACTIONS"),
                  const SizedBox(height: 12),

                  // Rejoindre une école — visible pour TOUS
                  _BoutonAction(
                    icone: Icons.add_circle_outline,
                    label: "Rejoindre une école",
                    description: "Utiliser un code d'invitation",
                    couleur: app.AppColors.primary,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/rejoindre-ecole',
                    ).then((_) => _recharger()),
                  ),

                  // Créer une école — visible uniquement pour les admins
                  if (estAdmin || ecolesActives.isEmpty) ...[
                    const SizedBox(height: 12),
                    _BoutonAction(
                      icone: Icons.school_outlined,
                      label: "Créer une école",
                      description:
                          "Devenir administrateur d'une nouvelle école",
                      couleur: app.AppColors.secondary,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/creer-ecole',
                      ).then((_) => _recharger()),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── EN-TÊTE UTILISATEUR ──────────────────────────────────────────────────────

class _EnTeteUtilisateur extends StatelessWidget {
  final String nomComplet;
  final String email;

  const _EnTeteUtilisateur({required this.nomComplet, required this.email});

  @override
  Widget build(BuildContext context) {
    final initiale = nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'U';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              initiale,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bienvenue 👋",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nomComplet,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
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

// ─── TITRE DE SECTION ─────────────────────────────────────────────────────────

class _TitreSection extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _TitreSection({
    required this.texte,
    this.couleur = app.AppColors.textMain,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: couleur,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── BOUTON ACTION ────────────────────────────────────────────────────────────

class _BoutonAction extends StatelessWidget {
  final IconData icone;
  final String label;
  final String description;
  final Color couleur;
  final VoidCallback onTap;

  const _BoutonAction({
    required this.icone,
    required this.label,
    required this.description,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: couleur,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: app.AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: couleur.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARTE ÉCOLE ──────────────────────────────────────────────────────────────

class _CarteEcole extends StatelessWidget {
  final String nom;
  final String ville;
  final String role;
  final int ecoleId;
  final bool isOwner;
  final VoidCallback onTap;

  const _CarteEcole({
    required this.nom,
    required this.ville,
    required this.role,
    required this.ecoleId,
    required this.isOwner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String roleLabel;
    Color roleColor;
    IconData roleIcon;

    switch (role.toLowerCase()) {
      case 'admin':
        roleLabel = isOwner
            ? 'Administrateur · Propriétaire'
            : 'Administrateur';
        roleColor = app.AppColors.primary;
        roleIcon =
            isOwner ? Icons.admin_panel_settings : Icons.manage_accounts;
        break;
      case 'enseignant':
        roleLabel = 'Enseignant';
        roleColor = app.AppColors.green;
        roleIcon = Icons.school;
        break;
      default:
        roleLabel = 'Étudiant';
        roleColor = app.AppColors.orange;
        roleIcon = Icons.person;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: roleColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(roleIcon, color: roleColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: app.AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ville.isNotEmpty ? '$ville · $roleLabel' : roleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: roleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Entrer",
                style: TextStyle(
                  fontSize: 13,
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARTE DEMANDE ────────────────────────────────────────────────────────────

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
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
                Text(
                  "Rôle: $role · $statut",
                  style: TextStyle(
                    fontSize: 12,
                    color: couleur.withValues(alpha: 0.7),
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