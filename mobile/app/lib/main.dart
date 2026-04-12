import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'features/chat/ui/live_location_firestore_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Больше декодированных кадров в памяти — меньше повторных декодов при скролле чата.
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20;
  await bootstrap();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'LighChat',
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      routerConfig: router,
      builder: (context, child) =>
          LiveLocationFirestoreSync(child: child ?? const SizedBox.shrink()),
    );
  }
}
