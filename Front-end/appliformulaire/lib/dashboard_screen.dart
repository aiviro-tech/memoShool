import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

// ================================================
// CONFIGURATION ET COMPOSANTS POUR DASHBOARD UNIFIÉ
// ================================================
class _RoleConfig {
  final String headerTitle;
  final Color headerColor;
  final List<_Feature> features;

  const _RoleConfig({
    required this.headerTitle,
    required this.headerColor,
    required this.features,
  });
}

class _Feature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  const _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

_RoleConfig _getRoleConfig(String role) {
  switch (role) {
    case 'admin':
      return const _RoleConfig(
        headerTitle: "Espace Administration",
        headerColor: AppColors.primary,
        features: [
          _Feature(
            title: "Gestion des cours",
            description: "Créer, modifier et organiser les cours de l'école",
            icon: Icons.menu_book,
            color: Colors.blue,
            route: "gestion_cours",
          ),
          _Feature(
            title: "Suivi académique",
            description:
                "Consulter les performances et statistiques des étudiants",
            icon: Icons.bar_chart,
            color: Colors.green,
            route: "suivi_academique",
          ),
          _Feature(
            title: "Annonces et notifications",
            description: "Publier des annonces et gérer les communications",
            icon: Icons.notifications,
            color: Colors.orange,
            route: "annonces",
          ),
          _Feature(
            title: "Horaire",
            description: "Gérer les emplois du temps et les plannings",
            icon: Icons.schedule,
            color: Colors.purple,
            route: "horaire",
          ),
          _Feature(
            title: "Gestions des paiements",
            description: "Suivre les frais de scolarité et les paiements",
            icon: Icons.payment,
            color: Colors.teal,
            route: "paiements",
          ),
        ],
      );
    case 'enseignant':
      return const _RoleConfig(
        headerTitle: "Espace Enseignant",
        headerColor: Color(0xFF2E7D32), // Colors.green[700]
        features: [
          _Feature(
            title: "Gestion des cours",
            description: "Gérer vos cours, supports et évaluations",
            icon: Icons.menu_book,
            color: Colors.green,
            route: "gestion_cours",
          ),
          _Feature(
            title: "Suivi académique",
            description: "Consulter les notes et progrès de vos étudiants",
            icon: Icons.bar_chart,
            color: Colors.blue,
            route: "suivi_academique",
          ),
          _Feature(
            title: "Annonces et notifications",
            description: "Publier des annonces pour vos classes",
            icon: Icons.notifications,
            color: Colors.orange,
            route: "annonces",
          ),
          _Feature(
            title: "Horaire",
            description: "Consulter votre emploi du temps",
            icon: Icons.schedule,
            color: Colors.purple,
            route: "horaire",
          ),
        ],
      );
    default: // etudiant
      return const _RoleConfig(
        headerTitle: "Espace Étudiant",
        headerColor: Color(0xFF303F9F), // Colors.indigo[700]
        features: [
          _Feature(
            title: "Gestion des cours",
            description: "Consulter vos cours et supports pédagogiques",
            icon: Icons.menu_book,
            color: Colors.blue,
            route: "gestion_cours",
          ),
          _Feature(
            title: "Suivi académique",
            description: "Suivre vos notes, moyennes et progrès",
            icon: Icons.bar_chart,
            color: Colors.green,
            route: "suivi_academique",
          ),
          _Feature(
            title: "Annonces et notifications",
            description: "Consulter les annonces de vos enseignants",
            icon: Icons.notifications,
            color: Colors.orange,
            route: "annonces",
          ),
          _Feature(
            title: "Horaire",
            description: "Consulter votre emploi du temps",
            icon: Icons.schedule,
            color: Colors.purple,
            route: "horaire",
          ),
          _Feature(
            title: "Gestions des paiements",
            description: "Consulter vos frais de scolarité et paiements",
            icon: Icons.payment,
            color: Colors.teal,
            route: "paiements",
          ),
        ],
      );
  }
}

// ================================================
// CARTE DE FONCTIONNALITÉ
// ================================================
class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, color: feature.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSub,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================
// DASHBOARD PRINCIPAL — S'ADAPTE AU RÔLE
// ================================================
class DashboardPrincipal extends StatefulWidget {
  final String nomEcole;
  const DashboardPrincipal({super.key, required this.nomEcole});

  @override
  State<DashboardPrincipal> createState() => _DashboardPrincipalState();
}

class _DashboardPrincipalState extends State<DashboardPrincipal> {
  int _selectedIndex = 0;
  final String role = SessionUtilisateur().role;

  List<Widget> get _pages {
    return [
      _AccueilPrincipal(nomEcole: widget.nomEcole),
      const _NotificationsPage(),
      const _ProfilPage(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Notifications',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _navItems,
      ),
    );
  }
}

// ================================================
// ACCUEIL PRINCIPAL — UNIFIÉ POUR TOUS LES RÔLES
// ================================================
class _AccueilPrincipal extends StatelessWidget {
  final String nomEcole;
  const _AccueilPrincipal({required this.nomEcole});

  @override
  Widget build(BuildContext context) {
    final prenom = SessionUtilisateur().prenom;
    final role = SessionUtilisateur().role;

    // Configuration selon le rôle
    final config = _getRoleConfig(role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Header(
                prenom: prenom,
                role: config.headerTitle,
                nomEcole: nomEcole,
                couleur: config.headerColor,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Fonctionnalités",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cartes des fonctionnalités
                    ...config.features.map(
                      (feature) => _FeatureCard(
                        feature: feature,
                        onTap: () => _navigateToFeature(context, feature.route),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFeature(BuildContext context, String route) {
    switch (route) {
      case 'gestion_cours':
        // Navigation vers gestion des cours
        break;
      case 'suivi_academique':
        // Navigation vers suivi académique
        break;
      case 'annonces':
        // Navigation vers annonces et notifications
        break;
      case 'horaire':
        // Navigation vers horaire
        break;
      case 'paiements':
        // Navigation vers gestions des paiements
        break;
    }
  }
}

// ================================================
// HEADER PERSONNALISÉ
// ================================================
class _Header extends StatelessWidget {
  final String prenom;
  final String role;
  final String nomEcole;
  final Color couleur;

  const _Header({
    required this.prenom,
    required this.role,
    required this.nomEcole,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  prenom.isNotEmpty ? prenom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bienvenue, $prenom",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nomEcole,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================
// PAGES PLACEHOLDER POUR LES AUTRES FONCTIONNALITÉS
// ================================================
class _MembresPage extends StatelessWidget {
  const _MembresPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des Membres")),
      body: const Center(child: Text("Page Membres - À implémenter")),
    );
  }
}

class _ProfilPage extends StatelessWidget {
  const _ProfilPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil")),
      body: const Center(child: Text("Page Profil - À implémenter")),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: const Center(
        child: Text(
          "Aucune notification pour le moment",
          style: TextStyle(fontSize: 16, color: AppColors.textSub),
        ),
      ),
    );
  }
}

class _CoursEnseignantPage extends StatelessWidget {
  const _CoursEnseignantPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Cours")),
      body: const Center(child: Text("Page Cours Enseignant - À implémenter")),
    );
  }
}

class _CoursEtudiantPage extends StatelessWidget {
  const _CoursEtudiantPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Cours")),
      body: const Center(child: Text("Page Cours Étudiant - À implémenter")),
    );
  }
}

class _EmploiDuTempsPage extends StatelessWidget {
  const _EmploiDuTempsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emploi du Temps")),
      body: const Center(child: Text("Page Emploi du Temps - À implémenter")),
    );
  }
}
