import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/features/cours/cours_page.dart';
import 'package:appliformulaire/notes_screen.dart';
import 'package:appliformulaire/paiement_screen.dart';
import 'package:appliformulaire/inscription_screen.dart';
import 'package:appliformulaire/features/suivi/suivi_academique_admin_screen.dart';
import 'package:appliformulaire/features/suivi/suivi_academique_enseignant_screen.dart';
import 'package:appliformulaire/features/notes/creer_devoir_screen.dart';
import 'package:appliformulaire/features/absences/saisie_presences_screen.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/annonce/annonces_screen.dart';
import 'package:appliformulaire/features/paiements/admin_paiements_screen.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_service.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_model.dart';
import 'package:appliformulaire/features/profil/profil_screen.dart';
import 'package:appliformulaire/features/config/ecole_config_screen.dart'; // ← AJOUTÉ

// ─── Config par rôle ──────────────────────────────────────────────────────────

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

_RoleConfig _getRoleConfig(String role, bool isOwner) {
  switch (role) {
    case 'admin':
      return _RoleConfig(
        headerTitle: 'Espace Administration',
        headerColor: app.AppColors.primary,
        features: const [
          _Feature(
            title: 'Gestion des cours',
            description: 'Créer, modifier et organiser les cours',
            icon: Icons.menu_book,
            color: Colors.blue,
            route: 'gestion_cours',
          ),
          _Feature(
            title: 'Suivi académique',
            description: 'Notes • Absences • Exclusions',
            icon: Icons.bar_chart,
            color: Colors.green,
            route: 'suivi_academique',
          ),
          _Feature(
            title: 'Supports à valider',
            description: 'Valider ou rejeter les supports déposés',
            icon: Icons.attach_file,
            color: Colors.orange,
            route: 'valider_supports',
          ),
          _Feature(
            title: 'Annonces et notifications',
            description: 'Publier des annonces et gérer les communications',
            icon: Icons.notifications,
            color: Colors.orange,
            route: 'annonces',
          ),
          _Feature(
            title: 'Gestion des paiements',
            description: 'Suivre et filtrer les frais de scolarité par classe',
            icon: Icons.payment,
            color: Colors.teal,
            route: 'paiements',
          ),
          _Feature(
            title: 'Inscriptions',
            description: 'Inscrire les étudiants dans les classes',
            icon: Icons.how_to_reg,
            color: Color(0xFF5C6BC0),
            route: 'inscriptions',
          ),
          // ── AJOUTÉ ────────────────────────────────────────────────────────
          _Feature(
            title: 'Configuration pédagogique',
            description: 'Paramétrer le calcul des moyennes et la scolarité',
            icon: Icons.tune,
            color: Color(0xFF6D4C41),
            route: 'config',
          ),
        ],
      );

    case 'enseignant':
      return const _RoleConfig(
        headerTitle: 'Espace Enseignant',
        headerColor: Color(0xFF2E7D32),
        features: [
          _Feature(
            title: 'Gestion des cours',
            description: 'Gérer vos cours, supports et évaluations',
            icon: Icons.menu_book,
            color: Colors.green,
            route: 'gestion_cours',
          ),
          _Feature(
            title: 'Suivi académique',
            description: 'Notes • Présences • Devoirs',
            icon: Icons.bar_chart,
            color: Colors.blue,
            route: 'suivi_academique',
          ),
          _Feature(
            title: 'Annonces et notifications',
            description: 'Consulter les annonces',
            icon: Icons.notifications,
            color: Colors.orange,
            route: 'annonces',
          ),
        ],
      );

    default: // etudiant
      return const _RoleConfig(
        headerTitle: 'Espace Étudiant',
        headerColor: Color(0xFF303F9F),
        features: [
          _Feature(
            title: 'Gestion des cours',
            description: 'Consulter vos cours et supports pédagogiques',
            icon: Icons.menu_book,
            color: Colors.blue,
            route: 'gestion_cours',
          ),
          _Feature(
            title: 'Suivi académique',
            description: 'Notes • Moyennes • Relevés',
            icon: Icons.bar_chart,
            color: Colors.green,
            route: 'suivi_academique',
          ),
          _Feature(
            title: 'Annonces et notifications',
            description: 'Consulter les annonces',
            icon: Icons.notifications,
            color: Colors.orange,
            route: 'annonces',
          ),
          _Feature(
            title: 'Mes paiements',
            description: 'Payer vos frais et consulter votre solde',
            icon: Icons.payment,
            color: Colors.teal,
            route: 'paiements',
          ),
          _Feature(
            title: 'Mon inscription',
            description: 'Voir le statut de votre inscription',
            icon: Icons.how_to_reg,
            color: Color(0xFF5C6BC0),
            route: 'inscriptions',
          ),
        ],
      );
  }
}

