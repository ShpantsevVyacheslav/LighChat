import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_firebase/lighchat_firebase.dart';

void main() {
  test('isFirebaseReady returns bool', () {
    // In unit tests Firebase isn't initialized; this should still be safe.
    final v = isFirebaseReady();
    expect(v, isA<bool>());
  });
}
