import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/absence_model.dart';

class AbsenceService {
  Future<List<AbsenceModel>> getMesAbsences(int ecoleId, {bool? justifiee}) async {
    final data = await ApiService.getMesAbsences(ecoleId, justifiee: justifiee);
    final list = data['data'] as List;
    return list.map((e) => AbsenceModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> justifierAbsence(
    int ecoleId,
    int absenceId, {
    required String typeJustification,
    String? observation,
  }) async {
    return await ApiService.justifierAbsence(
      ecoleId,
      absenceId,
      typeJustification: typeJustification,
      observation: observation,
    );
  }

  Future<Map<String, dynamic>> getStatutExclusion(
    int ecoleId, {
    required int etudiantId,
    required int ecueId,
    required int semestreId,
  }) async {
    return await ApiService.getStatutExclusion(
      ecoleId,
      etudiantId: etudiantId,
      ecueId: ecueId,
      semestreId: semestreId,
    );
  }
}