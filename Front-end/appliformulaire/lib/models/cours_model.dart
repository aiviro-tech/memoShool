class CoursModel {
  final int id;
  final String titre;
  final String description;
  final String enseignant;
  final String semestre;
  final int credits;
  final String salle;
  final String horaire;
  final String jour;

  CoursModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.enseignant,
    required this.semestre,
    required this.credits,
    required this.salle,
    required this.horaire,
    required this.jour,
  });

  // Convertir JSON de l'API → objet Dart
  factory CoursModel.fromJson(Map<String, dynamic> json) {
    return CoursModel(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      enseignant: json['enseignant']?['name'] ?? '',
      semestre: json['semestre'] ?? '',
      credits: json['credits'] ?? 0,
      salle: json['salle'] ?? '',
      horaire: json['horaire'] ?? '',
      jour: json['jour'] ?? '',
    );
  }

  // Convertir objet Dart → Map pour envoyer à l'API
  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'description': description,
      'semestre': semestre,
      'credits': credits,
      'salle': salle,
      'horaire': horaire,
      'jour': jour,
    };
  }
}

class SupportModel {
  final int id;
  final String titre;
  final String fichierPath;
  final String statut;

  SupportModel({
    required this.id,
    required this.titre,
    required this.fichierPath,
    required this.statut,
  });

  factory SupportModel.fromJson(Map<String, dynamic> json) {
    return SupportModel(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      fichierPath: json['fichier_path'] ?? '',
      statut: json['statut'] ?? 'en_attente',
    );
  }
}
