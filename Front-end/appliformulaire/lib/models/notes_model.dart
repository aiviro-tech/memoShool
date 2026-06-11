// ─── Helper global ────────────────────────────────────────────────────────────
// Le backend Laravel retourne parfois les décimaux en String ("0.00", "16.50")
// et parfois en num (0, 16.5). Cette fonction gère les deux cas sans crash.
double _toDouble(dynamic value, [double defaut = 0.0]) {
  if (value == null) return defaut;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaut;
  return defaut;
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// ─── EcueInfo ─────────────────────────────────────────────────────────────────
class EcueInfo {
  final int id;
  final String nom;
  final String code;

  EcueInfo({required this.id, required this.nom, required this.code});

  factory EcueInfo.fromJson(Map<String, dynamic> json) {
    return EcueInfo(
      id: json['id'] as int? ?? 0,
      nom: json['nom'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

// ─── DevoirModel ──────────────────────────────────────────────────────────────
class DevoirModel {
  final int id;
  final String titre;
  final String type;
  final int session;
  final double bareme;
  final String dateEvaluation;
  final EcueInfo? ecue;
  final int classeId;
  final int ecueId;

  DevoirModel({
    required this.id,
    required this.titre,
    required this.type,
    required this.session,
    required this.bareme,
    required this.dateEvaluation,
    this.ecue,
    required this.classeId,
    required this.ecueId,
  });

  factory DevoirModel.fromJson(Map<String, dynamic> json) {
    return DevoirModel(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] ?? '',
      type: json['type'] ?? '',
      session: json['session'] as int? ?? 1,
      // CORRECTION : _toDouble() gère String/int/double/null
      bareme: _toDouble(json['bareme'], 20.0),
      dateEvaluation: json['date_evaluation'] ?? '',
      ecue: json['ecue'] != null ? EcueInfo.fromJson(json['ecue']) : null,
      classeId: json['classe_id'] as int? ?? 0,
      ecueId: json['ecue_id'] as int? ?? 0,
    );
  }
}

// ─── NoteModel ────────────────────────────────────────────────────────────────
class NoteModel {
  final int id;
  final double valeur;
  final bool absent;
  final String? observation;
  final DevoirModel? devoir;

  NoteModel({
    required this.id,
    required this.valeur,
    required this.absent,
    this.observation,
    this.devoir,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as int? ?? 0,
      // CORRECTION : était (json['valeur'] ?? 0).toDouble()
      // → crash quand json['valeur'] = "0.00" (String)
      valeur: _toDouble(json['valeur'], 0.0),
      absent: json['absent'] == true || json['absent'] == 1,
      observation: json['observation'] as String?,
      devoir: json['devoir'] != null
          ? DevoirModel.fromJson(json['devoir'])
          : null,
    );
  }

  // Note ramenée sur 20 quel que soit le barème
  double get noteSur20 {
    if (devoir == null || devoir!.bareme == 0) return valeur;
    return (valeur / devoir!.bareme) * 20;
  }
}

// ─── MoyenneEcueModel ─────────────────────────────────────────────────────────
class MoyenneEcueModel {
  final int ecueId;
  final String ecueNom;
  final String ecueCode;
  final double? moyenneCC;
  final double? moyenneExamen;
  final double? moyenneFinale;
  final bool valide;
  final bool excluSession1;
  final int credits;

  MoyenneEcueModel({
    required this.ecueId,
    required this.ecueNom,
    required this.ecueCode,
    this.moyenneCC,
    this.moyenneExamen,
    this.moyenneFinale,
    required this.valide,
    required this.excluSession1,
    required this.credits,
  });

  factory MoyenneEcueModel.fromJson(Map<String, dynamic> json) {
    return MoyenneEcueModel(
      ecueId: json['ecue_id'] as int? ?? 0,
      ecueNom: json['ecue_nom'] ?? json['ecue']?['nom'] ?? '',
      ecueCode: json['ecue_code'] ?? json['ecue']?['code'] ?? '',
      // CORRECTION : _toDoubleNullable() gère String/int/double/null
      moyenneCC:     _toDoubleNullable(json['moyenne_cc']),
      moyenneExamen: _toDoubleNullable(json['moyenne_examen']),
      moyenneFinale: _toDoubleNullable(json['moyenne_finale']),
      valide:        json['valide'] == true || json['valide'] == 1,
      excluSession1: json['exclu_session1'] == true || json['exclu_session1'] == 1,
      credits:       json['credits'] as int? ?? 0,
    );
  }
}

// ─── MoyenneSemestreModel ─────────────────────────────────────────────────────
class MoyenneSemestreModel {
  final double? moyenneGenerale;
  final int creditsValides;
  final int creditsTotal;
  final List<MoyenneEcueModel> ecues;
  final bool admis;

  MoyenneSemestreModel({
    this.moyenneGenerale,
    required this.creditsValides,
    required this.creditsTotal,
    required this.ecues,
    required this.admis,
  });

  factory MoyenneSemestreModel.fromJson(Map<String, dynamic> json) {
    final ecuesList = (json['ecues'] as List? ?? [])
        .map((e) => MoyenneEcueModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MoyenneSemestreModel(
      // CORRECTION : était (json['moyenne_generale']).toDouble() → crash si String
      moyenneGenerale: _toDoubleNullable(json['moyenne_generale']),
      creditsValides: json['credits_valides'] as int? ?? 0,
      creditsTotal:   json['credits_total']   as int? ?? 0,
      ecues: ecuesList,
      admis: json['admis'] == true || json['admis'] == 1,
    );
  }
}