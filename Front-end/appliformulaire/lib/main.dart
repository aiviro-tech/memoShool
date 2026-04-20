import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/creer_ecole_page.dart';
import 'package:appliformulaire/super_admin_page.dart';
import 'package:appliformulaire/ecoles_selection_page.dart';
import 'package:appliformulaire/rejoindre_ecole_page.dart';
import 'package:appliformulaire/admin_dashboard_page.dart';
import 'package:appliformulaire/dashboard_screen.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const secondary = Color(0xFF00897B);
  static const background = Color(0xFFF5F7FA);
  static const textMain = Color(0xFF1A1A2E);
  static const textSub = Color(0xFF6B7280);
  static const green = Color(0xFF2E7D32);
  static const red = Color(0xFFC62828);
  static const orange = Color(0xFFE65100);
}

void main() {
  runApp(
    MaterialApp(
      home: const Connexion(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/ecoles-selection': (context) => const EcolesSelectionPage(),
        '/rejoindre-ecole': (context) => const RejoindreEcolePage(),
        '/creer-ecole': (context) => const CreerEcolePage(),
        '/admin-dashboard': (context) => AdminDashboardPage(
          ecoleId:
              int.tryParse(
                ModalRoute.of(context)?.settings.arguments as String? ?? '0',
              ) ??
              0,
        ),
      },
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ),
  );
}

// ==========================================
// 1. PAGE DE CONNEXION
// ==========================================
class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      SessionUtilisateur().setDepuisLogin(result);

      // Super admin → page super admin
      if (SessionUtilisateur().estSuperAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminPage()),
          (route) => false,
        );
      } else {
        // Tous les utilisateurs voient d'abord la page de sélection d'écoles.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EcolesSelectionPage()),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null) {
        errorMessage = e.error.toString();
      }
      errorMessage = errorMessage.replaceAll('Exception: ', '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Connexion",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Accédez à votre espace académique",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSub),
                ),
                const SizedBox(height: 32),
                InputCustom(
                  label: "Email",
                  hint: "votre-email@gmail.com",
                  isEmail: true,
                  controller: _emailController,
                ),
                const SizedBox(height: 15),
                InputCustom(
                  label: "Mot de passe",
                  hint: "Saisir votre mot de passe",
                  isPassword: true,
                  controller: _passwordController,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    ),
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    text: "Pas de compte ? ",
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Inscrivez-vous",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Inscription(),
                            ),
                          ),
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
}

