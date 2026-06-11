import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_model.dart';

class AnnonceService {
  /// Lister les annonces visibles pour l'utilisateur connecté
  Future<List<AnnonceModel>> getAnnonces(int ecoleId) async {
    final response = await ApiService.dio.get(
      '/api/ecoles/$ecoleId/annonces',
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AnnonceModel.fromJson(e)).toList();
  }

  /// Créer une annonce (admin uniquement)
  Future<AnnonceModel> creerAnnonce(int ecoleId, Map<String, dynamic> data) async {
    final response = await ApiService.dio.post(
      '/api/ecoles/$ecoleId/annonces',
      data: data,
    );
    return AnnonceModel.fromJson(response.data['data']);
  }

  /// Modifier une annonce (admin uniquement)
  Future<AnnonceModel> modifierAnnonce(int ecoleId, int id, Map<String, dynamic> data) async {
    final response = await ApiService.dio.put(
      '/api/ecoles/$ecoleId/annonces/$id',
      data: data,
    );
    return AnnonceModel.fromJson(response.data['data']);
  }

  /// Supprimer une annonce (admin uniquement)
  Future<void> supprimerAnnonce(int ecoleId, int id) async {
    await ApiService.dio.delete('/api/ecoles/$ecoleId/annonces/$id');
  }

  /// Publier une annonce (toggle publie = true)
  Future<AnnonceModel> publierAnnonce(int ecoleId, int id) async {
    return modifierAnnonce(ecoleId, id, {'publie': true});
  }
}

class NotificationService {
  /// Lister les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications(int ecoleId, {bool? lu, String? type}) async {
    final params = <String, dynamic>{};
    if (lu != null) params['lu'] = lu ? 1 : 0;
    if (type != null) params['type'] = type;

    final response = await ApiService.dio.get(
      '/api/ecoles/$ecoleId/notifications',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => NotificationModel.fromJson(e)).toList();
  }

  /// Compteur de notifications non lues
  Future<int> getCompteurNonLues(int ecoleId) async {
    try {
      final response = await ApiService.dio.get(
        '/api/ecoles/$ecoleId/notifications/compteur',
      );
      return response.data['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Marquer une notification comme lue
  Future<void> marquerLue(int ecoleId, int id) async {
    await ApiService.dio.patch('/api/ecoles/$ecoleId/notifications/$id/lue');
  }

  /// Marquer toutes les notifications comme lues
  Future<void> marquerToutesLues(int ecoleId) async {
    await ApiService.dio.patch('/api/ecoles/$ecoleId/notifications/toutes-lues');
  }

  /// Supprimer une notification
  Future<void> supprimer(int ecoleId, int id) async {
    await ApiService.dio.delete('/api/ecoles/$ecoleId/notifications/$id');
  }

  /// Enregistrer le token FCM Firebase
  Future<void> enregistrerTokenFCM(String token, {String device = 'android'}) async {
    await ApiService.dio.post('/api/fcm-token', data: {
      'token': token,
      'device': device,
    });
  }
}