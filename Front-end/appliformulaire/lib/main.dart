import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appliformulaire/firebase_options.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/notification_service.dart';
import 'package:appliformulaire/creer_ecole_page.dart';
import 'package:appliformulaire/super_admin_page.dart';
import 'package:appliformulaire/ecoles_selection_page.dart';
import 'package:appliformulaire/rejoindre_ecole_page.dart';
import 'package:appliformulaire/features/profil/profil_screen.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const primaryDark = Color(0xFF0D47A1);
  static const secondary = Color(0xFF00897B);
  static const background = Color(0xFFF0F4FF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textMain = Color(0xFF1A1A2E);
  static const textSub = Color(0xFF6B7280);
  static const green = Color(0xFF2E7D32);
  static const red = Color(0xFFC62828);
  static const orange = Color(0xFFE65100);
  static const accent = Color(0xFF2979FF);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await NotificationService.initialiser();
  }
  runApp(const MyApp());
}

// ── Widget racine qui écoute ThemeNotifier ────────────────────────────────────
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeNotifier.instance.isDark.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeNotifier.instance.isDark.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDark.value;

    return MaterialApp(
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(viewInsets: EdgeInsets.zero),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Connexion(),
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
      routes: {
        '/login': (context) => const Connexion(),
        '/ecoles-selection': (context) => const EcolesSelectionPage(),
        '/rejoindre-ecole': (context) => const RejoindreEcolePage(),
        '/creer-ecole': (context) => const CreerEcolePage(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: const Color(0xFFF0F4FF),
        onSurface: const Color(0xFF1A1A2E),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF0F4FF),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE0E0E0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.8),
        ),
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.textSub),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E2E),
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF2A2A3E),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF121220),
      cardColor: const Color(0xFF1E1E2E),
      dividerColor: const Color(0xFF3A3A4A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A4A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.8),
        ),
        hintStyle: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 13.5),
        labelStyle: const TextStyle(color: Color(0xFF9E9EBE)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      debugPrint('═══════════════════════════════════════════');
      debugPrint(' RÉPONSE API COMPLÈTE:');
      debugPrint(result.toString());
      debugPrint('═══════════════════════════════════════════');

      SessionUtilisateur().setDepuisLogin(result);

      debugPrint(' RÔLE CHARGÉ: "${SessionUtilisateur().role}"');
      debugPrint(' estSuperAdmin: ${SessionUtilisateur().estSuperAdmin}');
      debugPrint(' Token présent: ${SessionUtilisateur().token.isNotEmpty}');

      final roleManuel = result['user']?['role'] ?? result['role'] ?? 'aucun';
      debugPrint(' Rôle depuis la réponse: "$roleManuel"');

      final token = SessionUtilisateur().token;
      if (token.isNotEmpty) {
        ApiService.setToken(token);
        debugPrint(' Token positionné dans ApiService');
      }

      if (SessionUtilisateur().estSuperAdmin) {
        debugPrint(' REDIRECTION VERS: SuperAdminPage');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminPage()),
          (route) => false,
        );
      } else {
        debugPrint(' REDIRECTION VERS: EcolesSelectionPage');
        debugPrint('   (Rôle = ${SessionUtilisateur().role})');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EcolesSelectionPage()),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null)
        errorMessage = e.error.toString();
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      debugPrint(' ERREUR DE CONNEXION: $errorMessage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Couleurs adaptées au thème
    final formBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F7FF);
    final labelColor = isDark ? Colors.white : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 30),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Espace Académique",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: formBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Connexion",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: labelColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Accédez à votre espace académique",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subColor,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildLabel("Email", labelColor),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: "votre-email@gmail.com",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return "Champ obligatoire";
                                    if (!RegExp(
                                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
                                    ).hasMatch(v)) {
                                      return "Email invalide";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildLabel("Mot de passe", labelColor),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordPage(),
                                        ),
                                      ),
                                      child: const Text(
                                        "Mot de passe oublié ?",
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _StyledPasswordField(
                                  label: "",
                                  controller: _passwordController,
                                  hint: "Saisir votre mot de passe",
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return "Champ obligatoire";
                                    if (v.length < 8)
                                      return "8 caractères minimum";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      elevation: 4,
                                      shadowColor: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Se connecter',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: isDark
                                            ? const Color(0xFF3A3A4A)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "ou",
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF6B6B8A)
                                              : Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: isDark
                                            ? const Color(0xFF3A3A4A)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Pas encore de compte ? ",
                                      style: TextStyle(
                                        color: subColor,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "S'inscrire",
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const Inscription(),
                                              ),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary.withValues(alpha: 0.7),
          size: 20,
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Code envoyé par email !'),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      if (e is DioException && e.error != null)
        errorMessage = e.error.toString();
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Récupération",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Réinitialisation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Entrez votre email pour recevoir un code de vérification",
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 32),
              // Card pour le formulaire
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _StyledField(
                  controller: _emailController,
                  label: "Email",
                  hint: "votre-email@gmail.com",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Champ obligatoire";
                    if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
                    ).hasMatch(v)) {
                      return "Email invalide";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Envoyer le code",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;
    final otpBoxColor = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final otpBorderColor = isDark
        ? const Color(0xFF3A3A4A)
        : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Vérification",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Vérification",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Entrez le code à 6 chiffres reçu par email.",
              textAlign: TextAlign.center,
              style: TextStyle(color: subColor, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => _otpBox(index, otpBoxColor, otpBorderColor),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _controllers) c.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Réessayer"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? _verifyOtp
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Valider le code",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index, Color boxColor, Color borderColor) => Container(
    width: 46,
    height: 52,
    decoration: BoxDecoration(
      color: boxColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: _controllers[index],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
      onChanged: (v) {
        if (v.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
        if (v.isEmpty && index > 0) FocusScope.of(context).previousFocus();
      },
      decoration: const InputDecoration(
        counterText: "",
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
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

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: widget.email,
        code: widget.otpCode,
        password: _passController.text,
        passwordConfirmation: _confirmPassController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Mot de passe mis à jour !"),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
        (r) => false,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.error != null)
        errorMessage = e.error.toString();
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nouveau mot de passe",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Nouveau mot de passe",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choisissez un mot de passe sécurisé",
                style: TextStyle(color: subColor, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _StyledPasswordField(
                      label: "Nouveau mot de passe",
                      hint: "Minimum 8 caractères",
                      controller: _passController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Champ obligatoire";
                        if (v.length < 8) return "8 caractères minimum";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _StyledPasswordField(
                      label: "Confirmer le mot de passe",
                      hint: "Répéter le mot de passe",
                      controller: _confirmPassController,
                      validator: (v) => v != _passController.text
                          ? "Les mots de passe ne correspondent pas"
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Enregistrer",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Connexion()),
                  (route) => false,
                ),
                child: Text(
                  "Ignorer",
                  style: TextStyle(color: subColor, fontSize: 14),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _telephoneController.dispose();
    _dateNaissanceController.dispose();
    super.dispose();
  }

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
        SnackBar(
          content: const Text('Veuillez accepter les conditions'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final String sexeValue = _sexeSelectionne == 'Masculin'
          ? 'M'
          : _sexeSelectionne == 'Féminin'
          ? 'F'
          : 'other';

      await ApiService.register({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passController.text,
        'password_confirmation': _confirmPassController.text,
        'date_of_birth': _dateNaissanceController.text,
        'gender': sexeValue,
        'nationality': _nationaliteSelectionnee ?? '',
        'phone': _telephoneController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Inscription réussie ! Code OTP envoyé."),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      if (e is DioException && e.error != null)
        errorMessage = e.error.toString();
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;
    final borderColor = isDark ? const Color(0xFF3A3A4A) : Colors.grey.shade200;

    // InputDecoration adaptée au thème
    InputDecoration fieldDeco(String label, {IconData? icon}) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: subColor),
          isDense: true,
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 18,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
        );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Inscription",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Créer un compte",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rejoignez votre espace académique",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: subColor),
                ),
                const SizedBox(height: 22),

                _sectionTitle("Identité"),
                const SizedBox(height: 8),

                // Card Identité
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _lastNameController,
                        style: TextStyle(fontSize: 13, color: onSurface),
                        decoration: fieldDeco("Nom *"),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Obligatoire" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _firstNameController,
                        style: TextStyle(fontSize: 13, color: onSurface),
                        decoration: fieldDeco("Prénom *"),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Obligatoire" : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: _choisirDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _dateNaissanceController,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: onSurface,
                                  ),
                                  decoration: fieldDeco(
                                    "Date de naissance *",
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? "Obligatoire"
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: null,
                              initialValue: _sexeSelectionne,
                              decoration: fieldDeco("Sexe *"),
                              dropdownColor: cardColor,
                              hint: Text(
                                "Sexe",
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                              style: TextStyle(fontSize: 13, color: onSurface),
                              isExpanded: true,
                              isDense: true,
                              items: _sexes
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _sexeSelectionne = v),
                              validator: (v) => v == null ? "Requis" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: null,
                        initialValue: _nationaliteSelectionnee,
                        decoration: fieldDeco("Nationalité *"),
                        dropdownColor: cardColor,
                        hint: Text(
                          "Choisissez votre nationalité",
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                        style: TextStyle(fontSize: 13, color: onSurface),
                        isExpanded: true,
                        isDense: true,
                        items: _nationalites
                            .map(
                              (n) => DropdownMenuItem(value: n, child: Text(n)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _nationaliteSelectionnee = v),
                        validator: (v) => v == null
                            ? "Veuillez choisir votre nationalité"
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _sectionTitle("Contact"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: 13, color: onSurface),
                        decoration: fieldDeco(
                          "Email *",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return "Champ obligatoire";
                          if (!RegExp(
                            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
                          ).hasMatch(v)) {
                            return "Email invalide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 13, color: onSurface),
                        decoration: fieldDeco(
                          "Téléphone (facultatif)",
                          icon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _sectionTitle("Sécurité"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _PasswordField(
                        label: "Mot de passe *",
                        hint: "Minimum 8 caractères",
                        controller: _passController,
                        labelSize: 13,
                        fieldVPad: 11,
                        iconSize: 18,
                        isSmall: false,
                      ),
                      const SizedBox(height: 10),
                      _PasswordField(
                        label: "Confirmer le mot de passe *",
                        hint: "Répéter le mot de passe",
                        controller: _confirmPassController,
                        labelSize: 13,
                        fieldVPad: 11,
                        iconSize: 18,
                        isSmall: false,
                        validator: (v) =>
                            v != _passController.text ? "Non identiques" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Checkbox CGU
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setState(() => _acceptTerms = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "J'accepte les ",
                            style: TextStyle(fontSize: 11.5, color: subColor),
                            children: [
                              TextSpan(
                                text: "politiques de sécurité",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.accent,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PolicyPage(
                                        title: "Politiques de Sécurité",
                                        content:
                                            """POLITIQUE DE SÉCURITÉ DES SYSTÈMES

1. PROTECTION DES ACCÈS
L'accès à votre compte est protégé par un système de hachage cryptographique de pointe. Nous ne stockons jamais votre mot de passe en texte clair.

2. CHIFFREMENT DES DONNÉES
Toutes les données échangées entre votre appareil et nos serveurs sont cryptées via le protocole TLS 1.3.

3. INFRASTRUCTURE ET RÉSEAU
Notre infrastructure est hébergée dans des datacenters sécurisés.

4. AUDITS ET MISES À JOUR
Nous effectuons des tests d'intrusion réguliers et des scans de vulnérabilité.

5. RESPONSABILITÉ DE L'UTILISATEUR
Nous vous encourageons à utiliser un mot de passe complexe et unique.""",
                                      ),
                                    ),
                                  ),
                              ),
                              const TextSpan(text: " et la "),
                              TextSpan(
                                text: "confidentialité",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.accent,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PolicyPage(
                                        title: "Confidentialité",
                                        content:
                                            """DÉCLARATION DE CONFIDENTIALITÉ

1. COLLECTE DES INFORMATIONS
Nous collectons uniquement les données nécessaires au fonctionnement de l'application.

2. UTILISATION DES DONNÉES
Vos données sont traitées uniquement pour la gestion de votre profil.

3. PARTAGE DES DONNÉES
Nous ne vendons jamais vos données personnelles à des tiers.

4. DURÉE DE CONSERVATION
Vos données sont conservées tant que votre compte reste actif.

5. VOS DROITS
Vous disposez d'un droit d'accès, de rectification et d'effacement de vos données.""",
                                      ),
                                    ),
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "S'inscrire",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Déjà un compte ? ",
                      style: TextStyle(color: subColor, fontSize: 13.5),
                      children: [
                        TextSpan(
                          text: "Se connecter",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Widget champ mot de passe (Inscription)
// ==========================================
class _PasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final double labelSize;
  final double fieldVPad;
  final double iconSize;
  final bool isSmall;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.labelSize,
    required this.fieldVPad,
    required this.iconSize,
    required this.isSmall,
    this.validator,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;
    final onSurface = theme.colorScheme.onSurface;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      style: TextStyle(fontSize: widget.labelSize, color: onSurface),
      validator:
          widget.validator ??
          (v) {
            if (v == null || v.isEmpty) return "Champ obligatoire";
            if (v.length < 8) return "8 caractères minimum";
            return null;
          },
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(fontSize: widget.labelSize, color: subColor),
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: widget.labelSize - 1,
          color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[400],
        ),
        isDense: true,
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: subColor,
            size: widget.iconSize,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        errorStyle: const TextStyle(fontSize: 10.5, height: 0.9),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: widget.fieldVPad,
        ),
      ),
    );
  }
}

// ==========================================
// Widgets utilitaires stylistiques
// ==========================================
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : AppColors.textMain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _StyledPasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _StyledPasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
  });

  @override
  State<_StyledPasswordField> createState() => _StyledPasswordFieldState();
}

class _StyledPasswordFieldState extends State<_StyledPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          validator:
              widget.validator ??
              (v) {
                if (v == null || v.isEmpty) return "Champ obligatoire";
                if (v.length < 8) return "8 caractères minimum";
                return null;
              },
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: subColor,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
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

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    super.dispose();
  }

  Future<void> _finaliserInscription() async {
    String codeSaisi = _otpControllers.map((e) => e.text).join();
    setState(() => _isLoading = true);
    try {
      await ApiService.verifyEmail(email: widget.email, code: codeSaisi);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Compte validé avec succès !"),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;
    final otpBoxColor = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final otpBorderColor = isDark
        ? const Color(0xFF3A3A4A)
        : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Validation",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Vérifiez votre email",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Entrez le code à 6 chiffres envoyé par email",
              textAlign: TextAlign.center,
              style: TextStyle(color: subColor, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 46,
                  height: 52,
                  decoration: BoxDecoration(
                    color: otpBoxColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: otpBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && index < 5)
                        FocusScope.of(context).nextFocus();
                      if (v.isEmpty && index > 0)
                        FocusScope.of(context).previousFocus();
                    },
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _otpControllers) c.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Réessayer"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? _finaliserInscription
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Valider",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. PAGE POLITIQUE
// ==========================================
class PolicyPage extends StatelessWidget {
  final String title;
  final String content;
  const PolicyPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(height: 1.7, fontSize: 13.5, color: onSurface),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. INPUT CUSTOM (réutilisable)
// ==========================================
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subColor = isDark ? const Color(0xFF9E9EBE) : AppColors.textSub;

    return TextFormField(
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
            if (widget.isPassword && value.length < 8) {
              return "Mot de passe trop court (8 caractères minimum).";
            }
            return null;
          },
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: subColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
