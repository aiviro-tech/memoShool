class CoursModel {
  final int id;
  final int ecoleId;
  final int classeId;
  final int enseignantId;
  final int ecueCredits;
  final String ecue;
  final String ecueCode;
  final String dateCours;
  final String heureDebut;
  final String heureFin;
  final String salle;
  final String salleCode;
  final String enseignant;
  final String classe;
  final String filiere;
  final String semestre;
  final String anneeAcademique;
  final String statut;
  final String? motifAnnulation;
  final String? notes;

  CoursModel({
    required this.id,
    required this.ecoleId,
    required this.classeId,
    required this.enseignantId,
    required this.ecueCredits,
    required this.ecue,
    required this.ecueCode,
    required this.dateCours,
    required this.heureDebut,
    required this.heureFin,
    required this.salle,
    required this.salleCode,
    required this.enseignant,
    required this.classe,
    required this.filiere,
    required this.semestre,
    required this.anneeAcademique,
    required this.statut,
    this.motifAnnulation,
    this.notes,
  });

  factory CoursModel.fromJson(Map<String, dynamic> json) {
    final ecueData = json['ecue'] as Map<String, dynamic>? ?? {};
    final enseignantData = json['enseignant'] as Map<String, dynamic>? ?? {};
    final salleData = json['salle'] as Map<String, dynamic>? ?? {};
    final classeData = json['classe'] as Map<String, dynamic>? ?? {};
    final filiereData = classeData['filiere'] as Map<String, dynamic>? ?? {};
    final semestreData = json['semestre'] as Map<String, dynamic>? ?? {};

    return CoursModel(
      id: json['id'] as int? ?? 0,
      ecoleId: json['ecole_id'] as int? ?? 0,
      classeId: json['classe_id'] as int? ?? classeData['id'] as int? ?? 0,
      enseignantId: json['enseignant_id'] as int? ?? 0,
      ecueCredits: ecueData['credits'] as int? ?? 0,
      ecue: ecueData['nom'] ?? '',
      ecueCode: ecueData['code'] ?? '',
      dateCours: json['date_cours'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      heureFin: json['heure_fin'] ?? '',
      salle: salleData['nom'] ?? '',
      salleCode: salleData['code'] ?? '',
      enseignant: enseignantData['full_name'] ?? '',
      classe: classeData['nom'] ?? '',
      filiere: filiereData['nom'] ?? '',
      semestre: semestreData['numero']?.toString() ?? '',
      anneeAcademique: semestreData['annee_academique'] ?? '',
      statut: json['statut'] ?? 'planifie',
      motifAnnulation: json['motif_annulation'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String get dateFormatee {
    if (dateCours.length >= 10) return dateCours.substring(0, 10);
    return dateCours;
  }

  String get horaireFormate {
    return '$heureDebut - $heureFin';
  }
}