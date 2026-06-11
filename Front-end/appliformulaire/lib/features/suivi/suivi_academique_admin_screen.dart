import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/features/notes/autoriser_notes_screen.dart';
import 'package:appliformulaire/features/notes/consultation_notes_admin_screen.dart';
import 'package:appliformulaire/features/releves/releve_admin_screen.dart';
import 'package:appliformulaire/features/absences/absences_admin_screen.dart';

class SuiviAcademiqueAdminScreen extends StatelessWidget {
  const SuiviAcademiqueAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Suivi Académique',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                    SizedBox(height: 10),
                    Text(
                      'Gestion académique',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gérez les notes, relevés et absences de vos étudiants',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Actions disponibles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Column(
                  children: [
                    _buildCarte(
                      context,
                      icon: Icons.security_rounded,
                      couleur: Colors.purple,
                      titre: 'Autoriser un enseignant',
                      description: 'Accorder ou révoquer le droit de saisie de notes.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AutoriserNotesScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCarte(
                      context,
                      icon: Icons.visibility_rounded,
                      couleur: Colors.teal,
                      titre: 'Consulter les notes',
                      description: 'Voir les notes saisies par les enseignants.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConsultationNotesAdminScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCarte(
                      context,
                      icon: Icons.description_rounded,
                      couleur: Colors.indigo,
                      titre: 'Générer les relevés',
                      description: 'Générer et télécharger les relevés de notes en PDF.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReleveAdminScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCarte(
                      context,
                      icon: Icons.event_busy_rounded,
                      couleur: Colors.red,
                      titre: 'Gestion des absences',
                      description: 'Suivre et justifier les absences des étudiants.',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AbsencesAdminScreen()),
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

  Widget _buildCarte(
    BuildContext context, {
    required IconData icon,
    required Color couleur,
    required String titre,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: couleur.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: couleur, size: 28),
              ),
              const SizedBox(width: 16),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Flèche
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: couleur, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}