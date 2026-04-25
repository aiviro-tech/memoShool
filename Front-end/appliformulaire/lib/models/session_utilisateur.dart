
class SessionUtilisateur {
  static final SessionUtilisateur _instance = SessionUtilisateur._();
  factory SessionUtilisateur() => _instance;
  SessionUtilisateur._();

  String token = '';
  String role = '';
  String nom = '';
  String prenom = '';
  String email = '';
  int id = 0;

  // Infos école rejointe
  String nomEcole = '';
  int ecoleId = 0;
  String statut = ''; // 'en_attente', 'actif', 'refuse'

  /// true = créateur de l'école → AdminDashboardPage (codes + demandes)
  /// false = admin secondaire (comptable, etc.) → DashboardPrincipal
  bool isOwner = false;

  void setDepuisLogin(Map<String, dynamic> data) {
    final user = data['user'] ?? data;
    token = data['token'] ?? '';
    role = user['role'] ?? '';
    nom = user['last_name'] ?? '';
    prenom = user['first_name'] ?? '';
    email = user['email'] ?? '';
    id = user['id'] ?? 0;
  }

  void setEcole(String nom, int id, {bool owner = false}) {
    nomEcole = nom;
    ecoleId = id;
    isOwner = owner;
  }

  void vider() {
    token = '';
    role = '';
    nom = '';
    prenom = '';
    email = '';
    id = 0;
    nomEcole = '';
    ecoleId = 0;
    statut = '';
    isOwner = false;
  }

  bool get estSuperAdmin => email == 'superadmin2026@gmail.com';
  bool get estAdmin => role == 'admin';
  bool get estEnseignant => role == 'enseignant';
  bool get estEtudiant => role == 'etudiant';

  /// Admin propriétaire = créateur de l'école
  bool get estAdminProprietaire => estAdmin && isOwner;

  String get nomComplet => '$prenom $nom'.trim();
}

