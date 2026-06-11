import 'package:shared_preferences/shared_preferences.dart';

class SessionUtilisateur {
  static final SessionUtilisateur _instance = SessionUtilisateur._internal();
  factory SessionUtilisateur() => _instance;
  SessionUtilisateur._internal();

  int _id = 0;
  String _nom = '';
  String _prenom = '';
  String _email = '';
  String _role = '';
  String _token = '';
  int _ecoleId = 0;
  String _nomEcole = '';
  bool _isOwner = false;
  String _phone = '';        // ← AJOUTÉ
  String _photoProfil = '';  // ← AJOUTÉ

  int get id => _id;
  String get nom => _nom;
  String get prenom => _prenom;
  String get email => _email;
  String get role => _role;
  String get token => _token;
  int get ecoleId => _ecoleId;
  String get nomEcole => _nomEcole;
  bool get isOwner => _isOwner;
  String get phone => _phone;                                      // ← AJOUTÉ
  String get photoProfil => _photoProfil;                          // ← AJOUTÉ
  String get nomComplet => '$_prenom $_nom'.trim();                // ← AJOUTÉ (utile pour l'affichage)

  bool get estAdmin => _role == 'admin';
  bool get estEnseignant => _role == 'enseignant';
  bool get estEtudiant => _role == 'etudiant';
  bool get estSuperAdmin => _role == 'super_admin';

  void setDepuisLogin(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? {};
    _id = user['id'] ?? 0;
    _nom = user['last_name'] ?? '';
    _prenom = user['first_name'] ?? '';
    _email = user['email'] ?? '';
    _role = user['role'] ?? 'etudiant';
    _token = data['token'] ?? '';
    _phone = user['phone'] ?? '';             // ← AJOUTÉ
    _photoProfil = user['photo_profil'] ?? ''; // ← AJOUTÉ

    _saveToPreferences();
  }

  // ← AJOUTÉ : mettre à jour le profil depuis l'écran profil
  void mettreAJourProfil(Map<String, dynamic> user) {
    _nom = user['last_name'] ?? _nom;
    _prenom = user['first_name'] ?? _prenom;
    _phone = user['phone'] ?? _phone;
    _photoProfil = user['photo_profil'] ?? _photoProfil;
    _saveToPreferences();
  }

  // ← AJOUTÉ : mettre à jour uniquement la photo
  void mettreAJourPhoto(String urlPhoto) {
    _photoProfil = urlPhoto;
    _saveToPreferences();
  }

  void setEcole(String nom, int id, {bool owner = false}) {
    _nomEcole = nom;
    _ecoleId = id;
    _isOwner = owner;
    _saveToPreferences();
  }

  void vider() {
    _id = 0;
    _nom = '';
    _prenom = '';
    _email = '';
    _role = '';
    _token = '';
    _ecoleId = 0;
    _nomEcole = '';
    _isOwner = false;
    _phone = '';        // ← AJOUTÉ
    _photoProfil = '';  // ← AJOUTÉ
    _clearPreferences();
  }

  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', _id);
    await prefs.setString('user_nom', _nom);
    await prefs.setString('user_prenom', _prenom);
    await prefs.setString('user_email', _email);
    await prefs.setString('user_role', _role);
    await prefs.setString('user_token', _token);
    await prefs.setInt('ecole_id', _ecoleId);
    await prefs.setString('ecole_nom', _nomEcole);
    await prefs.setBool('is_owner', _isOwner);
    await prefs.setString('user_phone', _phone);           // ← AJOUTÉ
    await prefs.setString('user_photo_profil', _photoProfil); // ← AJOUTÉ
  }

  Future<void> chargerDepuisPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _id = prefs.getInt('user_id') ?? 0;
    _nom = prefs.getString('user_nom') ?? '';
    _prenom = prefs.getString('user_prenom') ?? '';
    _email = prefs.getString('user_email') ?? '';
    _role = prefs.getString('user_role') ?? '';
    _token = prefs.getString('user_token') ?? '';
    _ecoleId = prefs.getInt('ecole_id') ?? 0;
    _nomEcole = prefs.getString('ecole_nom') ?? '';
    _isOwner = prefs.getBool('is_owner') ?? false;
    _phone = prefs.getString('user_phone') ?? '';              // ← AJOUTÉ
    _photoProfil = prefs.getString('user_photo_profil') ?? ''; // ← AJOUTÉ
  }

  Future<void> _clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}