// ==========================================
// 2. MOT DE PASSE OUBLIÉ
// ==========================================
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code envoyé par email !'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpResetPage(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null) {
        errorMessage = e.error.toString();
      }
      errorMessage = errorMessage.replaceAll('Exception: ', '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Récupération"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Réinitialisation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Entrez votre email pour recevoir un code",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 30),
              InputCustom(
                label: "Email",
                hint: "votre-email@gmail.com",
                isEmail: true,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Envoyer le code"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. OTP RESET
// ==========================================
class OtpResetPage extends StatefulWidget {
  final String email;
  const OtpResetPage({super.key, required this.email});

  @override
  State<OtpResetPage> createState() => _OtpResetPageState();
}

class _OtpResetPageState extends State<OtpResetPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  String _errorMessage = "";
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var c in _controllers) {
      c.addListener(
        () => setState(
          () =>
              _isButtonEnabled = _controllers.every((c) => c.text.length == 1),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    String codeSaisi = _controllers.map((e) => e.text).join();
    if (codeSaisi.length != 6) {
      setState(() => _errorMessage = 'Le code doit contenir 6 chiffres.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NewPasswordPage(email: widget.email, otpCode: codeSaisi),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Vérification"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Vérification",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Entrez le code à 6 chiffres reçu par email.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _otpBox(index)),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _controllers) c.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: const Text("Réessayer"),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? _verifyOtp
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Valider le code"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) => SizedBox(
    width: 45,
    child: TextField(
      controller: _controllers[index],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      onChanged: (v) {
        if (v.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
        if (v.isEmpty && index > 0) FocusScope.of(context).previousFocus();
      },
      decoration: const InputDecoration(
        counterText: "",
        border: OutlineInputBorder(),
      ),
    ),
  );
}

// ==========================================
// 4. NOUVEAU MOT DE PASSE
// ==========================================
class NewPasswordPage extends StatefulWidget {
  final String email;
  final String otpCode;
  const NewPasswordPage({
    super.key,
    required this.email,
    required this.otpCode,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: widget.email,
        otpCode: widget.otpCode,
        password: _passController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mot de passe mis à jour !"),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
        (r) => false,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null) {
        errorMessage = e.error.toString();
      }
      errorMessage = errorMessage.replaceAll('Exception: ', '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Nouveau mot de passe"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Réinitialisation",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 30),
              InputCustom(
                label: "Nouveau mot de passe",
                hint: "Minimum 8 caractères",
                isPassword: true,
                controller: _passController,
              ),
              const SizedBox(height: 15),
              InputCustom(
                label: "Confirmer",
                hint: "Confirmer le mot de passe",
                isPassword: true,
                controller: _confirmPassController,
                validator: (v) => v != _passController.text
                    ? "Les mots de passe ne correspondent pas"
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer"),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Connexion()),
                  (route) => false,
                ),
                child: const Text(
                  "Ignorer",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. INSCRIPTION
// ==========================================
class Inscription extends StatefulWidget {
  const Inscription({super.key});
  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _dateNaissanceController = TextEditingController();

  String? _sexeSelectionne;
  String? _nationaliteSelectionnee;
  bool _acceptTerms = false;
  bool _isLoading = false;

  final List<String> _nationalites = [
    'Béninoise',
    'Burkinabé',
    'Camerounaise',
    'Congolaise',
    'Ivoirienne',
    'Malienne',
    'Nigérienne',
    'Nigériane',
    'Sénégalaise',
    'Togolaise',
    'Autre',
  ];
  final List<String> _sexes = ['Masculin', 'Féminin', 'Autre'];

  Future<void> _choisirDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      _dateNaissanceController.text =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Mapper les valeurs du formulaire aux valeurs attendues par le backend
      final String sexeValue = _sexeSelectionne == 'Masculin'
          ? 'M'
          : _sexeSelectionne == 'Féminin'
          ? 'F'
          : 'other';

      await ApiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passController.text,
        dateOfBirth: _dateNaissanceController.text,
        gender: sexeValue,
        nationality: _nationaliteSelectionnee ?? '',
        phone: _telephoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inscription réussie ! Code OTP envoyé."),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ValidationInscription(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null) {
        errorMessage = e.error.toString();
      }
      errorMessage = errorMessage.replaceAll('Exception: ', '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textMain,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Inscription",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Créer un compte",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSub),
              ),
              const SizedBox(height: 24),

              InputCustom(
                label: "Nom *",
                hint: "Votre nom",
                controller: _lastNameController,
              ),
              const SizedBox(height: 14),
              InputCustom(
                label: "Prénom *",
                hint: "Votre prénom",
                controller: _firstNameController,
              ),
              const SizedBox(height: 14),
              InputCustom(
                label: "Email *",
                hint: "votre-email@gmail.com",
                isEmail: true,
                controller: _emailController,
              ),
              const SizedBox(height: 14),

              // Date de naissance
              GestureDetector(
                onTap: _choisirDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateNaissanceController,
                    decoration: InputDecoration(
                      labelText: "Date de naissance *",
                      hintText: "JJ/MM/AAAA",
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? "La date de naissance est obligatoire"
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sexe
              DropdownButtonFormField<String>(
                value: _sexeSelectionne,
                decoration: InputDecoration(
                  labelText: "Sexe *",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text("Choisissez votre sexe"),
                items: _sexes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _sexeSelectionne = v),
                validator: (v) =>
                    v == null ? "Veuillez choisir votre sexe" : null,
              ),
              const SizedBox(height: 14),

              // Téléphone facultatif
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Téléphone (facultatif)",
                  hintText: "+229 XX XX XX XX",
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Nationalité
              DropdownButtonFormField<String>(
                value: _nationaliteSelectionnee,
                decoration: InputDecoration(
                  labelText: "Nationalité *",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text("Choisissez votre nationalité"),
                items: _nationalites
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => _nationaliteSelectionnee = v),
                validator: (v) =>
                    v == null ? "Veuillez choisir votre nationalité" : null,
              ),
              const SizedBox(height: 14),

              InputCustom(
                label: "Mot de passe *",
                hint: "Minimum 8 caractères",
                isPassword: true,
                controller: _passController,
              ),
              const SizedBox(height: 14),
              InputCustom(
                label: "Confirmer le mot de passe *",
                hint: "Confirmer le mot de passe",
                isPassword: true,
                controller: _confirmPassController,
                validator: (value) => value != _passController.text
                    ? "Les mots de passe ne correspondent pas"
                    : null,
              ),
              const SizedBox(height: 16),

              // Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _acceptTerms = v!),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "J'accepte les politiques de ",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "sécurités",
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PolicyPage(
                                    title: "Politiques de Sécurité",
                                    content: """
POLITIQUE DE SÉCURITÉ DES SYSTÈMES

1. PROTECTION DES ACCÈS
L'accès à votre compte est protégé par un système de hachage cryptographique de pointe. Nous ne stockons jamais votre mot de passe en texte clair.

2. CHIFFREMENT DES DONNÉES
Toutes les données échangées entre votre appareil et nos serveurs sont cryptées via le protocole TLS 1.3.

3. INFRASTRUCTURE ET RÉSEAU
Notre infrastructure est hébergée dans des datacenters sécurisés. Nous utilisons des pare-feu applicatifs pour bloquer les menaces en temps réel.

4. AUDITS ET MISES À JOUR
Nous effectuons des tests d'intrusion réguliers et des scans de vulnérabilité.

5. RESPONSABILITÉ DE L'UTILISATEUR
Nous vous encourageons à utiliser un mot de passe complexe et unique.
""",
                                  ),
                                ),
                              ),
                          ),
                          const TextSpan(text: " et "),
                          TextSpan(
                            text: "confidentialités",
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PolicyPage(
                                    title: "Confidentialité",
                                    content: """
DÉCLARATION DE CONFIDENTIALITÉ

1. COLLECTE DES INFORMATIONS
Nous collectons uniquement les données nécessaires au fonctionnement de l'application.

2. UTILISATION DES DONNÉES
Vos données sont traitées uniquement pour la gestion de votre profil et les notifications de sécurité.

3. PARTAGE DES DONNÉES
Nous ne vendons jamais vos données personnelles à des tiers.

4. DURÉE DE CONSERVATION
Vos données sont conservées tant que votre compte reste actif.

5. VOS DROITS
Vous disposez d'un droit d'accès, de rectification et d'effacement de vos données.
""",
                                  ),
                                ),
                              ),
                          ),
                          const TextSpan(
                            text: " de l'utilisation de l'application",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "S'inscrire",
                          style: TextStyle(fontSize: 15),
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
}

// ==========================================
// 6. VALIDATION INSCRIPTION
// ==========================================
class ValidationInscription extends StatefulWidget {
  final String email;
  const ValidationInscription({super.key, required this.email});

  @override
  State<ValidationInscription> createState() => _ValidationInscriptionState();
}

class _ValidationInscriptionState extends State<ValidationInscription> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  bool _isButtonEnabled = false;
  String _errorMessage = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var c in _otpControllers) {
      c.addListener(
        () => setState(
          () => _isButtonEnabled = _otpControllers.every(
            (c) => c.text.length == 1,
          ),
        ),
      );
    }
  }

  Future<void> _finaliserInscription() async {
    String codeSaisi = _otpControllers.map((e) => e.text).join();
    setState(() => _isLoading = true);
    try {
      await ApiService.verifyEmail(email: widget.email, code: codeSaisi);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compte validé avec succès !"),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Validation"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 60,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              "Vérifiez votre email",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Entrez le code à 6 chiffres envoyé par email",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _otpControllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (v) {
                      if (v.isNotEmpty && index < 5)
                        FocusScope.of(context).nextFocus();
                      if (v.isEmpty && index > 0)
                        FocusScope.of(context).previousFocus();
                    },
                    decoration: const InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _otpControllers) c.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: const Text("Réessayer"),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? _finaliserInscription
                      : null,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Valider"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. WIDGETS DE BASE
// ==========================================
class PolicyPage extends StatelessWidget {
  final String title;
  final String content;
  const PolicyPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Text(content, textAlign: TextAlign.justify),
      ),
    );
  }
}

class InputCustom extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final bool isEmail;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const InputCustom({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.isEmail = false,
    this.controller,
    this.validator,
  });

  @override
  State<InputCustom> createState() => _InputCustomState();
}

class _InputCustomState extends State<InputCustom> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          validator:
              widget.validator ??
              (value) {
                if (value == null || value.isEmpty) return "Champ obligatoire";
                if (widget.isEmail) {
                  final bool emailValid = RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
                  ).hasMatch(value);
                  if (!emailValid) return "Email invalide.";
                }
                // Mot de passe : juste 8 caractères minimum, rien d'autre
                if (widget.isPassword && value.length < 8) {
                  return "Mot de passe trop court (8 caractères minimum).";
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSub,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
