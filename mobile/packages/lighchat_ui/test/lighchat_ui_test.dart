import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lighchat_ui/lighchat_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('theme builder returns ThemeData', () {
    final t = lighChatTheme(brightness: Brightness.light);
    expect(t, isA<ThemeData>());
  });
}
