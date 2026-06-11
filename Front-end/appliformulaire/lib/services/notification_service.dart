// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:appliformulaire/services/api_service.dart';

// ── Handler background (top-level obligatoire) ────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}');
  await NotificationService._afficherNotifLocale(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'paiements_channel';
  static const _channelName = 'Paiements';
  static const _channelDesc = 'Notifications de paiements et frais de scolarité';

  // ── Initialisation complète ──────────────────────────────────────────────
  static Future<void> initialiser() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotifTapped,
    );

    await _creerCanalAndroid();
    await _demanderPermissions();
    await _enregistrerToken();

    FirebaseMessaging.onMessage.listen(_onMessageForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOuvert);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onMessageOuvert(initial);
  }

  // ── Canal Android ────────────────────────────────────────────────────────
  static Future<void> _creerCanalAndroid() async {
    const canal = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  // ── Permissions iOS ──────────────────────────────────────────────────────
  static Future<void> _demanderPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // ── Token FCM ────────────────────────────────────────────────────────────
  static Future<void> _enregistrerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.enregistrerFcmToken(token);
        debugPrint('[FCM] Token enregistré : ${token.substring(0, 20)}...');
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await ApiService.enregistrerFcmToken(newToken);
        debugPrint('[FCM] Token rafraîchi');
      });
    } catch (e) {
      debugPrint('[FCM] Erreur token : $e');
    }
  }

  // ── Message foreground ───────────────────────────────────────────────────
  static Future<void> _onMessageForeground(RemoteMessage message) async {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    await _afficherNotifLocale(message);
  }

  // ── Afficher notification locale ─────────────────────────────────────────
  static Future<void> _afficherNotifLocale(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    final type = message.data['type'] ?? '';

    // Couleur selon type de notification
    final Color couleur;
    if (type == 'paiement_approuve') {
      couleur = const Color(0xFF2E7D32);
    } else if (type == 'paiement_refuse') {
      couleur = const Color(0xFFC62828);
    } else {
      couleur = const Color(0xFF1565C0);
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: couleur,
      styleInformation: BigTextStyleInformation(
        notif.body ?? '',
        contentTitle: notif.title,
        summaryText: 'MémoSchool',
      ),
      ticker: notif.title,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifs.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  // ── Clic notification ────────────────────────────────────────────────────
  static void _onNotifTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _naviguerSelonType(data);
    } catch (_) {}
  }

  static void _onMessageOuvert(RemoteMessage message) {
    _naviguerSelonType(message.data);
  }

  static void _naviguerSelonType(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    debugPrint('[FCM Navigation] type=$type');
  }

  // ── Notif manuelle ───────────────────────────────────────────────────────
  static Future<void> notifierPaiementApprouve({
    required String nomEtudiant,
    required double montant,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF2E7D32),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifs.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ' Paiement approuvé',
      '$nomEtudiant — ${montant.toStringAsFixed(0)} FCFA reçu avec succès',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}