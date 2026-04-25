import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appliformulaire/main.dart';

// ================================================
// MODLE CODE D'INVITATION
// ================================================
class CodeInvitation {
  final String id;
  String code;
  final String role;
  final String destinataire;
  final String dateCreation;
  bool utilise;

  CodeInvitation({
    required this.id,
    required this.code,
    required this.role,
    required this.destinataire,
    required this.dateCreation,
    this.utilise = false,
  });
}

// Base de codes  partage dans toute l'app
// En production  cette liste vient de l'API Laravel
List<CodeInvitation> baseDeCodes = [];

// ================================================
// PAGE GESTION DES CODES
// ================================================
class GestionCodesPage extends StatefulWidget {
  const GestionCodesPage({super.key});

  static bool codeExiste(String code) {
    return baseDeCodes.any(
      (c) => c.code == code.trim().toUpperCase() && !c.utilise,
    );
  }

  static String? getRoleDuCode(String code) {
    try {
      final c = baseDeCodes.firstWhere(
        (c) => c.code == code.trim().toUpperCase() && !c.utilise,
      );
      return c.role;
    } catch (_) {
      return null;
    }
  }

  static void marquerUtilise(String code) {
    for (var c in baseDeCodes) {
      if (c.code == code.trim().toUpperCase()) {
        c.utilise = true;
      }
    }
  }

  @override
  State<GestionCodesPage> createState() => _GestionCodesPageState();
}

class _GestionCodesPageState extends State<GestionCodesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _roleFiltre = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Gnre un code unique selon le rle
  String _genererCode(String role) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final suffix = List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    switch (role) {
      case 'etudiant':
        return 'ETU-$suffix';
      case 'enseignant':
        return 'ENS-$suffix';
      default:
        return 'ADM-$suffix';
    }
  }

  String _dateAujourdhui() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _afficherDialogueGenerer() {
    String roleChoisi = 'etudiant';
    final destinataireController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Gnrer un code d'invitation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    " Ce code est unique et personnel. Ne le partagez qu'avec la personne concerne.",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
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
                    labelText: "Rle *",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'etudiant',
                      child: Text("tudiant"),
                    ),
                    DropdownMenuItem(
                      value: 'enseignant',
                      child: Text("Enseignant"),
                    ),
                    DropdownMenuItem(
                      value: 'administration',
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
                if (destinataireController.text.trim().isEmpty) {
                  return;
                }
                final nouveauCode = CodeInvitation(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: _genererCode(roleChoisi),
                  role: roleChoisi,
                  destinataire: destinataireController.text.trim(),
                  dateCreation: _dateAujourdhui(),
                );
                setState(() => baseDeCodes.add(nouveauCode));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Code gnr pour ${destinataireController.text.trim()}",
                    ),
                    backgroundColor: AppColors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Gnrer"),
            ),
          ],
        ),
      ),
    );
  }

  List<CodeInvitation> get _codesFiltres {
    if (_roleFiltre == 'Tous') return baseDeCodes;
    return baseDeCodes.where((c) => c.role == _roleFiltre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Codes d'invitation"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline, size: 18),
              text: "Gnrer",
            ),
            Tab(icon: Icon(Icons.list_alt, size: 18), text: "Mes codes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1 : Explication + bouton gnrer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Comment a fonctionne ?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                _etapeExplication(
                  "1",
                  "Gnrez un code unique pour chaque tudiant, enseignant ou administration",
                  Colors.blue,
                ),
                _etapeExplication(
                  "2",
                  "Partagez ce code uniquement  la personne concerne",
                  Colors.green,
                ),
                _etapeExplication(
                  "3",
                  "La personne utilise ce code pour rejoindre votre cole",
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
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
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
                          "Chaque code est unique et personnel. Un code utilis ne peut pas tre rutilis.",
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
                      "Gnrer un nouveau code",
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
          ),

          // Onglet 2 : Liste des codes
          Column(
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
                        color: AppColors.textSub,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...['Tous', 'etudiant', 'enseignant', 'administration'].map(
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
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              role == 'etudiant'
                                  ? 'tudiant'
                                  : role == 'enseignant'
                                  ? 'Enseignant'
                                  : role,
                              style: TextStyle(
                                fontSize: 12,
                                color: _roleFiltre == role
                                    ? Colors.white
                                    : AppColors.primary,
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
                              color: AppColors.textSub.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Aucun code gnr",
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Allez dans l'onglet \"Gnrer\" pour crer des codes",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSub,
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
                            onSupprimer: () {
                              setState(
                                () => baseDeCodes.removeWhere(
                                  (c) => c.id == code.id,
                                ),
                              );
                            },
                            onRegenerer: () => _regenererCode(code),
                            onCopier: () {
                              Clipboard.setData(ClipboardData(text: code.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Code copi dans le presse-papiers',
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _regenererCode(CodeInvitation code) {
    String nouveauCode;
    do {
      nouveauCode = _genererCode(code.role);
    } while (GestionCodesPage.codeExiste(nouveauCode));
    setState(() {
      code.code = nouveauCode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code rgnr avec succs'),
        backgroundColor: AppColors.green,
      ),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}

// Carte code
class _CarteCode extends StatelessWidget {
  final CodeInvitation code;
  final VoidCallback onSupprimer;
  final VoidCallback onRegenerer;
  final VoidCallback onCopier;

  const _CarteCode({
    required this.code,
    required this.onSupprimer,
    required this.onRegenerer,
    required this.onCopier,
  });

  Color get _couleur {
    switch (code.role) {
      case 'etudiant':
        return Colors.blue;
      case 'enseignant':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String get _libelle {
    switch (code.role) {
      case 'etudiant':
        return 'tudiant';
      case 'enseignant':
        return 'Enseignant';
      default:
        return 'Admin';
    }
  }

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
                    code.destinataire,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                // Badge rle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _couleur.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _libelle,
                    style: TextStyle(
                      fontSize: 11,
                      color: _couleur,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge utilis ou non
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: code.utilise
                        ? Colors.grey.withValues(alpha: 0.1)
                        : AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code.utilise ? "Utilis" : "Disponible",
                    style: TextStyle(
                      fontSize: 11,
                      color: code.utilise ? Colors.grey : AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Code avec bouton copier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: code.utilise ? Colors.grey[100] : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: code.utilise
                      ? Colors.grey.withValues(alpha: 0.3)
                      : _couleur.withValues(alpha: 0.3),
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
                        color: code.utilise ? Colors.grey : AppColors.textMain,
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
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Code copi !"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
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
                  "Cr le ${code.dateCreation}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
                const Spacer(),
                if (!code.utilise) ...[
                  TextButton.icon(
                    onPressed: onCopier,
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      "Copier",
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: onRegenerer,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.orange,
                    ),
                    label: const Text(
                      "Rgnrer",
                      style: TextStyle(color: AppColors.orange, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.red,
                    ),
                    label: const Text(
                      "Supprimer",
                      style: TextStyle(color: AppColors.red, fontSize: 12),
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
