// Generated from the same Firebase project as the web client (`src/firebase/config.ts`).
// If a platform fails to initialize (invalid `appId` for iOS/Android/macOS), add the app
// in the Firebase Console and run: `dart pub global run flutterfire_cli:flutterfire configure`
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for LighChat (project `project-72b24`).
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE',
    appId: '1:262148817877:web:d4191fc34eca6977f0335c',
    messagingSenderId: '262148817877',
    projectId: 'project-72b24',
    authDomain: 'project-72b24.firebaseapp.com',
    storageBucket: 'project-72b24.firebasestorage.app',
  );

  /// Uses the same API keys as web; ensure an Android app exists in Firebase for this package name.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE',
    appId: '1:262148817877:web:d4191fc34eca6977f0335c',
    messagingSenderId: '262148817877',
    projectId: 'project-72b24',
    storageBucket: 'project-72b24.firebasestorage.app',
  );

  /// Replace `appId` with the iOS app id from Firebase Console if sign-in or Firestore fails.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfedXYICIrF0VPOXkmqB72QoW6J3fEXpg',
    appId: '1:262148817877:ios:b3472b836d144249f0335c',
    messagingSenderId: '262148817877',
    projectId: 'project-72b24',
    storageBucket: 'project-72b24.firebasestorage.app',
    iosBundleId: 'com.lighchat.lighchatMobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE',
    appId: '1:262148817877:web:d4191fc34eca6977f0335c',
    messagingSenderId: '262148817877',
    projectId: 'project-72b24',
    storageBucket: 'project-72b24.firebasestorage.app',
    iosBundleId: 'com.lighchat.lighchatMobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD9GMaIREDiU4twHnMQg5utITpJ7ZVnlYE',
    appId: '1:262148817877:web:d4191fc34eca6977f0335c',
    messagingSenderId: '262148817877',
    projectId: 'project-72b24',
    authDomain: 'project-72b24.firebaseapp.com',
    storageBucket: 'project-72b24.firebasestorage.app',
  );
}