// ─── Dashboard principal ──────────────────────────────────────────────────────

class DashboardPrincipal extends StatefulWidget {
  final String nomEcole;
  final int ecoleId;
  final bool isOwner;

  const DashboardPrincipal({
    super.key,
    required this.nomEcole,
    required this.ecoleId,
    required this.isOwner,
  });

  @override
  State<DashboardPrincipal> createState() => _DashboardPrincipalState();
}

class _DashboardPrincipalState extends State<DashboardPrincipal> {
  bool _showCodesPage = false;

  Map<String, dynamic>? _codes;
  Map<String, int> _codesIds = {};
  bool _loadingCodes = true;
  String? _errorCodes;
  final Set<String> _regenerationEnCours = {};

  List<dynamic> _demandes = [];
  bool _loadingDemandes = false;

  // Bottom nav : 0=Accueil  1=Notifications  2=Profil
  int _currentIndex = 0;

  int _nbNotifNonLues = 0;
  Timer? _timerNotif;
  final _notifService = NotificationService();
  final _notifPageKey = GlobalKey<_NotificationsPageState>();

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      _showCodesPage = true;
      _chargerCodes();
      _chargerDemandes();
    }
    _chargerCompteurNotifs();
    _timerNotif = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _chargerCompteurNotifs(),
    );
  }

  @override
  void dispose() {
    _timerNotif?.cancel();
    super.dispose();
  }

  Future<void> _chargerCompteurNotifs() async {
    try {
      final count = await _notifService.getCompteurNonLues(widget.ecoleId);
      if (mounted) setState(() => _nbNotifNonLues = count);
    } catch (_) {}
  }

  Future<void> _chargerCodes() async {
    setState(() {
      _loadingCodes = true;
      _errorCodes   = null;
    });
    try {
      final List<dynamic> codes = await ApiService.mesCodes();
      final Map<String, dynamic> codesMap = {};
      final Map<String, int>     idsMap   = {};
      for (var code in codes) {
        final role     = code['role']?.toString() ?? '';
        final isActive = code['is_active'] != false;
        if (isActive && !codesMap.containsKey(role)) {
          codesMap[role] = code['code'];
          final id = code['id'];
          if (id != null) {
            idsMap[role] = id is int ? id : int.tryParse(id.toString()) ?? 0;
          }
        }
      }
      if (mounted) {
        setState(() {
          _codes        = codesMap;
          _codesIds     = idsMap;
          _loadingCodes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorCodes   = e.toString().replaceAll('Exception: ', '');
          _loadingCodes = false;
        });
      }
    }
  }

  Future<void> _chargerDemandes() async {
    setState(() => _loadingDemandes = true);
    try {
      final response = await ApiService.demandesEnAttente();
      if (mounted) {
        setState(() {
          _demandes        = response;
          _loadingDemandes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDemandes = false);
    }
  }

  void _copierCode(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Code copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
        backgroundColor: app.AppColors.green,
      ),
    );
  }

  Future<void> _regenererCode(String role) async {
    final codeId = _codesIds[role];
    if (codeId == null || codeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de trouver ce code'),
          backgroundColor: app.AppColors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Régénérer le code ?'),
        content: const Text(
          "L'ancien code sera immédiatement désactivé.\n"
          "Les personnes qui ne l'ont pas encore utilisé devront utiliser le nouveau code.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: app.AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _regenerationEnCours.add(role));
    try {
      await ApiService.regenererCode(codeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Code régénéré avec succès'),
            backgroundColor: app.AppColors.green,
          ),
        );
        await _chargerCodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerationEnCours.remove(role));
    }
  }

  Future<void> _accepterDemande(int id) async {
    try {
      await ApiService.accepterDemande(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Demande acceptée avec succès'),
            backgroundColor: app.AppColors.green,
          ),
        );
        _chargerDemandes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejeterDemande(int id) async {
    final motifCtrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Motif du rejet"),
        content: TextField(
          controller: motifCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Expliquez la raison du refus...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motifCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: app.AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Rejeter"),
          ),
        ],
      ),
    );
    if (motif == null || motif.isEmpty) return;
    try {
      await ApiService.rejeterDemande(id, motif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande rejetée'),
            backgroundColor: app.AppColors.orange,
          ),
        );
        _chargerDemandes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOwner && _showCodesPage) {
      return _buildCodesPage();
    }

    final pages = [
      _AccueilPrincipal(
        isOwner: widget.isOwner,
        ecoleId: widget.ecoleId,         // ← AJOUTÉ (nécessaire pour config)
        onRetourCodesPage: widget.isOwner
            ? () {
                setState(() => _showCodesPage = true);
                _chargerDemandes();
              }
            : null,
      ),
      _NotificationsPage(
        key: _notifPageKey,
        ecoleId: widget.ecoleId,
        notifService: _notifService,
        onCompteurChange: (count) {
          if (mounted) setState(() => _nbNotifNonLues = count);
        },
      ),
      const ProfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(
                index: 0,
                icon: Icons.grid_view_rounded,
                iconActif: Icons.grid_view_rounded,
                label: 'Accueil',
              ),
              _navItemAvecBadge(
                index: 1,
                icon: Icons.notifications_outlined,
                iconActif: Icons.notifications,
                label: 'Notifications',
                badge: _nbNotifNonLues,
              ),
              _navItem(
                index: 2,
                icon: Icons.person_outline,
                iconActif: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    IconData? iconActif,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? app.AppColors.primary : const Color(0xFF9E9E9E);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? (iconActif ?? icon) : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemAvecBadge({
    required int index,
    required IconData icon,
    IconData? iconActif,
    required String label,
    required int badge,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? app.AppColors.primary : const Color(0xFF9E9E9E);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          _notifPageKey.currentState?.charger();
          _chargerCompteurNotifs();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? (iconActif ?? icon) : icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page codes + demandes ────────────────────────────────────────────────

  Widget _buildCodesPage() {
    if (_loadingCodes) {
      return const Scaffold(
        backgroundColor: app.AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorCodes != null) {
      return Scaffold(
        backgroundColor: app.AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
              const SizedBox(height: 12),
              Text(_errorCodes!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _chargerCodes,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: Text(widget.nomEcole),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: "Tableau de bord",
            onPressed: () => setState(() => _showCodesPage = false),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _chargerCodes();
          await _chargerDemandes();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header école
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school, size: 40, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      widget.nomEcole,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Espace Administrateur",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Codes d'invitation
              const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: app.AppColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "CODES D'INVITATION",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: app.AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Partagez ces codes pour que vos membres rejoignent l'école",
                style: TextStyle(color: app.AppColors.textSub, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _buildCodeCard(
                titre: "🎓  ÉTUDIANTS",
                code: _codes?['etudiant'] ?? "ETU-XXXXXXXX",
                couleur: Colors.blue,
                role: 'etudiant',
                onCopier: () => _copierCode(_codes?['etudiant'] ?? ''),
                onRegenerer: () => _regenererCode('etudiant'),
                enCoursRegeneration: _regenerationEnCours.contains('etudiant'),
              ),
              const SizedBox(height: 10),
              _buildCodeCard(
                titre: "👨‍🏫  ENSEIGNANTS",
                code: _codes?['enseignant'] ?? "ENS-XXXXXXXX",
                couleur: Colors.green,
                role: 'enseignant',
                onCopier: () => _copierCode(_codes?['enseignant'] ?? ''),
                onRegenerer: () => _regenererCode('enseignant'),
                enCoursRegeneration: _regenerationEnCours.contains('enseignant'),
              ),
              const SizedBox(height: 10),
              _buildCodeCard(
                titre: "👔  ADMINISTRATION",
                code: _codes?['admin'] ?? "ADM-XXXXXXXX",
                couleur: Colors.orange,
                role: 'admin',
                onCopier: () => _copierCode(_codes?['admin'] ?? ''),
                onRegenerer: () => _regenererCode('admin'),
                enCoursRegeneration: _regenerationEnCours.contains('admin'),
              ),
              const SizedBox(height: 28),

              // Demandes en attente
              Row(
                children: [
                  const Icon(Icons.people_outline, color: app.AppColors.textMain, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    "DEMANDES EN ATTENTE",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: app.AppColors.textMain,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_demandes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_demandes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    color: app.AppColors.primary,
                    onPressed: _chargerDemandes,
                    tooltip: "Actualiser",
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_loadingDemandes)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_demandes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: app.AppColors.green, size: 32),
                      SizedBox(height: 8),
                      Text(
                        "Aucune demande en attente",
                        style: TextStyle(color: app.AppColors.green, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Les demandes apparaîtront ici quand\ndes membres utiliseront vos codes",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: app.AppColors.textSub, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ..._demandes.map((d) => _buildCarteDemande(d)),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showCodesPage = false),
                  icon: const Icon(Icons.dashboard),
                  label: const Text(
                    "Accéder au tableau de bord",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard({
    required String titre,
    required String code,
    required Color couleur,
    required String role,
    required VoidCallback onCopier,
    required VoidCallback onRegenerer,
    required bool enCoursRegeneration,
  }) {
    final bool codeValide = !code.contains('XXXXXXXX');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: couleur,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: app.AppColors.textMain,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (codeValide)
                GestureDetector(
                  onTap: onCopier,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: couleur),
                        const SizedBox(width: 4),
                        Text(
                          "Copier",
                          style: TextStyle(
                            fontSize: 12,
                            color: couleur,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: enCoursRegeneration ? null : onRegenerer,
              icon: enCoursRegeneration
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: app.AppColors.orange,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                enCoursRegeneration ? 'Régénération...' : 'Régénérer le code',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: app.AppColors.orange,
                side: BorderSide(color: app.AppColors.orange.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteDemande(dynamic d) {
    final user      = d['user'] as Map<String, dynamic>? ?? {};
    final nomComplet =
        user['full_name'] ??
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email = user['email'] ?? '';
    final role  = d['role']?.toString() ?? '';
    final date  = d['created_at']?.toString().split('T')[0] ?? '';
    final id    = d['id'] as int;

    Color   couleur;
    IconData icone;
    String  libelleRole;
    switch (role) {
      case 'etudiant':
        couleur     = Colors.blue;
        icone       = Icons.school;
        libelleRole = 'Étudiant';
        break;
      case 'enseignant':
        couleur     = Colors.green;
        icone       = Icons.person;
        libelleRole = 'Enseignant';
        break;
      default:
        couleur     = Colors.orange;
        icone       = Icons.admin_panel_settings;
        libelleRole = 'Administration';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: couleur, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomComplet.isNotEmpty ? nomComplet : 'Utilisateur',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: app.AppColors.textMain,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 12, color: app.AppColors.textSub),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  libelleRole,
                  style: TextStyle(
                    fontSize: 11,
                    color: couleur,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: app.AppColors.textSub),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 11, color: app.AppColors.textSub)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejeterDemande(id),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text("Refuser"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: app.AppColors.red,
                    side: const BorderSide(color: app.AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _accepterDemande(id),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text("Accepter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsPage extends StatefulWidget {
  final int ecoleId;
  final NotificationService notifService;
  final ValueChanged<int> onCompteurChange;

  const _NotificationsPage({
    super.key,
    required this.ecoleId,
    required this.notifService,
    required this.onCompteurChange,
  });

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _chargement = true;
  String? _erreur;
  bool? _filtreLu;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    if (!mounted) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      final notifs = await widget.notifService.getNotifications(
        widget.ecoleId,
        lu: _filtreLu,
      );
      if (!mounted) return;
      setState(() { _notifications = notifs; _chargement = false; });
      final nonLues = notifs.where((n) => !n.lu).length;
      widget.onCompteurChange(nonLues);
    } catch (e) {
      if (!mounted) return;
      setState(() { _erreur = e.toString().replaceAll('Exception: ', ''); _chargement = false; });
    }
  }

  Future<void> _marquerLue(NotificationModel notif) async {
    if (notif.lu) return;
    try {
      await widget.notifService.marquerLue(widget.ecoleId, notif.id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = NotificationModel(
            id: notif.id, ecoleId: notif.ecoleId, titre: notif.titre,
            contenu: notif.contenu, type: notif.type, data: notif.data,
            lu: true, luAt: notif.luAt, createdAt: notif.createdAt,
          );
        }
      });
      widget.onCompteurChange(_notifications.where((n) => !n.lu).length);
    } catch (_) {}
  }

  Future<void> _marquerToutesLues() async {
    try {
      await widget.notifService.marquerToutesLues(widget.ecoleId);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) => NotificationModel(
          id: n.id, ecoleId: n.ecoleId, titre: n.titre, contenu: n.contenu,
          type: n.type, data: n.data, lu: true, luAt: n.luAt, createdAt: n.createdAt,
        )).toList();
      });
      widget.onCompteurChange(0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été lues'),
            backgroundColor: app.AppColors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _supprimer(NotificationModel notif) async {
    try {
      await widget.notifService.supprimer(widget.ecoleId, notif.id);
      if (!mounted) return;
      setState(() => _notifications.removeWhere((n) => n.id == notif.id));
      widget.onCompteurChange(_notifications.where((n) => !n.lu).length);
    } catch (e) {
      if (mounted) {
        charger();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  int get _nbNonLues => _notifications.where((n) => !n.lu).length;

  Color _couleurType(String type) {
    switch (type) {
      case 'annonce':         return Colors.purple;
      case 'note':            return Colors.blue;
      case 'support':         return Colors.teal;
      case 'emploi_du_temps': return Colors.indigo;
      case 'paiement':        return Colors.green;
      case 'absence':         return Colors.red;
      default:                return Colors.grey;
    }
  }

  IconData _iconeType(String type) {
    switch (type) {
      case 'annonce':         return Icons.campaign_rounded;
      case 'note':            return Icons.grade_rounded;
      case 'support':         return Icons.attach_file_rounded;
      case 'emploi_du_temps': return Icons.schedule_rounded;
      case 'paiement':        return Icons.payment_rounded;
      case 'absence':         return Icons.event_busy_rounded;
      default:                return Icons.notifications_rounded;
    }
  }

  String _libelleType(String type) {
    switch (type) {
      case 'annonce':         return 'Annonce';
      case 'note':            return 'Note';
      case 'support':         return 'Support';
      case 'emploi_du_temps': return 'Emploi du temps';
      case 'paiement':        return 'Paiement';
      case 'absence':         return 'Absence';
      default:                return 'Général';
    }
  }

  String _tempsRelatif(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final dt   = DateTime.parse(createdAt.replaceAll(' ', 'T'));
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60)  return 'À l\'instant';
      if (diff.inMinutes < 60)  return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours   < 24)  return 'Il y a ${diff.inHours} h';
      if (diff.inDays    == 1)  return 'Hier';
      if (diff.inDays    < 7)   return 'Il y a ${diff.inDays} jours';
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    } catch (_) {
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_nbNonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: Text('$_nbNonLues', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (_nbNonLues > 0)
            TextButton(
              onPressed: _marquerToutesLues,
              child: const Text('Tout lire', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: charger, tooltip: 'Actualiser'),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filtreChip('Toutes', null),
                const SizedBox(width: 8),
                _filtreChip('Non lues', false),
                const SizedBox(width: 8),
                _filtreChip('Lues', true),
              ],
            ),
          ),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _erreur != null
                    ? _buildErreur()
                    : _notifications.isEmpty
                        ? _buildVide()
                        : RefreshIndicator(
                            onRefresh: charger,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              itemCount: _notifications.length,
                              itemBuilder: (_, i) => _buildCarteNotification(_notifications[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteNotification(NotificationModel notif) {
    final couleur = _couleurType(notif.type);
    final icone   = _iconeType(notif.type);
    final temps   = _tempsRelatif(notif.createdAt);

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => _supprimer(notif),
      child: GestureDetector(
        onTap: () => _marquerLue(notif),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: notif.lu ? Colors.white : app.AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.lu ? Colors.grey.shade200 : app.AppColors.primary.withValues(alpha: 0.25),
              width: notif.lu ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: notif.lu ? 0.03 : 0.06),
                blurRadius: notif.lu ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: couleur.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icone, color: couleur, size: 22),
                    ),
                    if (!notif.lu)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: app.AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.titre,
                        style: TextStyle(
                          fontWeight: notif.lu ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.contenu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: notif.lu ? Colors.grey.shade600 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: couleur.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icone, size: 10, color: couleur),
                                const SizedBox(width: 4),
                                Text(
                                  _libelleType(notif.type),
                                  style: TextStyle(fontSize: 10, color: couleur, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            temps,
                            style: TextStyle(
                              fontSize: 11,
                              color: notif.lu ? Colors.grey.shade400 : app.AppColors.primary.withValues(alpha: 0.7),
                              fontWeight: notif.lu ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtreChip(String label, bool? value) {
    final selected = _filtreLu == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) { setState(() => _filtreLu = value); charger(); },
      selectedColor: app.AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: app.AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? app.AppColors.primary : Colors.grey.shade600,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: selected ? app.AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 44, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            _filtreLu == false ? 'Aucune notification non lue'
                : _filtreLu == true ? 'Aucune notification lue'
                : 'Aucune notification',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Vous êtes à jour !', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: app.AppColors.red),
            const SizedBox(height: 16),
            Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: charger,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: app.AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Accueil principal ────────────────────────────────────────────────────────

class _AccueilPrincipal extends StatelessWidget {
  final bool isOwner;
  final int ecoleId;                      // ← AJOUTÉ
  final VoidCallback? onRetourCodesPage;

  const _AccueilPrincipal({
    required this.isOwner,
    required this.ecoleId,               // ← AJOUTÉ
    this.onRetourCodesPage,
  });

  @override
  Widget build(BuildContext context) {
    final session = SessionUtilisateur();
    final config  = _getRoleConfig(session.role, isOwner);

    return Scaffold(
      backgroundColor: app.AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Header(
                prenom: session.prenom,
                nomEcole: session.nomEcole,
                roleTitle: config.headerTitle,
                couleur: config.headerColor,
                isOwner: isOwner,
                onRetourAccueil: onRetourCodesPage,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fonctionnalités',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: app.AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...config.features.map(
                      (f) => _FeatureCard(
                        feature: f,
                        onTap: () => _naviguer(context, f.route, session.role, ecoleId),
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

  void _naviguer(BuildContext context, String route, String role, int ecoleId) {
    switch (route) {
      case 'gestion_cours':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursPage()));
        break;

      case 'suivi_academique':
        if (role == 'etudiant') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
        } else if (role == 'enseignant') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SuiviAcademiqueEnseignantScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SuiviAcademiqueAdminScreen()));
        }
        break;

      case 'creer_devoir':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreerDevoirScreen()));
        break;

      case 'saisie_presences':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SaisiePresencesScreen()));
        break;

      case 'valider_supports':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _SupportsAValiderPage()));
        break;

      case 'annonces':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnoncesScreen()));
        break;

      case 'paiements':
        if (role == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaiementsScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaiementsScreen()));
        }
        break;

      case 'inscriptions':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InscriptionScreen()));
        break;

      // ── AJOUTÉ ────────────────────────────────────────────────────────────
      case 'config':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EcoleConfigScreen(ecoleId: ecoleId),
          ),
        );
        break;
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String prenom;
  final String nomEcole;
  final String roleTitle;
  final Color couleur;
  final bool isOwner;
  final VoidCallback? onRetourAccueil;

  const _Header({
    required this.prenom,
    required this.nomEcole,
    required this.roleTitle,
    required this.couleur,
    required this.isOwner,
    this.onRetourAccueil,
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: "Retour",
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              prenom.isNotEmpty ? prenom[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomEcole,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(roleTitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (isOwner && onRetourAccueil != null)
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              tooltip: "Codes & demandes",
              onPressed: onRetourAccueil,
            ),
        ],
      ),
    );
  }
}

// ─── Feature Card ─────────────────────────────────────────────────────────────

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
                  color: feature.color.withValues(alpha: 0.1),
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
                        color: app.AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: const TextStyle(fontSize: 13, color: app.AppColors.textSub),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: app.AppColors.textSub),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supports à valider ───────────────────────────────────────────────────────

class _SupportsAValiderPage extends StatefulWidget {
  const _SupportsAValiderPage();
  @override
  State<_SupportsAValiderPage> createState() => _SupportsAValiderPageState();
}

class _SupportsAValiderPageState extends State<_SupportsAValiderPage> {
  List<dynamic> _supports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _chargerSupports(); }

  Future<void> _chargerSupports() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ecoleId = SessionUtilisateur().ecoleId;
      final result  = await ApiService.getSupports(ecoleId);
      final supports = result['data'] as List? ?? [];
      setState(() {
        _supports = supports.where((s) => s['statut'] == 'en_attente').toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _validerSupport(int supportId) async {
    try {
      await ApiService.validerSupport(SessionUtilisateur().ecoleId, supportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support validé'), backgroundColor: app.AppColors.green),
        );
        _chargerSupports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  Future<void> _rejeterSupport(int supportId) async {
    final motifCtrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: motifCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Expliquez le motif...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              motifCtrl.text.trim().isNotEmpty ? motifCtrl.text.trim() : 'Rejeté',
            ),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (motif == null) return;
    try {
      await ApiService.rejeterSupport(SessionUtilisateur().ecoleId, supportId, motif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support rejeté'), backgroundColor: app.AppColors.orange),
        );
        _chargerSupports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: app.AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text('Supports à valider'),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerSupports)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _chargerSupports, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _supports.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: app.AppColors.green),
                          SizedBox(height: 16),
                          Text('Aucun support en attente',
                              style: TextStyle(fontSize: 16, color: app.AppColors.textSub)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _supports.length,
                      itemBuilder: (_, i) {
                        final s    = _supports[i] as Map<String, dynamic>;
                        final cours = s['cours'] as Map<String, dynamic>? ?? {};
                        final ecue  = cours['ecue'] as Map<String, dynamic>? ?? {};
                        final ens   = s['enseignant'] as Map<String, dynamic>? ?? {};
                        final nomEns =
                            ens['full_name'] ??
                            '${ens['first_name'] ?? ''} ${ens['last_name'] ?? ''}'.trim();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: app.AppColors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: app.AppColors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.attach_file, color: app.AppColors.orange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['titre'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(ecue['nom'] ?? 'Cours',
                                            style: const TextStyle(fontSize: 13, color: app.AppColors.textSub)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Enseignant : $nomEns',
                                  style: const TextStyle(fontSize: 12, color: app.AppColors.textSub)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _validerSupport(s['id'] as int),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Valider'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: app.AppColors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _rejeterSupport(s['id'] as int),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Rejeter'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: app.AppColors.red,
                                        side: const BorderSide(color: app.AppColors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}