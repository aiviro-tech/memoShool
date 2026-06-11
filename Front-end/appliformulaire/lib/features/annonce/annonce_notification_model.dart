class AnnonceModel {
  final int id;
  final int ecoleId;
  final String titre;
  final String contenu;
  final String cible; // 'tous', 'etudiants', 'enseignants'
  final String? niveauCible; // 'L1', 'L2', 'L3', 'M1', 'M2'
  final int? classeCibleId;
  final String? classeCibleNom;
  final bool publie;
  final String? datePublication;
  final String? publiePar; // nom de l'auteur

  AnnonceModel({
    required this.id,
    required this.ecoleId,
    required this.titre,
    required this.contenu,
    required this.cible,
    this.niveauCible,
    this.classeCibleId,
    this.classeCibleNom,
    required this.publie,
    this.datePublication,
    this.publiePar,
  });

  factory AnnonceModel.fromJson(Map<String, dynamic> json) {
    final publiePar = json['publie_par_user'] as Map<String, dynamic>? ??
        json['publie_par'] as Map<String, dynamic>?;
    final classeCible = json['classe_cible_obj'] as Map<String, dynamic>? ??
        json['classe_cible_data'] as Map<String, dynamic>?;

    String? nomAuteur;
    if (publiePar != null) {
      nomAuteur = publiePar['full_name'] ??
          '${publiePar['first_name'] ?? ''} ${publiePar['last_name'] ?? ''}'.trim();
    }

    return AnnonceModel(
      id: json['id'] as int? ?? 0,
      ecoleId: json['ecole_id'] as int? ?? 0,
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      cible: json['cible'] ?? 'tous',
      niveauCible: json['niveau_cible'] as String?,
      classeCibleId: json['classe_cible'] as int?,
      classeCibleNom: classeCible?['nom'] as String?,
      publie: json['publie'] == true || json['publie'] == 1,
      datePublication: json['date_publication'] as String?,
      publiePar: nomAuteur,
    );
  }

  // Label lisible pour la cible
  String get cibleLabel {
    switch (cible) {
      case 'etudiants':
        if (classeCibleNom != null) return 'Étudiants — $classeCibleNom';
        if (niveauCible != null) return 'Étudiants $niveauCible';
        return 'Tous les étudiants';
      case 'enseignants':
        return 'Enseignants';
      default:
        return 'Tout le monde';
    }
  }

  // Date formatée
  String get dateFormatee {
    if (datePublication == null) return '';
    final s = datePublication!;
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class NotificationModel {
  final int id;
  final int? ecoleId;
  final String titre;
  final String contenu;
  final String type; // 'annonce','note','support','emploi_du_temps','paiement','absence','general'
  final Map<String, dynamic>? data;
  final bool lu;
  final String? luAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.ecoleId,
    required this.titre,
    required this.contenu,
    required this.type,
    this.data,
    required this.lu,
    this.luAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      ecoleId: json['ecole_id'] as int?,
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'] as Map<String, dynamic>?,
      lu: json['lu'] == true || json['lu'] == 1,
      luAt: json['lu_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  String get dateFormatee {
    if (createdAt.length >= 10) return createdAt.substring(0, 10);
    return createdAt;
  }

  String get heureFormatee {
    if (createdAt.length >= 16) return createdAt.substring(11, 16);
    return '';
  }
}