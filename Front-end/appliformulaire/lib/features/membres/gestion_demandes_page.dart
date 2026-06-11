import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/services/api_service.dart';

class DemandeAdhesion {
  final int id;
  final String nomComplet;
  final String email;
  final String role;
  final String dateCreation;
  final Map<String, dynamic>? infosSpecifiques;
  final String status;

  DemandeAdhesion({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.role,
    required this.dateCreation,
    this.infosSpecifiques,
    required this.status,
  });

  factory DemandeAdhesion.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};

    return DemandeAdhesion(
      id: json['id'] as int,
      nomComplet:
          user['full_name'] ??
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
      email: user['email'] ?? '',
      role: json['role'] ?? '',
      dateCreation: json['created_at']?.toString().split('T')[0] ?? '',
      infosSpecifiques: {
        if (json['niveau'] != null) 'niveau': json['niveau'],
        if (json['matricule'] != null) 'matricule': json['matricule'],
        if (json['diplome'] != null) 'diplome': json['diplome'],
        if (json['experience_annees'] != null)
          'experience': json['experience_annees'].toString(),
        if (json['poste'] != null) 'poste': json['poste'],
        if (json['service'] != null) 'service': json['service'],
        if (json['type_contrat'] != null) 'contrat': json['type_contrat'],
        if (json['tuteur_nom'] != null) 'tuteur': json['tuteur_nom'],
      },
      status: json['statut'] ?? '',
    );
  }
}

class GestionDemandesPage extends StatefulWidget {
  const GestionDemandesPage({super.key});

  @override
  State<GestionDemandesPage> createState() => _GestionDemandesPageState();
}

class _GestionDemandesPageState extends State<GestionDemandesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DemandeAdhesion> _demandesEnAttente = [];
  List<DemandeAdhesion> _demandesTraitees = [];

  bool _loading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDemandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDemandes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.dio.get('/api/demandes-en-attente');
      final List<dynamic> demandes = response.data ?? [];

      final enAttente = <DemandeAdhesion>[];
      final traitees = <DemandeAdhesion>[];

      for (var d in demandes) {
        final demande = DemandeAdhesion.fromJson(d as Map<String, dynamic>);
        if (demande.status == 'en_attente') {
          enAttente.add(demande);
        } else {
          traitees.add(demande);
        }
      }

      if (mounted) {
        setState(() {
          _demandesEnAttente = enAttente;
          _demandesTraitees = traitees;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _accepterDemande(DemandeAdhesion demande) async {
    setState(() => _isProcessing = true);
    try {
      await ApiService.accepterDemande(demande.id);
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
            content: Text(
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejeterDemande(DemandeAdhesion demande) async {
    final motifController = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: motifController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Expliquez la raison du refus...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, motifController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (motif == null || motif.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await ApiService.rejeterDemande(demande.id, motif);
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
            content: Text(
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _voirDetails(DemandeAdhesion demande) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Détails — ${demande.nomComplet}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Email', demande.email),
              _detailRow('Rôle', _libelleRole(demande.role)),
              _detailRow('Date', demande.dateCreation),
              const Divider(height: 20),
              const Text(
                'Informations complémentaires',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (demande.infosSpecifiques != null &&
                  demande.infosSpecifiques!.isNotEmpty) ...[
                for (var entry in demande.infosSpecifiques!.entries)
                  _detailRow(_libelleChamp(entry.key), entry.value.toString()),
              ] else
                const Text(
                  'Aucune information supplémentaire',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _libelleChamp(String key) {
    switch (key) {
      case 'niveau':
        return 'Niveau';
      case 'matricule':
        return 'Matricule';
      case 'diplome':
        return 'Diplôme';
      case 'experience':
        return 'Expérience';
      case 'poste':
        return 'Poste';
      case 'service':
        return 'Service';
      case 'contrat':
        return 'Contrat';
      case 'tuteur':
        return 'Tuteur';
      default:
        return key;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _libelleRole(String role) {
    switch (role) {
      case 'etudiant':
        return 'Étudiant';
      case 'enseignant':
        return 'Enseignant';
      case 'admin':
      case 'admin_school':
        return 'Administration';
      default:
        return role;
    }
  }

  Color _couleurRole(String role) {
    switch (role) {
      case 'etudiant':
        return Colors.blue;
      case 'enseignant':
        return Colors.green;
      case 'admin':
      case 'admin_school':
        return Colors.orange;
      default:
        return app.AppColors.primary;
    }
  }

  IconData _iconeRole(String role) {
    switch (role) {
      case 'etudiant':
        return Icons.school;
      case 'enseignant':
        return Icons.person;
      default:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text("Demandes d'adhésion"),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDemandes,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.hourglass_empty, size: 18),
              text: "En attente (${_demandesEnAttente.length})",
            ),
            Tab(
              icon: const Icon(Icons.history, size: 18),
              text: "Traitées (${_demandesTraitees.length})",
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListeDemandes(_demandesEnAttente, isHistorique: false),
                _buildListeDemandes(_demandesTraitees, isHistorique: true),
              ],
            ),
    );
  }

  Widget _buildListeDemandes(
    List<DemandeAdhesion> demandes, {
    required bool isHistorique,
  }) {
    if (demandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistorique ? Icons.history : Icons.hourglass_empty,
              size: 64,
              color: app.AppColors.textSub.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isHistorique
                  ? "Aucune demande traitée"
                  : "Aucune demande en attente",
              style: const TextStyle(color: app.AppColors.textSub, fontSize: 16),
            ),
            if (!isHistorique) ...[
              const SizedBox(height: 8),
              const Text(
                "Les demandes apparaîtront ici\nquand des membres utiliseront vos codes",
                textAlign: TextAlign.center,
                style: TextStyle(color: app.AppColors.textSub, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerDemandes,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: demandes.length,
        itemBuilder: (context, index) {
          final demande = demandes[index];
          final couleur = _couleurRole(demande.role);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ligne principale ──
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          _iconeRole(demande.role),
                          color: couleur,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              demande.nomComplet.isNotEmpty
                                  ? demande.nomComplet
                                  : 'Utilisateur inconnu',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: app.AppColors.textMain,
                              ),
                            ),
                            Text(
                              demande.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: app.AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _libelleRole(demande.role),
                          style: TextStyle(
                            color: couleur,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Date + bouton détails ──
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: app.AppColors.textSub,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        demande.dateCreation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: app.AppColors.textSub,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _voirDetails(demande),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text("Détails"),
                        style: TextButton.styleFrom(
                          foregroundColor: app.AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  // ── Boutons Accepter / Refuser (en attente seulement) ──
                  if (!isHistorique) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _rejeterDemande(demande),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text("Refuser"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: app.AppColors.red,
                              side: const BorderSide(color: app.AppColors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _accepterDemande(demande),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check, size: 16),
                            label: const Text("Accepter"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: app.AppColors.green,
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

                  // ── Statut pour les demandes traitées ──
                  if (isHistorique) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: demande.status == 'actif'
                            ? app.AppColors.green.withValues(alpha: 0.1)
                            : app.AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            demande.status == 'actif'
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 14,
                            color: demande.status == 'actif'
                                ? app.AppColors.green
                                : app.AppColors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            demande.status == 'actif' ? 'Acceptée' : 'Refusée',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: demande.status == 'actif'
                                  ? app.AppColors.green
                                  : app.AppColors.red,
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
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: app.AppColors.textSub),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _chargerDemandes,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}