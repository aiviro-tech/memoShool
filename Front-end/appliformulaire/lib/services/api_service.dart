import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'dart:io';
import 'dart:typed_data';

class ApiService {
  static const String _mobileUrl = 'http://192.168.1.227:8000';
  static const String _webUrl = 'http://localhost:8000';
  static String get baseUrl => kIsWeb ? _webUrl : _mobileUrl;

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
                final errors = data['errors'];
                if (errors is Map && errors.isNotEmpty) {
                  final firstKey = errors.keys.first;
                  message = errors[firstKey][0].toString();
                }
                throw Exception(message);
              }
              return handler.next(e);
            },
          ),
        );

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static String? getToken() {
    final auth = dio.options.headers['Authorization']?.toString();
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    return auth.replaceFirst('Bearer ', '');
  }

  static String getDocumentUrl(int ecoleId, String documentType) {
    final token = getToken();
    final url = '$baseUrl/api/ecoles/$ecoleId/document/$documentType';
    if (token != null && token.isNotEmpty) {
      return '$url?token=$token';
    }
    return url;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/api/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data;
    if (data['token'] != null) setToken(data['token']);
    SessionUtilisateur().setDepuisLogin(data);
    return data;
  }

  static Future<void> logout() async {
    await dio.post('/api/logout');
    dio.options.headers.remove('Authorization');
    SessionUtilisateur().vider();
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/register', data: data);
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD & ÉCOLES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getDashboardAccueil() async {
    final response = await dio.get('/api/dashboard');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerEcole(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> creerEcoleAvecDocuments(
    Map<String, dynamic> data,
    Map<String, File?> documents,
  ) async {
    final formData = FormData();
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });
    documents.forEach((key, file) {
      if (file != null) {
        formData.files.add(
          MapEntry(
            key,
            MultipartFile.fromFileSync(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }
    });
    final response = await dio.post('/api/ecoles', data: formData);
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
    int ecoleId,
    String motif,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/refuser',
      data: {'motif': motif},
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CODES D'INVITATION
  // ═══════════════════════════════════════════════════════════════════════════

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

  static Future<Map<String, dynamic>> rejoindreEcole(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/rejoindre', data: data);
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMANDES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> demandesEnAttente() async {
    final response = await dio.get('/api/demandes-en-attente');
    return response.data;
  }

  static Future<Map<String, dynamic>> accepterDemande(int demandeId) async {
    final response = await dio.put('/api/demandes/$demandeId/accepter');
    return response.data;
  }

  static Future<Map<String, dynamic>> rejeterDemande(
    int demandeId,
    String motif,
  ) async {
    final response = await dio.put(
      '/api/demandes/$demandeId/rejeter',
      data: {'motif': motif},
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getInscriptions(
    int ecoleId, {
    String? statut,
    int? classeId,
  }) async {
    final params = <String, dynamic>{};
    if (statut != null) params['statut'] = statut;
    if (classeId != null) params['classe_id'] = classeId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/inscriptions',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> creerInscription(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/inscriptions',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> validerInscription(
    int ecoleId,
    int inscriptionId,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/inscriptions/$inscriptionId/valider',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> rejeterInscription(
    int ecoleId,
    int inscriptionId,
    String motif,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/inscriptions/$inscriptionId/rejeter',
      data: {'motif_rejet': motif},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerInscription(
    int ecoleId,
    int inscriptionId,
  ) async {
    final response = await dio.delete(
      '/api/ecoles/$ecoleId/inscriptions/$inscriptionId',
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COURS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEmploiDuTemps(
    int ecoleId, {
    String? semaine,
  }) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/cours/emploi-du-temps',
      queryParameters: semaine != null ? {'semaine': semaine} : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getCours(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/cours');
    return response.data;
  }

  static Future<Map<String, dynamic>> getDetailCours(
    int ecoleId,
    int coursId,
  ) async {
    final response = await dio.get('/api/ecoles/$ecoleId/cours/$coursId');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerCours(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/cours', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> modifierCours(
    int ecoleId,
    int coursId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/cours/$coursId',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerCours(
    int ecoleId,
    int coursId,
  ) async {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // FILIÈRES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getFilieres(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/filieres');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerFiliere(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/filieres',
      data: data,
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMESTRES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSemestres(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/semestres');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerSemestre(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/semestres',
      data: data,
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UEs
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getUes(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/ues');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerUe(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/ues', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerUe(int ecoleId, int ueId) async {
    final response = await dio.delete('/api/ecoles/$ecoleId/ues/$ueId');
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ECUEs
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEcues(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/ecues');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerEcue(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/ecues', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerEcue(
    int ecoleId,
    int ecueId,
  ) async {
    final response = await dio.delete('/api/ecoles/$ecoleId/ecues/$ecueId');
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLASSES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getClasses(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/classes');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerClasse(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/classes', data: data);
    return response.data;
  }

  static Future<List<dynamic>> getEtudiantsByClasse(
    int ecoleId,
    int classeId,
  ) async {
    final classeRes = await ApiService.getClasses(ecoleId);
    final classes = classeRes['data'] as List? ?? [];
    final classe = classes.firstWhere(
      (c) => c['id'] == classeId,
      orElse: () => null,
    );
    if (classe == null) return [];

    final inscriptionsRes = await ApiService.getInscriptions(
      ecoleId,
      statut: 'validee',
    );
    final inscriptions = inscriptionsRes['data'] as List? ?? [];
    final inscriptionsClasse = inscriptions
        .where((ins) => ins['classe_id'] == classeId)
        .toList();

    final List<dynamic> etudiants = [];
    for (var ins in inscriptionsClasse) {
      final etudiant = ins['etudiant'] as Map<String, dynamic>? ?? {};
      if (etudiant['id'] != null) etudiants.add(etudiant);
    }
    return etudiants;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMBRES & ENSEIGNANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMembres(int ecoleId, {String? role}) async {
    final response = await dio.get('/api/ecoles/$ecoleId/membres');
    final data = response.data;
    List<dynamic> membres = [];
    if (data is Map && data['data'] != null) {
      membres = data['data'] as List<dynamic>;
    } else if (data is List) {
      membres = data;
    }
    if (role != null) {
      return membres.where((m) => m['role'] == role).toList();
    }
    return membres;
  }

  static Future<List<dynamic>> getEnseignants(int ecoleId) async {
    return getMembres(ecoleId, role: 'enseignant');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SALLES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSalles(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/salles');
    return response.data;
  }

  static Future<Map<String, dynamic>> creerSalle(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/salles', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getSallesDisponibles(
    int ecoleId, {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPORTS DE COURS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSupports(
    int ecoleId, {
    int? coursId,
  }) async {
    final params = <String, dynamic>{};
    if (coursId != null) params['cours_id'] = coursId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/supports',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> deposerSupport(
    int ecoleId,
    Map<String, dynamic> data,
    String fileName, {
    String? fichierPath,
    Uint8List? fichierBytes,
  }) async {
    MultipartFile multipartFile;
    if (fichierPath != null) {
      multipartFile = await MultipartFile.fromFile(
        fichierPath,
        filename: fileName,
      );
    } else if (fichierBytes != null) {
      multipartFile = MultipartFile.fromBytes(fichierBytes, filename: fileName);
    } else {
      throw Exception('Aucun fichier fourni (path et bytes sont null)');
    }
    final formData = FormData.fromMap({...data, 'fichier': multipartFile});
    final response = await dio.post(
      '/api/ecoles/$ecoleId/supports',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> validerSupport(
    int ecoleId,
    int supportId,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/supports/$supportId/valider',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> rejeterSupport(
    int ecoleId,
    int supportId,
    String motif,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/supports/$supportId/rejeter',
      data: {'motif_rejet': motif},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerSupport(
    int ecoleId,
    int supportId,
  ) async {
    final response = await dio.delete(
      '/api/ecoles/$ecoleId/supports/$supportId',
    );
    return response.data;
  }

  static String getDownloadUrl(int ecoleId, int supportId) {
    return '$baseUrl/api/ecoles/$ecoleId/supports/$supportId/download';
  }

  static Future<void> telechargerSupport(
    int ecoleId,
    int supportId,
    String savePath,
  ) async {
    await dio.download(
      '/api/ecoles/$ecoleId/supports/$supportId/download',
      savePath,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABSENCES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMesAbsences(
    int ecoleId, {
    bool? justifiee,
  }) async {
    final params = <String, dynamic>{};
    if (justifiee != null) params['justifiee'] = justifiee ? 1 : 0;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/absences',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getStatutExclusion(
    int ecoleId, {
    required int etudiantId,
    required int ecueId,
    required int semestreId,
  }) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/absences/statut-exclusion',
      queryParameters: {
        'etudiant_id': etudiantId,
        'ecue_id': ecueId,
        'semestre_id': semestreId,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> justifierAbsence(
    int ecoleId,
    int absenceId, {
    required String typeJustification,
    String? observation,
  }) async {
    final response = await dio.patch(
      '/api/ecoles/$ecoleId/absences/$absenceId/justifier',
      data: {
        'type_justification': typeJustification,
        if (observation != null) 'observation': observation,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getPresencesCours(
    int ecoleId,
    int coursId,
  ) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/cours/$coursId/presences',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> saisirPresences(
    int ecoleId,
    int coursId,
    List<Map<String, dynamic>> presences,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/cours/$coursId/presences',
      data: {'presences': presences},
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES & DEVOIRS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getDevoirs(
    int ecoleId, {
    int? ecueId,
    int? classeId,
    int? session,
    String? type,
  }) async {
    final params = <String, dynamic>{};
    if (ecueId != null) params['ecue_id'] = ecueId;
    if (classeId != null) params['classe_id'] = classeId;
    if (session != null) params['session'] = session;
    if (type != null) params['type'] = type;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/devoirs',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getNotesEtudiant(
    int ecoleId, {
    int? ecueId,
    int? session,
    int? etudiantId,
  }) async {
    final params = <String, dynamic>{};
    if (ecueId != null) params['ecue_id'] = ecueId;
    if (session != null) params['session'] = session;
    if (etudiantId != null) params['etudiant_id'] = etudiantId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/notes/etudiant',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> creerDevoir(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/devoirs', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> saisirNotes(
    int ecoleId,
    int devoirId,
    List<Map<String, dynamic>> notes, {
    int? semestreId,
  }) async {
    final data = <String, dynamic>{'notes': notes};
    if (semestreId != null) data['semestre_id'] = semestreId;
    final response = await dio.post(
      '/api/ecoles/$ecoleId/devoirs/$devoirId/notes',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> autoriserSaisieNotes(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/notes/autoriser',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> revoquerAutorisation(
    int ecoleId,
    int autorisationId,
  ) async {
    final response = await dio.patch(
      '/api/ecoles/$ecoleId/notes/autoriser/$autorisationId/revoquer',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getAutorisations(int ecoleId) async {
    return {'data': []};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RELEVÉS & MOYENNES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMoyennesSemestre(
    int ecoleId, {
    required int etudiantId,
    required int semestreId,
    required int classeId,
    int session = 1,
  }) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/releves/moyennes-semestre',
      queryParameters: {
        'etudiant_id': etudiantId,
        'semestre_id': semestreId,
        'classe_id': classeId,
        'session': session,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> genererReleve(
    int ecoleId, {
    required int etudiantId,
    required int semestreId,
    required int classeId,
    required int session,
  }) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/releves/generer',
      data: {
        'etudiant_id': etudiantId,
        'semestre_id': semestreId,
        'classe_id': classeId,
        'session': session,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getRelevesList(
    int ecoleId, {
    int? etudiantId,
  }) async {
    final params = <String, dynamic>{};
    if (etudiantId != null) params['etudiant_id'] = etudiantId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/releves',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static String getTelechargementReleveUrl(
    int ecoleId,
    int releveId, {
    String? token,
  }) {
    final base = '$baseUrl/api/ecoles/$ecoleId/releves/$releveId/telecharger';
    if (token != null && token.isNotEmpty) return '$base?token=$token';
    return base;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIEMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getFraisEtudiant(
    int ecoleId, {
    int? etudiantId,
  }) async {
    final params = <String, dynamic>{};
    if (etudiantId != null) params['etudiant_id'] = etudiantId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/paiements/frais',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> initierPaiement(
    int ecoleId, {
    required int inscriptionId,
    required double montant,
    required String modePaiement,
    required String telephone,
  }) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/paiements/initier',
      data: {
        'inscription_id': inscriptionId,
        'montant': montant,
        'mode_paiement': modePaiement,
        'telephone': telephone,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getHistoriquePaiements(
    int ecoleId, {
    int? etudiantId,
  }) async {
    final params = <String, dynamic>{};
    if (etudiantId != null) params['etudiant_id'] = etudiantId;
    final response = await dio.get(
      '/api/ecoles/$ecoleId/paiements/historique',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> verifierStatutPaiement(
    int ecoleId,
    int paiementId,
  ) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/paiements/$paiementId/statut',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> genererRecu(
    int ecoleId,
    int paiementId,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/paiements/$paiementId/recu',
    );
    return response.data;
  }

  static String getRecuUrl(int ecoleId, int paiementId) {
    return '$baseUrl/api/ecoles/$ecoleId/paiements/$paiementId/recu';
  }

  //  NOUVEAU : Télécharger le PDF du reçu en bytes via Dio (avec token auth)
  // Remplace launchUrl qui ouvrait un navigateur externe sans token → 401
  // Route Laravel : GET /ecoles/{ecole_id}/paiements/{id}/recu
  static Future<Uint8List> telechargerRecuBytes(
    int ecoleId,
    int paiementId,
  ) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/paiements/$paiementId/recu',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
      ),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  // ── Types de frais ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTypesFrais(
    int ecoleId,
    int classeId,
  ) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/classes/$classeId/types-frais',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> creerTypeFrais(
    int ecoleId,
    int classeId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/classes/$classeId/types-frais',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> modifierTypeFrais(
    int ecoleId,
    int classeId,
    int fraisId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put(
      '/api/ecoles/$ecoleId/classes/$classeId/types-frais/$fraisId',
      data: data,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> supprimerTypeFrais(
    int ecoleId,
    int classeId,
    int fraisId,
  ) async {
    final response = await dio.delete(
      '/api/ecoles/$ecoleId/classes/$classeId/types-frais/$fraisId',
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION PÉDAGOGIQUE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getConfig(int ecoleId) async {
    final response = await dio.get('/api/ecoles/$ecoleId/config');
    return response.data;
  }

  static Future<Map<String, dynamic>> saveConfig(
    int ecoleId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles/$ecoleId/config', data: data);
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ÉCHÉANCES DE SCOLARITÉ
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEcheances(
    int ecoleId,
    int classeId,
  ) async {
    final response = await dio.get(
      '/api/ecoles/$ecoleId/classes/$classeId/echeances',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> upsertEcheances(
    int ecoleId,
    int classeId,
    List<Map<String, dynamic>> echeances,
  ) async {
    final response = await dio.post(
      '/api/ecoles/$ecoleId/classes/$classeId/echeances',
      data: {'echeances': echeances},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteEcheances(
    int ecoleId,
    int classeId,
  ) async {
    final response = await dio.delete(
      '/api/ecoles/$ecoleId/classes/$classeId/echeances',
    );
    return response.data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANNONCES & NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> enregistrerFcmToken(String token) async {
    try {
      await dio.post('/api/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      debugPrint('[ApiService] Erreur enregistrement FCM token: $e');
    }
  }
}
