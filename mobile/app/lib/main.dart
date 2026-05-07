import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap.dart';
import 'app_providers.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/meetings/data/meeting_deep_links.dart';
import 'features/push/push_messaging_background.dart';
import 'features/push/in_app_incoming_call_scope.dart';
import 'features/push/push_messaging_scope.dart';
import 'features/push/push_native_call_service.dart';
import 'features/push/push_runtime_flags.dart';
import 'features/chat/data/app_theme_preference.dart';
import 'features/chat/data/chat_auto_theme_mode.dart';
import 'features/auth/device_session_firestore_sync.dart';
import 'features/chat/ui/live_location_firestore_sync.dart';
import 'features/settings/data/app_language_preference.dart';
import 'features/chat/ui/in_app_call_mini_window_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  // Больше декодированных кадров в памяти — меньше повторных декодов при скролле чата.
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20;
  await bootstrap();
  if (!kIsWeb && iosPushRuntimeEnabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNativeCallService.instance.ensureInitialized();
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router = createRouter();
  StreamSubscription<Uri>? _meetingDeepLinksSub;
  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = kDefaultAppThemeSeed;
  String _themeFingerprint = '';

  @override
  void initState() {
    super.initState();
    attachAppGoRouter(_router);
    PushNativeCallService.instance.flushDeferredNavigation();
    if (!kIsWeb) {
      attachMeetingWebDeepLinks(_router).then((sub) {
        if (!mounted) {
          sub.cancel();
          return;
        }
        _meetingDeepLinksSub = sub;
      });
    }
  }

  @override
  void dispose() {
    _meetingDeepLinksSub?.cancel();
    super.dispose();
  }

  Future<void> _applyTheme({
    required String fingerprint,
    required AppThemePreference pref,
    required String? wallpaper,
  }) async {
    final resolution = await resolveAppThemeResolution(
      preference: pref,
      chatWallpaper: wallpaper,
    );
    if (!mounted || _themeFingerprint != fingerprint) {
      return;
    }
    if (resolution.mode == _themeMode && resolution.seedColor == _seedColor) {
      return;
    }
    setState(() {
      _themeMode = resolution.mode;
      _seedColor = resolution.seedColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authUserProvider).asData?.value;
    final uid = authUser?.uid;
    final userDoc = uid == null
        ? const <String, dynamic>{}
        : (ref.watch(userChatSettingsDocProvider(uid)).asData?.value ??
              const <String, dynamic>{});

    final pref = appThemePreferenceFromRaw(userDoc['appTheme']);
    final rawChatSettings = Map<String, dynamic>.from(
      userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
    );
    final wallpaper = rawChatSettings['chatWallpaper'] as String?;
    final fingerprint = '${uid ?? 'anon'}|${pref.name}|${wallpaper ?? ''}';
    if (fingerprint != _themeFingerprint) {
      _themeFingerprint = fingerprint;
      unawaited(
        _applyTheme(fingerprint: fingerprint, pref: pref, wallpaper: wallpaper),
      );
    }

    final languagePref = ref.watch(appLanguagePreferenceProvider);

    return MaterialApp.router(
      title: 'LighChat',
      theme: buildAppTheme(brightness: Brightness.light, seedColor: _seedColor),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
        seedColor: _seedColor,
      ),
      themeMode: _themeMode,
      locale: languagePref.toLocaleOrNull(),
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('ru');
        final code = locale.languageCode.toLowerCase();
        final country = (locale.countryCode ?? '').toUpperCase();
        // Точное совпадение (язык + страна).
        for (final s in supportedLocales) {
          if (s.languageCode.toLowerCase() == code &&
              (s.countryCode ?? '').toUpperCase() == country) {
            return s;
          }
        }
        // Совпадение только по языку.
        for (final s in supportedLocales) {
          if (s.languageCode.toLowerCase() == code) return s;
        }
        return const Locale('ru');
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) => DeviceSessionFirestoreSync(
        child: LiveLocationFirestoreSync(
          child: InAppIncomingCallScope(
            child: InAppCallMiniWindowHost(
              child: PushMessagingScope(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
