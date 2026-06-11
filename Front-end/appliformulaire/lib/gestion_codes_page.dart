import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/services/api_service.dart';

// ================================================
// MODÈLE CODE D'INVITATION (API)
// ================================================
class CodeInvitation {
  final int id;
  final String code;
  final String role;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  CodeInvitation({
    required this.id,
    required this.code,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory CodeInvitation.fromJson(Map<String, dynamic> json) {
    return CodeInvitation(
      id: json['id'] as int,
      code: json['code'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  bool get utilise => !isActive;
  String get dateCreation {
    if (createdAt.isEmpty) return '';
    return createdAt.split('T')[0];
  }
}

// ================================================
// PAGE GESTION DES CODES
// ================================================
class GestionCodesPage extends StatefulWidget {
  const GestionCodesPage({super.key});

  @override
  State<GestionCodesPage> createState() => _GestionCodesPageState();
}

class _GestionCodesPageState extends State<GestionCodesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _roleFiltre = 'Tous';

  List<CodeInvitation> _codes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerCodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.dio.get('/api/mes-codes');
      final List<dynamic> data = response.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _codes = data.map((c) => CodeInvitation.fromJson(c)).toList();
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

  Future<void> _genererCode(String role, String destinataire) async {
    try {
      final response = await ApiService.dio.post(
        '/api/codes/generer',
        data: {'role': role, 'destinataire': destinataire},
      );
      if (response.data['success'] == true) {
        await _chargerCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code généré pour $destinataire'),
              backgroundColor: app.AppColors.green,
            ),
          );
        }
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
    }
  }

  Future<void> _regenererCode(CodeInvitation code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Régénérer le code'),
        content: Text(
          'Êtes-vous sûr ? L\'ancien code sera désactivé immédiatement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await ApiService.dio.put(
        '/api/codes/${code.id}/regenerer',
      );
      if (response.data['success'] == true) {
        await _chargerCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code régénéré avec succès'),
              backgroundColor: app.AppColors.green,
            ),
          );
        }
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
    }
  }

  Future<void> _supprimerCode(CodeInvitation code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le code'),
        content: Text('Voulez-vous vraiment supprimer le code ${code.code} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await ApiService.dio.delete('/api/codes/${code.id}');
      if (response.data['success'] == true) {
        await _chargerCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code supprimé'),
              backgroundColor: app.AppColors.green,
            ),
          );
        }
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
    }
  }

  void _copierCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _afficherDialogueGenerer() {
    String roleChoisi = 'etudiant';
    final destinataireController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Générer un code d'invitation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: app.AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Ce code est unique et personnel. Ne le partagez qu'avec la personne concernée.",
                    style: TextStyle(fontSize: 12, color: app.AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: destinataireController,
                  decoration: const InputDecoration(
                    labelText: "Nom du destinataire *",
                    border: OutlineInputBorder(),
                    hintText: "Ex: Jean Dupont",
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: roleChoisi,
                  decoration: const InputDecoration(
                    labelText: "Rôle *",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'etudiant',
                      child: Text("Étudiant"),
                    ),
                    DropdownMenuItem(
                      value: 'enseignant',
                      child: Text("Enseignant"),
                    ),
                    DropdownMenuItem(
                      value: 'admin_school',
                      child: Text("Administration"),
                    ),
                  ],
                  onChanged: (v) => setStateDialog(() => roleChoisi = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (destinataireController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _genererCode(roleChoisi, destinataireController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: app.AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Générer"),
            ),
          ],
        ),
      ),
    );
  }

  List<CodeInvitation> get _codesFiltres {
    if (_roleFiltre == 'Tous') return _codes;
    return _codes.where((c) => c.role == _roleFiltre).toList();
  }

  String _libelleRole(String role) {
    switch (role) {
      case 'etudiant':
        return 'Étudiant';
      case 'enseignant':
        return 'Enseignant';
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
      case 'admin_school':
        return Colors.orange;
      default:
        return app.AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text("Codes d'invitation"),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerCodes),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline, size: 18),
              text: "Générer",
            ),
            Tab(icon: Icon(Icons.list_alt, size: 18), text: "Mes codes"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [_buildOngletGenerer(), _buildOngletListe()],
            ),
    );
  }

  Widget _buildOngletGenerer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comment ça fonctionne ?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: app.AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          _etapeExplication(
            "1",
            "Générez un code unique pour chaque étudiant, enseignant ou administration",
            Colors.blue,
          ),
          _etapeExplication(
            "2",
            "Partagez ce code uniquement à la personne concernée",
            Colors.green,
          ),
          _etapeExplication(
            "3",
            "La personne utilise ce code pour rejoindre votre école",
            Colors.orange,
          ),
          _etapeExplication(
            "4",
            "Vous validez sa demande depuis l'onglet Membres",
            Colors.purple,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Chaque code est unique et personnel. Un code utilisé ne peut pas être réutilisé.",
                    style: TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _afficherDialogueGenerer,
              icon: const Icon(Icons.add),
              label: const Text(
                "Générer un nouveau code",
                style: TextStyle(fontSize: 15),
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
        ],
      ),
    );
  }

  Widget _buildOngletListe() {
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                "Filtrer : ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: app.AppColors.textSub,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              ...['Tous', 'etudiant', 'enseignant', 'admin_school'].map(
                (role) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _roleFiltre = role),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _roleFiltre == role
                            ? app.AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: app.AppColors.primary),
                      ),
                      child: Text(
                        role == 'etudiant'
                            ? 'Étudiant'
                            : role == 'enseignant'
                            ? 'Enseignant'
                            : role == 'admin_school'
                            ? 'Admin'
                            : 'Tous',
                        style: TextStyle(
                          fontSize: 12,
                          color: _roleFiltre == role
                              ? Colors.white
                              : app.AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _codesFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.vpn_key_outlined,
                        size: 52,
                        color: app.AppColors.textSub.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Aucun code généré",
                        style: TextStyle(
                          color: app.AppColors.textSub,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Allez dans l'onglet \"Générer\" pour créer des codes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: app.AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _codesFiltres.length,
                  itemBuilder: (context, index) {
                    final code = _codesFiltres[index];
                    return _CarteCode(
                      code: code,
                      libelleRole: _libelleRole(code.role),
                      couleurRole: _couleurRole(code.role),
                      onRegenerer: () => _regenererCode(code),
                      onSupprimer: () => _supprimerCode(code),
                      onCopier: () => _copierCode(code.code),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _etapeExplication(String numero, String texte, Color couleur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: couleur.withValues(alpha: 0.15),
            child: Text(
              numero,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(fontSize: 13, color: app.AppColors.textMain),
            ),
          ),
        ],
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
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _chargerCodes,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ─── Carte code ───────────────────────────────────────────────────────────────

class _CarteCode extends StatelessWidget {
  final CodeInvitation code;
  final String libelleRole;
  final Color couleurRole;
  final VoidCallback onRegenerer;
  final VoidCallback onSupprimer;
  final VoidCallback onCopier;

  const _CarteCode({
    required this.code,
    required this.libelleRole,
    required this.couleurRole,
    required this.onRegenerer,
    required this.onSupprimer,
    required this.onCopier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    libelleRole,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: app.AppColors.textMain,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: code.utilise
                        ? Colors.grey.withValues(alpha: 0.1)
                        : app.AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code.utilise ? "Utilisé" : "Disponible",
                    style: TextStyle(
                      fontSize: 11,
                      color: code.utilise ? Colors.grey : app.AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: code.utilise ? Colors.grey[100] : app.AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: code.utilise
                      ? Colors.grey.withValues(alpha: 0.3)
                      : couleurRole.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: code.utilise ? Colors.grey : app.AppColors.textMain,
                        decoration: code.utilise
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (!code.utilise)
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: app.AppColors.primary,
                        size: 20,
                      ),
                      onPressed: onCopier,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Créé le ${code.dateCreation}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: app.AppColors.textSub,
                  ),
                ),
                const Spacer(),
                if (!code.utilise) ...[
                  TextButton.icon(
                    onPressed: onCopier,
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: app.AppColors.primary,
                    ),
                    label: const Text(
                      "Copier",
                      style: TextStyle(color: app.AppColors.primary, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: onRegenerer,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: app.AppColors.orange,
                    ),
                    label: const Text(
                      "Régénérer",
                      style: TextStyle(color: app.AppColors.orange, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: app.AppColors.red,
                    ),
                    label: const Text(
                      "Supprimer",
                      style: TextStyle(color: app.AppColors.red, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}