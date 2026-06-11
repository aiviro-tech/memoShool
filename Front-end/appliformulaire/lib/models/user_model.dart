// lib/models/user_model.dart
// ACTION : Remplace complètement ton fichier user_model.dart existant

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final String? emailVerifiedAt;
  final String? photoProfil; // ← AJOUTÉ
  final String? phone;       // ← AJOUTÉ

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    this.emailVerifiedAt,
    this.photoProfil,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'etudiant',
      emailVerifiedAt: json['email_verified_at'],
      photoProfil: json['photo_profil'],
      phone: json['phone'],
    );
  }

  bool get isEtudiant => role == 'etudiant';
  bool get isEnseignant => role == 'enseignant';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
}