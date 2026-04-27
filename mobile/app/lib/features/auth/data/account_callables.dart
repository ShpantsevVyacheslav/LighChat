import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Account-level callable functions (Cloud Functions).
///
/// Region matches CF deployment: `us-central1`.
class AccountCallables {
  AccountCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  Future<void> deleteAccount() async {
    final callable = _functions.httpsCallable(
      'deleteAccount',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );
    await callable.call<void>(const <String, Object?>{});
  }
}

