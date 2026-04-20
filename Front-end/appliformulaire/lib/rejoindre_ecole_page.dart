import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/services/api_service.dart';

class RejoindreEcolePage extends StatefulWidget {
  const RejoindreEcolePage({super.key});

  @override
  State<RejoindreEcolePage> createState() => _RejoindreEcolePageState();
}

class _RejoindreEcolePageState extends State<RejoindreEcolePage> {
  int _etape = 1;
  String _roleChoisi = '';
  String _codeVerifie = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Rejoindre une école"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _IndicateurEtape(etapeActuelle: _etape, total: 3),
            const SizedBox(height: 24),

            if (_etape == 1)
              _EtapeChoixRole(
                onRoleChoisi: (role) {
                  setState(() {
                    _roleChoisi = role;
                    _etape = 2;
                  });
                },
              ),

            if (_etape == 2)
              _EtapeSaisieCode(
                role: _roleChoisi,
                onCodeValide: (code) {
                  setState(() {
                    _codeVerifie = code;
                    _etape = 3;
                  });
                },
                onRetour: () => setState(() => _etape = 1),
              ),

            if (_etape == 3)
              _EtapeInfosComplementaires(
                role: _roleChoisi,
                code: _codeVerifie,
                onRetour: () => setState(() => _etape = 2),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================
// INDICATEUR ÉTAPE
// ================================================
class _IndicateurEtape extends StatelessWidget {
  final int etapeActuelle;
  final int total;
  const _IndicateurEtape({required this.etapeActuelle, required this.total});

  @override
  Widget build(BuildContext context) {
    final etapes = ['Rôle', 'Code', 'Infos'];
    return Row(
      children: List.generate(etapes.length, (index) {
        final numero = index + 1;
        final estActif = numero == etapeActuelle;
        final estPasse = numero < etapeActuelle;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: estActif || estPasse
                          ? AppColors.primary
                          : Colors.grey[300],
                      child: estPasse
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '$numero',
                              style: TextStyle(
                                color: estActif ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etapes[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: estActif || estPasse
                            ? AppColors.primary
                            : Colors.grey,
                        fontWeight: estActif
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < etapes.length - 1)
                Expanded(
                  child: Divider(
                    color: numero < etapeActuelle
                        ? AppColors.primary
                        : Colors.grey[300],
                    thickness: 1.5,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ================================================
// ÉTAPE 1 : CHOIX DU RÔLE
// ================================================
class _EtapeChoixRole extends StatelessWidget {
  final Function(String) onRoleChoisi;
  const _EtapeChoixRole({required this.onRoleChoisi});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quel est votre rôle ?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Choisissez votre profil pour rejoindre une école",
          style: TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        const SizedBox(height: 24),

        _CarteRole(
          icone: Icons.school_rounded,
          titre: "Étudiant",
          description:
              "Consulter vos cours, notes, emploi du temps et supports",
          couleur: Colors.blue,
          onTap: () => onRoleChoisi('etudiant'),
        ),
        const SizedBox(height: 14),
        _CarteRole(
          icone: Icons.person_rounded,
          titre: "Enseignant",
          description:
              "Gérer vos cours, déposer des supports, saisir les notes",
          couleur: Colors.green,
          onTap: () => onRoleChoisi('enseignant'),
        ),
        const SizedBox(height: 14),
        _CarteRole(
          icone: Icons.admin_panel_settings_rounded,
          titre: "Administration",
          description:
              "Gérer l'établissement, valider les notes et les membres",
          couleur: Colors.orange,
          onTap: () => onRoleChoisi('admin'),
        ),
      ],
    );
  }
}

class _CarteRole extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String description;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteRole({
    required this.icone,
    required this.titre,
    required this.description,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: couleur.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: couleur, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ================================================
// ÉTAPE 2 : SAISIE CODE
// ================================================
class _EtapeSaisieCode extends StatefulWidget {
  final String role;
  final Function(String) onCodeValide;
  final VoidCallback onRetour;

  const _EtapeSaisieCode({
    required this.role,
    required this.onCodeValide,
    required this.onRetour,
  });

  @override
  State<_EtapeSaisieCode> createState() => _EtapeSaisieCodeState();
}

class _EtapeSaisieCodeState extends State<_EtapeSaisieCode> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _erreur = '';

  String get _prefixeAttendu {
    switch (widget.role) {
      case 'etudiant':
        return 'ETU-';
      case 'enseignant':
        return 'ENS-';
      case 'admin':
        return 'ADM-';
      default:
        return '';
    }
  }

  String get _libelleRole {
    switch (widget.role) {
      case 'etudiant':
        return 'Étudiant';
      case 'enseignant':
        return 'Enseignant';
      case 'admin':
        return 'Administration';
      default:
        return '';
    }
  }

  Color get _couleurRole {
    switch (widget.role) {
      case 'etudiant':
        return Colors.blue;
      case 'enseignant':
        return Colors.green;
      case 'admin':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  void _verifierCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _erreur = "Veuillez saisir le code d'invitation");
      return;
    }

    setState(() {
      _isLoading = true;
      _erreur = '';
    });

    try {
      final result = await ApiService.verifierCode(code);
      final role = result['role'] as String?;

      if (role == null || role != widget.role) {
        setState(() {
          _isLoading = false;
          _erreur =
              "Ce code ne correspond pas au rôle $_libelleRole. Vérifiez votre code.";
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onCodeValide(code);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          'Code invalide ou déjà utilisé. Contactez votre administration.';
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erreur = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erreur = 'Une erreur est survenue. Veuillez réessayer plus tard.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge rôle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _couleurRole.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Rôle : $_libelleRole",
            style: TextStyle(
              color: _couleurRole,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Code d'invitation",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Saisissez le code $_prefixeAttendu... reçu de votre administration",
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: "Code d'invitation",
            hintText: "${_prefixeAttendu}XXXXXXXX",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (_) => setState(() => _erreur = ''),
        ),

        if (_erreur.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _erreur,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onRetour,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Retour",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifierCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Vérifier le code"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Votre code vous est fourni uniquement par l'administration de votre établissement. "
                  "Étudiant : ETU-...  •  Enseignant : ENS-...  •  Admin : ADM-...",
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================
// ÉTAPE 3 : INFOS COMPLÉMENTAIRES
// ================================================
class _EtapeInfosComplementaires extends StatefulWidget {
  final String role;
  final String code;
  final VoidCallback onRetour;

  const _EtapeInfosComplementaires({
    required this.role,
    required this.code,
    required this.onRetour,
  });

  @override
  State<_EtapeInfosComplementaires> createState() =>
      _EtapeInfosComplementairesState();
}

class _EtapeInfosComplementairesState
    extends State<_EtapeInfosComplementaires> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Champs étudiant
  final _matriculeController = TextEditingController();
  final _tuteurNomController = TextEditingController();
  final _tuteurTelController = TextEditingController();
  String? _niveauSelectionne;
  String? _statutSelectionne;
  String? _anneeEntreeSelectionnee;

  // Champs enseignant
  final _matiereController = TextEditingController();
  final _diplomeController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _contratSelectionne;

  // Champs admin
  final _posteController = TextEditingController();
  String? _serviceSelectionne;
  String? _niveauAccesSelectionne;

  final List<String> _niveaux = ['L1', 'L2', 'L3', 'M1', 'M2', 'Doctorat'];
  final List<String> _statuts = ['Nouveau', 'Redoublant', 'Transfert'];
  final List<String> _annees = ['2024', '2025', '2026'];
  final List<String> _contrats = ['CDI', 'CDD', 'Vacataire', 'Stagiaire'];
  final List<String> _services = [
    'Scolarité',
    'Comptabilité',
    'Direction',
    'Vie scolaire',
    'Autre',
  ];
  final List<String> _niveauxAcces = ['Lecture seule', 'Saisie', 'Gestion'];

  void _soumettreDemande() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'code': widget.code,
        'niveau': _niveauSelectionne,
        'matricule': _matriculeController.text.trim(),
        'annee_entree': _anneeEntreeSelectionnee,
        'statut_etudiant': _statutSelectionne,
        'tuteur_nom': _tuteurNomController.text.trim(),
        'tuteur_tel': _tuteurTelController.text.trim(),
        'matiere_principale': _matiereController.text.trim(),
        'diplome': _diplomeController.text.trim(),
        'experience_annees': _experienceController.text.trim(),
        'type_contrat': _contratSelectionne,
        'poste': _posteController.text.trim(),
        'service': _serviceSelectionne,
        'niveau_acces': _niveauAccesSelectionne,
      };

      await ApiService.rejoindreEcole(data);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Demande soumise ! En attente de validation par l'administration.",
          ),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const _AttentePage()),
        (r) => false,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          'Impossible de soumettre la demande. Veuillez réessayer.';
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une erreur est survenue. Veuillez réessayer plus tard.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations complémentaires",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.role == 'etudiant'
                ? "Complétez votre profil étudiant"
                : widget.role == 'enseignant'
                ? "Complétez votre profil enseignant"
                : "Complétez votre profil administration",
            style: const TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (widget.role == 'etudiant') _champsEtudiant(),
          if (widget.role == 'enseignant') _champsEnseignant(),
          if (widget.role == 'admin') _champsAdmin(),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onRetour,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Retour",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _soumettreDemande,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Soumettre la demande"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _champsEtudiant() {
    return Column(
      children: [
        _dropdown(
          "Niveau / Classe *",
          _niveaux,
          _niveauSelectionne,
          (v) => setState(() => _niveauSelectionne = v),
          obligatoire: true,
        ),
        const SizedBox(height: 14),
        _champ("Numéro matricule", _matriculeController),
        const SizedBox(height: 14),
        _dropdown(
          "Année d'entrée *",
          _annees,
          _anneeEntreeSelectionnee,
          (v) => setState(() => _anneeEntreeSelectionnee = v),
          obligatoire: true,
        ),
        const SizedBox(height: 14),
        _dropdown(
          "Statut *",
          _statuts,
          _statutSelectionne,
          (v) => setState(() => _statutSelectionne = v),
          obligatoire: true,
        ),
        const SizedBox(height: 14),
        _champ("Nom du tuteur", _tuteurNomController),
        const SizedBox(height: 14),
        _champ(
          "Téléphone du tuteur",
          _tuteurTelController,
          clavier: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _champsEnseignant() {
    return Column(
      children: [
        _champ("Matière principale *", _matiereController, obligatoire: true),
        const SizedBox(height: 14),
        _champ(
          "Diplôme le plus élevé *",
          _diplomeController,
          obligatoire: true,
        ),
        const SizedBox(height: 14),
        _champ(
          "Années d'expérience *",
          _experienceController,
          obligatoire: true,
          clavier: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _dropdown(
          "Type de contrat *",
          _contrats,
          _contratSelectionne,
          (v) => setState(() => _contratSelectionne = v),
          obligatoire: true,
        ),
      ],
    );
  }

  Widget _champsAdmin() {
    return Column(
      children: [
        _champ(
          "Poste / Fonction *",
          _posteController,
          obligatoire: true,
          hint: "ex: Comptable, Secrétaire",
        ),
        const SizedBox(height: 14),
        _dropdown(
          "Service d'affectation *",
          _services,
          _serviceSelectionne,
          (v) => setState(() => _serviceSelectionne = v),
          obligatoire: true,
        ),
        const SizedBox(height: 14),
        _dropdown(
          "Niveau d'accès *",
          _niveauxAcces,
          _niveauAccesSelectionne,
          (v) => setState(() => _niveauAccesSelectionne = v),
          obligatoire: true,
        ),
      ],
    );
  }

  Widget _champ(
    String label,
    TextEditingController controller, {
    bool obligatoire = false,
    String? hint,
    TextInputType clavier = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: clavier,
      decoration: _deco(label, hint: hint),
      validator: obligatoire
          ? (v) => v == null || v.isEmpty ? "Champ obligatoire" : null
          : null,
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? valeur,
    Function(String?) onChange, {
    bool obligatoire = false,
  }) {
    return DropdownButtonFormField<String>(
      value: valeur,
      decoration: _deco(label),
      hint: Text("Choisir..."),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChange,
      validator: obligatoire ? (v) => v == null ? "Obligatoire" : null : null,
    );
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

// ================================================
// PAGE D'ATTENTE APRÈS SOUMISSION
// ================================================
class _AttentePage extends StatelessWidget {
  const _AttentePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Demande en attente",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Votre demande a été soumise. L'administration de l'école doit la valider avant que vous puissiez accéder à votre espace.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Connexion()),
                    (r) => false,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Se déconnecter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
