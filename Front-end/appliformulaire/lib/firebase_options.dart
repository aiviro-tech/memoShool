import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Firebase configuration options for each platform.
/// Values extracted from google-services.json (Android) and Firebase console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // Android config from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiQr_GQN9kYI2MyLXI8oEdkDG0V09oXek',
    appId: '1:19291565143:android:46ba31a47ac2b765fc0712',
    messagingSenderId: '19291565143',
    projectId: 'memoshool',
    storageBucket: 'memoshool.firebasestorage.app',
  );

  // Web config — uses the same project keys
  // Note: If FCM push doesn't work on web, add a dedicated web app in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAiQr_GQN9kYI2MyLXI8oEdkDG0V09oXek',
    appId: '1:19291565143:web:memoshool_web_app',
    messagingSenderId: '19291565143',
    projectId: 'memoshool',
    storageBucket: 'memoshool.firebasestorage.app',
    authDomain: 'memoshool.firebaseapp.com',
  );

  // iOS placeholder
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAiQr_GQN9kYI2MyLXI8oEdkDG0V09oXek',
    appId: '1:19291565143:ios:memoshool_ios_app',
    messagingSenderId: '19291565143',
    projectId: 'memoshool',
    storageBucket: 'memoshool.firebasestorage.app',
    iosBundleId: 'com.example.appliformulaire',
  );
}
