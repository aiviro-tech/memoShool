class CoursModel {
  final int id;
  final String matiere;
  final String matiereCode;
  final int matiereCredits;
  final String enseignant;
  final int enseignantId;
  final String salle;
  final String salleCode;
  final String classe;
  final String filiere;
  final String dateCours;
  final String heureDebut;
  final String heureFin;
  final String statut;
  final String semestre;
  final String anneeAcademique;
  final String? notes;
  final String? motifAnnulation;

  CoursModel({
    required this.id,
    required this.matiere,
    required this.matiereCode,
    required this.matiereCredits,
    required this.enseignant,
    required this.enseignantId,
    required this.salle,
    required this.salleCode,
    required this.classe,
    required this.filiere,
    required this.dateCours,
    required this.heureDebut,
    required this.heureFin,
    required this.statut,
    required this.semestre,
    required this.anneeAcademique,
    this.notes,
    this.motifAnnulation,
  });

  factory CoursModel.fromJson(Map<String, dynamic> json) {
    final mat  = (json['matiere']    ?? {}) as Map<String, dynamic>;
    final ens  = (json['enseignant'] ?? {}) as Map<String, dynamic>;
    final sal  = (json['salle']      ?? {}) as Map<String, dynamic>;
    final cls  = (json['classe']     ?? {}) as Map<String, dynamic>;
    final fil  = (cls['filiere']     ?? {}) as Map<String, dynamic>;

    return CoursModel(
      id:              json['id'] ?? 0,
      matiere:         mat['nom'] ?? '',
      matiereCode:     mat['code'] ?? '',
      matiereCredits:  mat['credits'] ?? 0,
      enseignant:      ens['full_name'] ?? '',
      enseignantId:    ens['id'] ?? 0,
      salle:           sal['nom'] ?? '',
      salleCode:       sal['code'] ?? '',
      classe:          cls['nom'] ?? '',
      filiere:         fil['nom'] ?? '',
      dateCours:       json['date_cours'] ?? '',
      heureDebut:      json['heure_debut'] ?? '',
      heureFin:        json['heure_fin'] ?? '',
      statut:          json['statut'] ?? 'planifie',
      semestre:        json['semestre'] ?? '',
      anneeAcademique: json['annee_academique'] ?? '',
      notes:           json['notes'],
      motifAnnulation: json['motif_annulation'],
    );
  }

  String get jourSemaine {
    if (dateCours.isEmpty) return '';
    try {
      final d = DateTime.parse(dateCours);
      const j = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
      return j[d.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String get dateFormatee {
    if (dateCours.isEmpty) return '';
    try {
      final d = DateTime.parse(dateCours);
      const m = [
        '', 'janvier','février','mars','avril','mai','juin',
        'juillet','août','septembre','octobre','novembre','décembre'
      ];
      return '$jourSemaine ${d.day} ${m[d.month]} ${d.year}';
    } catch (_) {
      return dateCours;
    }
  }

  String get horaireFormate => '$heureDebut - $heureFin';

  bool get estActif => statut != 'annule';
}