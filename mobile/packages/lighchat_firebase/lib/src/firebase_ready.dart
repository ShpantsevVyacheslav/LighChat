import 'package:firebase_core/firebase_core.dart';

/// Firebase is considered ready if at least one app is initialized.
bool isFirebaseReady() => Firebase.apps.isNotEmpty;

