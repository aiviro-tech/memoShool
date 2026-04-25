import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class AdminDashboardPage extends StatefulWidget {
  final int ecoleId;

  const AdminDashboardPage({super.key, required this.ecoleId});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _demandeFuture;
  Timer? _autoRefreshTimer;
  int _dernierCompteDemandes = 0;
  bool _nouvellesDemandes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final session = SessionUtilisateur();
    if (session.token.isNotEmpty) {
      ApiService.setToken(session.token);
    }
    _demandeFuture = _loadDemandes();
    _demarrerAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _rafraichir();
      _demarrerAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _autoRefreshTimer?.cancel();
    }
  }

  void _demarrerAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _rafraichirSilencieux();
    });
  }

  void _rafraichir() {
    setState(() {
      _demandeFuture = _loadDemandes();
      _nouvellesDemandes = false;
    });
  }

  /// Rafraîchissement silencieux : ne reconstruit que si de nouvelles demandes arrivent
  Future<void> _rafraichirSilencieux() async {
    try {
      final data = await ApiService.demandesEnAttente();
      final count = data.length;
      if (count != _dernierCompteDemandes && mounted) {
        setState(() {
          _nouvellesDemandes = count > _dernierCompteDemandes;
          _dernierCompteDemandes = count;
          _demandeFuture = Future.value({'demandes': data});
        });
      }
    } catch (_) {
      // Ignorer les erreurs silencieuses
    }
  }

  Future<Map<String, dynamic>> _loadDemandes() async {
    final demandes = await ApiService.demandesEnAttente();
    _dernierCompteDemandes = demandes.length;
    return {'demandes': demandes};
  }

  Future<void> _accepterDemande(int demandeId) async {
    try {
      await ApiService.accepterDemande(demandeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✓ Demande acceptée avec succès"),
          backgroundColor: AppColors.green,
        ),
      );
      _rafraichir();
    } catch (e) {
      _showErrorSnackbar(e);
    }
  }

  Future<void> _rejeterDemande(int demandeId) async {
    final motifController = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Motif du rejet"),
        content: TextField(
          controller: motifController,
          decoration: const InputDecoration(
            hintText: "Expliquez pourquoi vous rejetez cette demande",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(
              context,
              motifController.text.isNotEmpty
                  ? motifController.text
                  : "Rejeté par l'administrateur",
            ),
            child: const Text("Confirmer le rejet"),
          ),
        ],
      ),
    );

    if (motif != null && mounted) {
      try {
        await ApiService.rejeterDemande(demandeId, motif);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande rejetée"),
            backgroundColor: AppColors.orange,
          ),
        );
        _rafraichir();
      } catch (e) {
        _showErrorSnackbar(e);
      }
    }
  }

  Future<void> _regenererCode(int codeId, String ancienCode) async {
    try {
      final result = await ApiService.regenererCode(codeId);
      final newCode = result['nouveau'] ?? 'ERREUR';
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text("Code régénéré"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ancien code: $ancienCode",
                  style: const TextStyle(color: AppColors.textSub)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  newCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackbar(e);
    }
  }

  void _showErrorSnackbar(dynamic e) {
    String errorMessage = e.toString();
    if (e is DioException && e.error != null) {
      errorMessage = e.error.toString();
    }
    errorMessage = errorMessage.replaceAll('Exception: ', '');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: AppColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Gestion de l'école"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Badge de nouvelles demandes
          if (_nouvellesDemandes)
            IconButton(
              icon: const Stack(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              tooltip: "Nouvelles demandes reçues !",
              onPressed: _rafraichir,
            ),
          // Bouton rafraîchir manuel
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualiser",
            onPressed: _rafraichir,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: () async {
              _autoRefreshTimer?.cancel();
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
                if (!mounted) return;
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
      body: RefreshIndicator(
        onRefresh: () async => _rafraichir(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau info auto-refresh
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Actualisation automatique toutes les 15 secondes",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (_nouvellesDemandes)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Nouvelles demandes !",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),


              Row(
                children: [
                  const Text(
                    "DEMANDES EN ATTENTE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _demandeFuture,
                    builder: (_, snap) {
                      final count =
                          (snap.data?['demandes'] as List?)?.length ?? 0;
                      if (count == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count en attente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _demandeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          Text("Erreur: ${snapshot.error}"),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _rafraichir,
                            child: const Text("Réessayer"),
                          ),
                        ],
                      ),
                    );
                  }
                  final demandes =
                      List.from(snapshot.data?['demandes'] ?? []);
                  if (demandes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "✓ Aucune demande en attente",
                          style: TextStyle(color: AppColors.green),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: demandes.map((demande) {
                      final id = demande['id'] is int
                          ? demande['id'] as int
                          : int.tryParse(demande['id']?.toString() ?? '') ?? 0;
                      final user =
                          demande['user'] as Map<String, dynamic>? ?? {};
                      final nom =
                          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                              .trim();
                      return _CarteDemande(
                        id: id,
                        nom: nom,
                        role: demande['role']?.toString() ?? '',
                        email: user['email']?.toString() ?? '',
                        dateCreation:
                            demande['created_at']?.toString() ?? '',
                        onAccepter: () => _accepterDemande(id),
                        onRejeter: () => _rejeterDemande(id),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                "CODES D'INVITATION",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Les 3 codes permanents pour inviter des utilisateurs",
                style: TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              const SizedBox(height: 8),
              const Text(
                "Chaque code est alphanumérique et fait 12 caractères au total.",
                style: TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              const SizedBox(height: 16),
              _CodesListWidget(onRegenerer: _regenererCode),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final int id;
  final String nom;
  final String role;
  final String email;
  final String dateCreation;
  final VoidCallback onAccepter;
  final VoidCallback onRejeter;

  const _CarteDemande({
    required this.id,
    required this.nom,
    required this.role,
    required this.email,
    required this.dateCreation,
    required this.onAccepter,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "$email • Rôle: $role",
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccepter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("✓ Accepter"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRejeter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                  ),
                  child: const Text("✕ Rejeter"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodesListWidget extends StatefulWidget {
  final Function(int, String) onRegenerer;

  const _CodesListWidget({required this.onRegenerer});

  @override
  State<_CodesListWidget> createState() => _CodesListWidgetState();
}

class _CodesListWidgetState extends State<_CodesListWidget> {
  late Future<List<dynamic>> _codesFuture;

  @override
  void initState() {
    super.initState();
    _codesFuture = ApiService.mesCodes();
  }

  void _refreshCodes() {
    setState(() {
      _codesFuture = ApiService.mesCodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _codesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Erreur chargement codes: ${snapshot.error}"),
          );
        }

        final codes = List.from(snapshot.data ?? []);

        // Dédupliquage : garder un seul code par rôle
        final Map<String, dynamic> codesUniques = {};
        for (var code in codes) {
          final role = code['role']?.toString() ?? 'unknown';
          if (!codesUniques.containsKey(role)) {
            codesUniques[role] = code;
          }
        }
        final codesList = codesUniques.values.toList();

        if (codesList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  "Aucun code d'invitation trouvé",
                  style: TextStyle(color: AppColors.orange),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _refreshCodes,
                  child: const Text("Actualiser"),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...codesList.map((code) {
              final codeId = code['id'] is int
                  ? code['id'] as int
                  : int.tryParse(code['id']?.toString() ?? '') ?? 0;
              final codeValue = code['code']?.toString() ?? '';
              final codeRole = code['role']?.toString() ?? '';

              String prefix;
              switch (codeRole.toLowerCase()) {
                case 'etudiant':
                  prefix = 'ETU';
                  break;
                case 'enseignant':
                  prefix = 'ENS';
                  break;
                case 'admin':
                case 'administration':
                  prefix = 'ADM';
                  break;
                default:
                  prefix = 'UNK';
              }

              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prefix,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            codeRole,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            codeValue,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: codeValue));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié dans le presse-papiers'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: "Copier ce code",
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: () async {
                        await widget.onRegenerer(codeId, codeValue);
                        _refreshCodes(); // Actualiser après régénération
                      },
                      tooltip: "Régénérer ce code",
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshCodes,
              icon: const Icon(Icons.refresh),
              label: const Text("Actualiser les codes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
