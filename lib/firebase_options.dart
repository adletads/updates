// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5tV2KI2b2vmuiz0LYVmdWWCdt7gt0iO8',
    authDomain: 'employee-updater-app.firebaseapp.com',
    projectId: 'employee-updater-app',
    storageBucket: 'employee-updater-app.firebasestorage.app',
    messagingSenderId: '822468940617',
    appId: '1:822468940617:web:23ab12f01a865c4f1e0098',
  );
}
