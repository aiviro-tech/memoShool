import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static final Dio dio =
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      )
        ..interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => debugPrint(obj.toString()),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onError: (DioException e, handler) {
              if (e.response?.data != null && e.response?.data is Map) {
                final data = e.response?.data;
                String message = data['message'] ?? 'Erreur inconnue';

                if (data['errors'] != null && data['errors'] is Map) {
                  final errors = data['errors'] as Map;
                  if (errors.isNotEmpty) {
                    final firstKey = errors.keys.first;
                    message = errors[firstKey][0].toString();
                  }
                }

                throw Exception(message);
              }
              return handler.next(e);
            },
          ),
        );

  // ================= TOKEN =================

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ================= AUTH =================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;

    if (data['token'] != null) {
      setToken(data['token']);
    }

    SessionUtilisateur().setDepuisLogin(data);

    return data;
  }

  static Future<void> logout() async {
    await dio.post('/api/logout');
    dio.options.headers.remove('Authorization');
    SessionUtilisateur().vider();
  }

  // ================= COURS =================

  static Future<Map<String, dynamic>> getEmploiDuTemps(
    int ecoleId, {
    String? semaine,
  }) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/cours/emploi-du-temps',
      queryParameters: semaine != null ? {'semaine': semaine} : null,
    );

    final data = response.data;

    debugPrint("EMPLOI DU TEMPS: $data");

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'emploi_du_temps': data};
  }

  // ================= AUTRES =================

  static Future<Map<String, dynamic>> getDashboardAccueil() async {
    final response = await dio.get('/api/dashboard');
    return response.data;
  }

  // ================= AUTH =================

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final response = await dio.post(
      '/api/register',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await dio.post(
      '/api/verify-email',
      data: {'email': email, 'code': code},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await dio.post(
      '/api/forgot-password',
      data: {'email': email},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await dio.post(
      '/api/reset-password',
      data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data;
  }

  // ================= ÉCOLES =================

  static Future<Map<String, dynamic>> creerEcole(
      Map<String, dynamic> data) async {
    final response = await dio.post(
      '/api/ecoles',
      data: data,
    );
    return response.data;
  }

  static Future<List<dynamic>> ecolesEnAttente() async {
    final response = await dio.get('/api/ecoles/en-attente');
    return response.data;
  }

  static Future<List<dynamic>> getEcolesTraitees() async {
    final response = await dio.get('/api/ecoles/traitees');
    return response.data;
  }

  static Future<Map<String, dynamic>> activerEcole(int ecoleId) async {
    final response = await dio.put('/api/ecoles/$ecoleId/activer');
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerEcole(int ecoleId) async {
    final response = await dio.delete('/api/ecoles/$ecoleId');
    return response.data;
  }

  static Future<Map<String, dynamic>> refuserEcole(
      int ecoleId, String motif) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/refuser',
      data: {'motif': motif},
    );
    return response.data;
  }

  // ================= CODES D'INVITATION =================

  static Future<List<dynamic>> mesCodes() async {
    final response = await dio.get('/api/mes-codes');
    return response.data;
  }

  static Future<Map<String, dynamic>> regenererCode(int codeId) async {
    final response = await dio.put('/api/codes/$codeId/regenerer');
    return response.data;
  }

  static Future<Map<String, dynamic>> verifierCode(String code) async {
    final response = await dio.post(
      '/api/codes/verifier',
      data: {'code': code},
    );
    return response.data;
  }

  // ================= MEMBRES =================

  static Future<Map<String, dynamic>> rejoindreEcole(
      Map<String, dynamic> data) async {
    final response = await dio.post(
      '/api/rejoindre',
      data: data,
    );
    return response.data;
  }

  static Future<List<dynamic>> demandesEnAttente() async {
    final response = await dio.get('/api/demandes-en-attente');
    return response.data;
  }

  static Future<Map<String, dynamic>> accepterDemande(int demandeId) async {
    final response = await dio.put('/api/demandes/$demandeId/accepter');
    return response.data;
  }

  static Future<Map<String, dynamic>> rejeterDemande(int demandeId, String motif) async {
    final response = await dio.put(
      '/api/demandes/$demandeId/rejeter',
      data: {'motif': motif},
    );
    return response.data;
  }

  // ================= COURS =================

  static Future<Map<String, dynamic>> getCours(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/cours');
    return response.data;
  }

  static Future<Map<String, dynamic>> getDetailCours(int ecoleId, int coursId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/cours/$coursId');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerCours(int ecoleId, Map<String, dynamic> data) async {
    final response = await dio.post('/api/ecoles/$ecoleId/cours', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> modifierCours(int ecoleId, int coursId, Map<String, dynamic> data) async {
    final response = await dio.put('/api/ecoles/$ecoleId/cours/$coursId', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerCours(int ecoleId, int coursId) async {
    final response = await dio.delete('/api/ecoles/$ecoleId/cours/$coursId');
    return response.data;
  }

  static Future<Map<String, dynamic>> changerStatutCours(
    int ecoleId,
    int coursId,
    String statut, {
    String? motifAnnulation,
  }) async {
    final data = <String, dynamic>{'statut': statut};
    if (motifAnnulation != null && motifAnnulation.isNotEmpty) {
      data['motif_annulation'] = motifAnnulation;
    }

    final response = await dio.patch(
      '/api/ecoles/$ecoleId/cours/$coursId/statut',
      data: data,
    );
    return response.data;
  }

  // ================= FILIÈRES =================

  static Future<Map<String, dynamic>> getFilieres(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/filieres');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerFiliere(int ecoleId, Map<String, dynamic> data) async {
    final response = await dio.post('/api/ecoles/$ecoleId/filieres', data: data);
    return response.data;
  }

  // ================= MATIÈRES =================

  static Future<Map<String, dynamic>> getMatieres(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/matieres');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerMatiere(int ecoleId, Map<String, dynamic> data) async {
    final response = await dio.post('/api/ecoles/$ecoleId/matieres', data: data);
    return response.data;
  }

  // ================= CLASSES =================

  static Future<Map<String, dynamic>> getClasses(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/classes');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerClasse(int ecoleId, Map<String, dynamic> data) async {
    final response = await dio.post('/api/ecoles/$ecoleId/classes', data: data);
    return response.data;
  }

  // ================= ENSEIGNANTS =================

  static Future<List<dynamic>> getEnseignants(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/membres');
    final data = response.data;
    // le backend retourne { success: true, data: [...] }
    // donc on doit acceder a data['data'] et pas directement data
    List<dynamic> membres = [];
    if (data is Map && data['data'] != null) {
      membres = data['data'] as List<dynamic>;
    } else if (data is List) {
      membres = data;
    }
    return membres.where((m) => m['role'] == 'enseignant').toList();
  }

  // ================= SALLES =================

  static Future<Map<String, dynamic>> getSalles(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/salles');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerSalle(int ecoleId, Map<String, dynamic> data) async {
    final response = await dio.post('/api/ecoles/$ecoleId/salles', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getSallesDisponibles(int ecoleId, {
    String? date,
    String? heureDebut,
    String? heureFin,
  }) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;
    if (heureDebut != null) queryParams['heure_debut'] = heureDebut;
    if (heureFin != null) queryParams['heure_fin'] = heureFin;

    final response = await dio.get(
      '/api/ecoles/$ecoleId/salles/disponibles',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ================= SUPPORTS DE COURS =================

  static Future<Map<String, dynamic>> getSupports(int ecoleId, {int? coursId}) async {
    final params = <String, dynamic>{};
    if (coursId != null) params['cours_id'] = coursId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/supports',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  // Upload support de cours (multipart)
  static Future<Map<String, dynamic>> deposerSupport(
    int ecoleId,
    Map<String, dynamic> data,
    String filePath,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      ...data,
      'fichier': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await dio.post(
      '/api/ecoles/$ecoleId/supports',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> validerSupport(int ecoleId, int supportId) async {
    final response = await dio.put('/api/ecoles/$ecoleId/supports/$supportId/valider');
    return response.data;
  }

  static Future<Map<String, dynamic>> rejeterSupport(int ecoleId, int supportId, String motif) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/supports/$supportId/rejeter',
      data: {'motif_rejet': motif},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerSupport(int ecoleId, int supportId) async {
    final response = await dio.delete('/api/ecoles/$ecoleId/supports/$supportId');
    return response.data;
  }

  /// Retourne l'URL de téléchargement d'un support
  static String getDownloadUrl(int ecoleId, int supportId) {
    return '$baseUrl/api/ecoles/$ecoleId/supports/$supportId/download';
  }

  /// Télécharge un support de cours
  static Future<void> telechargerSupport(int ecoleId, int supportId, String savePath) async {
    await dio.download(
      '/api/ecoles/$ecoleId/supports/$supportId/download',
      savePath,
    );
  }
}