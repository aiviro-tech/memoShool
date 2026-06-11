import 'package:appliformulaire/models/cours_model.dart';

class AbsenceModel {
  final int id;
  final int? coursId;
  final CoursModel? cours;
  final bool present;
  final bool justifiee;
  final String? typeJustification;
  final String? observation;
  final DateTime createdAt;
  final bool delaiDepasse;

  AbsenceModel({
    required this.id,
    this.coursId,
    this.cours,
    required this.present,
    required this.justifiee,
    this.typeJustification,
    this.observation,
    required this.createdAt,
    required this.delaiDepasse,
  });

  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    return AbsenceModel(
      id: json['id'],
      coursId: json['cours_id'],
      cours: json['cours'] != null ? CoursModel.fromJson(json['cours']) : null,
      present: json['present'] ?? false,
      justifiee: json['justifiee'] ?? false,
      typeJustification: json['type_justification'],
      observation: json['observation'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      delaiDepasse: json['delai_depasse'] ?? false,
    );
  }
}