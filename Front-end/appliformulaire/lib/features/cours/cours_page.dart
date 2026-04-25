import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/features/cours/liste_cours_tab.dart';
import 'package:appliformulaire/features/cours/emploi_du_temps_tab.dart';
import 'package:appliformulaire/features/cours/supports_cours_tab.dart';

class CoursPage extends StatefulWidget {
  const CoursPage({super.key});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _session = SessionUtilisateur();

  @override
  void initState() {
    super.initState();
    // 3 onglets: Liste, Emploi du temps, Supports
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _titre {
    if (_session.estAdmin) return 'Gestion des cours';
    if (_session.estEnseignant) return 'Mes cours';
    return 'Mes cours';
  }

  Color get _couleurAppBar {
    if (_session.estAdmin) return AppColors.primary;
    if (_session.estEnseignant) return const Color(0xFF2E7D32);
    return const Color(0xFF303F9F);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titre),
        backgroundColor: _couleurAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt, size: 20), text: 'Liste'),
            Tab(icon: Icon(Icons.calendar_view_week, size: 20), text: 'Emploi du temps'),
            Tab(icon: Icon(Icons.attach_file, size: 20), text: 'Supports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ListeCoursTab(),
          EmploiDuTempsTab(),
          SupportsCoursTab(),
        ],
      ),
    );
  }
}
