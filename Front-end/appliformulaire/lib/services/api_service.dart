import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

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
                    // Prends la toute première ligne d'erreur de validation
                    final firstKey = errors.keys.first;
                    message = errors[firstKey][0].toString();
                  }
                }

                // Traduction manuelle basique pour les messages Laravel communs
                final lowerMessage = message.toLowerCase();
                if (lowerMessage.contains("has already been taken")) {
                  message = "Cet email est déjà lié à un compte existant.";
                } else if (lowerMessage.contains("selected email is invalid")) {
                  message = "Aucun compte trouvé avec cet email.";
                } else if (lowerMessage.contains("must be a valid email")) {
                  message = "Email invalide.";
                } else if (lowerMessage.contains("password")) {
                  message =
                      "Le mot de passe ne correspond pas ou est incorrect.";
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

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? nationality,
    String? phone,
  }) async {
    final response = await dio.post(
      '/api/register',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (nationality != null) 'nationality': nationality,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final data = response.data;

    if (data['token'] != null) {
      setToken(data['token']);
    }

    return data;
  }

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

  // ================= ÉCOLES =================

  static Future<Map<String, dynamic>> creerEcole(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/ecoles', data: data);
    return response.data;
  }

  static Future<List<dynamic>> ecolesEnAttente() async {
    final response = await dio.get('/api/ecoles/en-attente');
    return response.data;
  }

  static Future<Map<String, dynamic>> activerEcole(int id) async {
    final response = await dio.put('/api/ecoles/$id/activer');
    return response.data;
  }

  static Future<void> refuserEcole(int id, String motif) async {
    await dio.put('/api/ecoles/$id/refuser', data: {'motif': motif});
  }

  static Future<List<dynamic>> mesEcoles() async {
    final response = await dio.get('/api/mes-ecoles');
    return response.data;
  }

  static Future<List<dynamic>> getEcolesTraitees() async {
    final response = await dio.get('/api/ecoles/traitees');
    return response.data;
  }

  static Future<void> supprimerEcole(int id) async {
    await dio.delete('/api/ecoles/$id');
  }

  static Future<Map<String, dynamic>> rejoindreEcole(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/api/rejoindre', data: data);
    return response.data;
  }

  // ================= CODES =================

  static Future<Map<String, dynamic>> verifierCode(String code) async {
    final response = await dio.post(
      '/api/codes/verifier',
      data: {'code': code},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> genererCode(
    String role,
    String destinataire,
  ) async {
    final response = await dio.post(
      '/api/codes/generer',
      data: {'role': role, 'destinataire': destinataire},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> regenererCode(int codeId) async {
    final response = await dio.put('/api/codes/$codeId/regenerer');
    return response.data;
  }

  static Future<List<dynamic>> mesCodes() async {
    final response = await dio.get('/api/mes-codes');
    return response.data;
  }

  // ================= DEMANDES =================

  static Future<List<dynamic>> demandesEnAttente() async {
    final response = await dio.get('/api/demandes-en-attente');
    return response.data;
  }

  static Future<void> accepterDemande(int id) async {
    await dio.put('/api/demandes/$id/accepter');
  }

  static Future<void> rejeterDemande(int id, String motif) async {
    await dio.put('/api/demandes/$id/rejeter', data: {'motif': motif});
  }

  static Future<void> forgotPassword({required String email}) async {
    await dio.post('/api/forgot-password', data: {'email': email});
  }

  static Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
  }) async {
    await dio.post(
      '/api/reset-password',
      data: {
        'email': email,
        'code': otpCode,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  static Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await dio.post('/api/verify-email', data: {'email': email, 'code': code});
  }

  // ================= DASHBOARD =================

  static Future<Map<String, dynamic>> getDashboardAccueil() async {
    final response = await dio.get('/api/dashboard');
    return response.data;
  }
}
