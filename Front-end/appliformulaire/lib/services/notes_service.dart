import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/notes_model.dart';

class NoteService {
  // Lister les devoirs
  Future<List<DevoirModel>> getDevoirs(int ecoleId, {
    int? ecueId,
    int? classeId,
    int? session,
    String? type,
  }) async {
    final data = await ApiService.getDevoirs(
      ecoleId,
      ecueId: ecueId,
      classeId: classeId,
      session: session,
      type: type,
    );
    final list = data['data'] as List;
    return list.map((e) => DevoirModel.fromJson(e)).toList();
  }

  // Notes de l'étudiant connecté
  Future<List<NoteModel>> getNotesEtudiant(int ecoleId, {
    int? ecueId,
    int? session,
    int? etudiantId,
  }) async {
    final data = await ApiService.getNotesEtudiant(
      ecoleId,
      ecueId: ecueId,
      session: session,
      etudiantId: etudiantId,
    );
    final list = data['data'] as List;
    return list.map((e) => NoteModel.fromJson(e)).toList();
  }

  // Moyennes d'un semestre
  Future<MoyenneSemestreModel> getMoyennesSemestre(
    int ecoleId, {
    required int etudiantId,
    required int semestreId,
    required int classeId,
    int session = 1,
  }) async {
    final data = await ApiService.getMoyennesSemestre(
      ecoleId,
      etudiantId: etudiantId,
      semestreId: semestreId,
      classeId: classeId,
      session: session,
    );
    return MoyenneSemestreModel.fromJson(data['data']);
  }

  // Générer le relevé
  Future<Map<String, dynamic>> genererReleve(
    int ecoleId, {
    required int etudiantId,
    required int semestreId,
    required int classeId,
    required int session,
  }) async {
    return await ApiService.genererReleve(
      ecoleId,
      etudiantId: etudiantId,
      semestreId: semestreId,
      classeId: classeId,
      session: session,
    );
  }

  // Lister les relevés
  Future<List<dynamic>> getRelevesList(int ecoleId, {int? etudiantId}) async {
    final data = await ApiService.getRelevesList(ecoleId, etudiantId: etudiantId);
    return data['data'] as List;
  }

  // URL pour télécharger le relevé PDF
  String getTelechargementUrl(int ecoleId, int releveId) {
    return ApiService.getTelechargementReleveUrl(ecoleId, releveId);
  }

  // ================= ENSEIGNANT =================

  Future<List<DevoirModel>> getDevoirsEnseignant(int ecoleId, {
    int? ecueId,
    int? classeId,
    int? session,
  }) async {
    final data = await ApiService.getDevoirs(
      ecoleId,
      ecueId: ecueId,
      classeId: classeId,
      session: session,
    );
    final list = data['data'] as List;
    return list.map((e) => DevoirModel.fromJson(e)).toList();
  }

  Future<void> saisirNotes(
    int ecoleId,
    int devoirId,
    List<Map<String, dynamic>> notes, {
    int? semestreId,
  }) async {
    await ApiService.saisirNotes(ecoleId, devoirId, notes, semestreId: semestreId);
  }

  Future<Map<String, dynamic>> creerDevoir(int ecoleId, Map<String, dynamic> data) async {
    return await ApiService.creerDevoir(ecoleId, data);
  }

  // ================= ADMIN =================

  Future<Map<String, dynamic>> autoriserSaisieNotes(int ecoleId, Map<String, dynamic> data) async {
    return await ApiService.autoriserSaisieNotes(ecoleId, data);
  }

  Future<Map<String, dynamic>> revoquerAutorisation(int ecoleId, int autorisationId) async {
    return await ApiService.revoquerAutorisation(ecoleId, autorisationId);
  }

  Future<List<dynamic>> getAutorisations(int ecoleId) async {
    final data = await ApiService.getAutorisations(ecoleId);
    return data['data'] as List;
  }
}