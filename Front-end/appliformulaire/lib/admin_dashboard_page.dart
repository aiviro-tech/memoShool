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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final session = SessionUtilisateur();
    if (session.token.isNotEmpty) {
      ApiService.setToken(session.token);
    }
    _demandeFuture = _loadDemandes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rafraîchir les demandes quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _demandeFuture = _loadDemandes();
      });
    }
  }

  Future<Map<String, dynamic>> _loadDemandes() async {
    final demandes = await ApiService.demandesEnAttente();
    return {'demandes': demandes};
  }

  Future<void> _accepterDemande(int demandeId) async {
    try {
      await ApiService.accepterDemande(demandeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Demande acceptée avec succès"),
          backgroundColor: AppColors.green,
        ),
      );
      setState(() {
        _demandeFuture = _loadDemandes();
      });
    } catch (e) {
      _showErrorSnackbar(e);
    }
  }

  Future<void> _rejeterDemande(int demandeId) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Motif du rejet"),
        content: TextField(
          decoration: const InputDecoration(
            hintText: "Expliquez pourquoi vous rejetez cette demande",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, "Rejeté par administrateur"),
            child: const Text("Confirmer"),
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
        setState(() {
          _demandeFuture = _loadDemandes();
        });
      } catch (e) {
        _showErrorSnackbar(e);
      }
    }
  }

  Future<void> _regenererCode(int codeId, String ancienCode) async {
    try {
      final result = await ApiService.regenererCode(codeId);
      final newCode = result['nouveau'] ?? 'ERREUR';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Code régénéré"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Ancien code: $ancienCode"),
                const SizedBox(height: 16),
                Text(
                  "Nouveau code: $newCode",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
      }
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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _demandeFuture = _loadDemandes();
          });
          await _demandeFuture;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "DEMANDES EN ATTENTE DE VALIDATION",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _demandeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  }
                  final demandes = List.from(snapshot.data?['demandes'] ?? []);
                  if (demandes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
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
                      return _CarteDemande(
                        id: demande['id'] is int
                            ? demande['id'] as int
                            : int.tryParse(demande['id']?.toString() ?? '') ??
                                  0,
                        nom: (() {
                          final user = demande['user'] as Map<String, dynamic>?;
                          final firstName =
                              user?['first_name']?.toString() ?? '';
                          final lastName = user?['last_name']?.toString() ?? '';
                          return ('$firstName $lastName').trim();
                        })(),
                        role: demande['role']?.toString() ?? '',
                        email:
                            (demande['user'] as Map<String, dynamic>?)?['email']
                                ?.toString() ??
                            '',
                        dateCreation: demande['created_at']?.toString() ?? '',
                        onAccepter: () => _accepterDemande(
                          demande['id'] is int
                              ? demande['id'] as int
                              : int.tryParse(demande['id']?.toString() ?? '') ??
                                    0,
                        ),
                        onRejeter: () => _rejeterDemande(
                          demande['id'] is int
                              ? demande['id'] as int
                              : int.tryParse(demande['id']?.toString() ?? '') ??
                                    0,
                        ),
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                  child: const Text("✗ Rejeter"),
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
              color: Colors.orange.withOpacity(0.1),
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
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
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
