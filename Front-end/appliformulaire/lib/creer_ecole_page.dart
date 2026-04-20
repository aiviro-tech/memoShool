import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/ecoles_selection_page.dart';

class CreerEcolePage extends StatefulWidget {
  const CreerEcolePage({super.key});

  @override
  State<CreerEcolePage> createState() => _CreerEcolePageState();
}

class _CreerEcolePageState extends State<CreerEcolePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomOfficielController = TextEditingController();
  final _sigleController = TextEditingController();
  final _siteWebController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysController = TextEditingController();
  final _emailPrincipalController = TextEditingController();
  final _emailSecondaireController = TextEditingController();
  final _telFixeController = TextEditingController();
  final _telMobileController = TextEditingController();
  final _nomResponsableController = TextEditingController();
  final _titreResponsableController = TextEditingController();
  final _numeroRneController = TextEditingController();
  final _descriptionCourteController = TextEditingController();
  final _descriptionCompleteController = TextEditingController();
  final _maxEtudiantsController = TextEditingController();
  final _maxEnseignantsController = TextEditingController();

  String? _typeEtablissement;

  final List<String> _typesEtablissement = [
    'Public',
    'Privé',
    'Laïc',
    'Religieux',
    'International',
  ];

  void _soumettre() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);

      try {
        await ApiService.creerEcole({
          'nom_officiel': _nomOfficielController.text.trim(),
          'sigle': _sigleController.text.trim(),
          'site_web': _siteWebController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'ville': _villeController.text.trim(),
          'code_postal': _codePostalController.text.trim(),
          'pays': _paysController.text.trim(),
          'email_principal': _emailPrincipalController.text.trim(),
          'email_secondaire': _emailSecondaireController.text.trim(),
          'tel_fixe': _telFixeController.text.trim(),
          'tel_mobile': _telMobileController.text.trim(),
          'nom_responsable': _nomResponsableController.text.trim(),
          'titre_responsable': _titreResponsableController.text.trim(),
          'numero_rne': _numeroRneController.text.trim(),
          'type_etablissement': _typeEtablissement ?? 'Public',
          'description_courte': _descriptionCourteController.text.trim(),
          'description_complete': _descriptionCompleteController.text.trim(),
          'max_etudiants': _maxEtudiantsController.text.trim(),
          'max_enseignants': _maxEnseignantsController.text.trim(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DemandeEnCoursPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Créer une école"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Créer une école",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Remplissez les informations de votre établissement.\nIl sera validé par le Super Administrateur.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
              const SizedBox(height: 28),

              _titreSection("Identité de l'école"),
              const SizedBox(height: 14),
              _champ(
                "Nom officiel *",
                _nomOfficielController,
                obligatoire: true,
              ),
              const SizedBox(height: 12),
              _champ("Sigle / Acronyme", _sigleController),
              const SizedBox(height: 12),
              _champ(
                "Site web",
                _siteWebController,
                hint: "https://www.example.com",
              ),

              const SizedBox(height: 20),
              _titreSection("Localisation"),
              const SizedBox(height: 14),
              _champ(
                "Adresse complète *",
                _adresseController,
                obligatoire: true,
              ),
              const SizedBox(height: 12),
              _champ("Ville *", _villeController, obligatoire: true),
              const SizedBox(height: 12),
              _champ("Code postal", _codePostalController),
              const SizedBox(height: 12),
              _champ("Pays *", _paysController, obligatoire: true),

              const SizedBox(height: 20),
              _titreSection("Contact"),
              const SizedBox(height: 14),
              _champ(
                "Email principal *",
                _emailPrincipalController,
                obligatoire: true,
                clavier: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _champ(
                "Email secondaire",
                _emailSecondaireController,
                clavier: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _champ(
                "Téléphone fixe *",
                _telFixeController,
                obligatoire: true,
                clavier: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _champ(
                "Téléphone mobile",
                _telMobileController,
                clavier: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              _titreSection("Administration"),
              const SizedBox(height: 14),
              _champ(
                "Nom du responsable *",
                _nomResponsableController,
                obligatoire: true,
              ),
              const SizedBox(height: 12),
              _champ(
                "Titre du responsable *",
                _titreResponsableController,
                obligatoire: true,
                hint: "ex: Directeur, Proviseur",
              ),

              const SizedBox(height: 20),
              _titreSection("Informations légales"),
              const SizedBox(height: 14),
              _champ("Numéro RNE", _numeroRneController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _typeEtablissement,
                decoration: _deco("Type d'établissement *"),
                hint: const Text("Choisissez le type"),
                items: _typesEtablissement
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _typeEtablissement = v),
                validator: (v) => v == null
                    ? "Veuillez choisir le type d'établissement"
                    : null,
              ),

              const SizedBox(height: 20),
              _titreSection("Description"),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionCourteController,
                maxLength: 200,
                decoration: _deco("Description courte"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCompleteController,
                maxLines: 4,
                maxLength: 2000,
                decoration: _deco("Description complète"),
              ),

              const SizedBox(height: 20),
              _titreSection("Configuration"),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _champ(
                      "Nb max étudiants",
                      _maxEtudiantsController,
                      clavier: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champ(
                      "Nb max enseignants",
                      _maxEnseignantsController,
                      clavier: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _soumettre,
                  icon: const Icon(Icons.send_rounded),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Soumettre la demande",
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titreSection(String titre) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
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
          ? (v) => v == null || v.isEmpty ? "Ce champ est obligatoire" : null
          : null,
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

// ==========================================
// PAGE D'ATTENTE DE VALIDATION
// ==========================================
class DemandeEnCoursPage extends StatelessWidget {
  const DemandeEnCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_filled,
                size: 80,
                color: AppColors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                "Votre demande d'ouverture de création d'une école est en cours de vérification par le super admin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Vous recevrez une notification prochainement.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSub),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text("Revenir à l'accueil"),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EcolesSelectionPage(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Se déconnecter"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    SessionUtilisateur().vider();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Connexion()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
