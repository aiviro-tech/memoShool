// ================================================
// SESSION UTILISATEUR
// lib/models/session_utilisateur.dart
// ================================================

class SessionUtilisateur {
  static final SessionUtilisateur _instance = SessionUtilisateur._();
  factory SessionUtilisateur() => _instance;
  SessionUtilisateur._();

  String token = ''; // Nouvelle variable
  String role = '';
  String nom = '';
  String prenom = '';
  String email = '';
  int id = 0;

  // Infos école rejointe
  String nomEcole = '';
  int ecoleId = 0;
  String statut = ''; // 'en_attente', 'actif', 'refuse'

  void setDepuisLogin(Map<String, dynamic> data) {
    final user = data['user'] ?? data;
    token = data['token'] ?? ''; // Récupérer le token
    role = user['role'] ?? '';
    nom = user['last_name'] ?? '';
    prenom = user['first_name'] ?? '';
    email = user['email'] ?? '';
    id = user['id'] ?? 0;
  }

  void setEcole(String nom, int id) {
    nomEcole = nom;
    ecoleId = id;
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
  }

  bool get estSuperAdmin => email == 'superadmin2026@gmail.com';
  bool get estAdmin => role == 'admin';
  bool get estEnseignant => role == 'enseignant';
  bool get estEtudiant => role == 'etudiant';

  String get nomComplet => '$prenom $nom'.trim();
}
