import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

import 'firebase_options.dart';

final logger = Logger();

/// Application bootstrap (Firebase must finish before [runApp]).
Future<void> bootstrap() async {
  // Prevent native Firebase from crashing the process when options are clearly
  // not meant for this platform (e.g. web appId on macOS/iOS/Android).
  if (!kIsWeb) {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts.appId.contains(':web:')) {
      logger.w(
        'Firebase options look like web options (appId contains ":web:"). '
        'Skipping Firebase.initializeApp on native until you run FlutterFire configure.',
      );
      return;
    }
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    logger.w('Firebase.initializeApp failed.', error: e, stackTrace: st);
  }
}

