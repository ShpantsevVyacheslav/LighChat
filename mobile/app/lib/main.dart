import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'features/chat/data/share_intent_listener.dart';
import 'platform/platform_capabilities.dart';
import 'ui/responsive/desktop_shortcuts.dart';
import 'features/chat/data/chat_auto_theme_mode.dart';
import 'features/auth/device_session_firestore_sync.dart';
import 'features/chat/ui/live_location_firestore_sync.dart';
import 'features/settings/data/app_language_preference.dart';
import 'features/chat/ui/in_app_call_mini_window_host.dart';
import 'features/desktop_shell/desktop_shell.dart';
import 'features/desktop_shell/desktop_drop_target.dart';
import 'features/desktop_shell/desktop_deep_links.dart';
import 'features/desktop_shell/desktop_auto_updater.dart';
import 'features/desktop_shell/desktop_single_instance.dart';
import 'features/push/push_fallback_service.dart';
import 'features/analytics/analytics_provider.dart';
import 'features/analytics/analytics_events.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Single-instance: если уже есть запущенная копия — передали ей фокус,
  // завершаемся. Делается _до_ всех остальных init, чтобы не плодить
  // ProcessSingleton-resources зря.
  if (DesktopSingleInstance.instance.isSupported) {
    final isPrimary = await DesktopSingleInstance.instance.acquire();
    if (!isPrimary) {
      // Уже работает — graceful exit без runApp.
      return;
    }
  }
  // Desktop окно нужно инициализировать до `runApp`, чтобы первый кадр
  // отрисовался в правильном размере без вспышки 800×600.
  if (DesktopShell.instance.isSupported) {
    await DesktopShell.instance.initWindow();
  }
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
  // [audit L-005] Подключаем Crashlytics: SDK был в pubspec.yaml, но не
  // инициализирован — крэши уходили в системный лог без stack-traces в
  // Firebase Console. Web Crashlytics не поддерживает (`flutter_crashlytics`
  // throws), поэтому только на native.
  // Crashlytics на Windows/Linux нет: firebase_crashlytics поддерживает только
  // iOS/Android/macOS/web. На остальных платформах оставляем стандартный
  // FlutterError handler.
  final crashlyticsAvailable =
      !kIsWeb && !Platform.isWindows && !Platform.isLinux;
  if (crashlyticsAvailable) {
    try {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true; // обработали — не передаём дальше в crash-loop runtime
      };
    } catch (e, st) {
      logger.w('Crashlytics wiring failed', error: e, stackTrace: st);
    }
  }
  if (nativePushAvailable && iosPushRuntimeEnabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  if (callKitSupported) {
    await PushNativeCallService.instance.ensureInitialized();
  }
  if (pushFallbackEnabled) {
    unawaited(PushFallbackService.instance.start());
  }
  // Трей поднимаем после bootstrap, чтобы иметь рабочий window handle.
  if (DesktopShell.instance.isSupported) {
    unawaited(DesktopShell.instance.initTray());
    // В release включаем периодическую проверку обновлений; в debug —
    // нет, чтобы не дёргать prod CDN на каждый run.
    if (kReleaseMode) {
      unawaited(DesktopAutoUpdater.instance.initialize());
    }
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
  ShareIntentListener? _shareIntentListener;
  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = kDefaultAppThemeSeed;
  String _themeFingerprint = '';

  @override
  void initState() {
    super.initState();
    attachAppGoRouter(_router);
    PushNativeCallService.instance.flushDeferredNavigation();
    // Аналитика: init на первом кадре после bootstrap (Firebase уже готов).
    // setConsent вызывается из onboarding consent-экрана; здесь только читаем
    // ранее сохранённое решение и шлём app_open если consent был выдан.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final svc = ref.read(analyticsServiceProvider);
        await svc.init();
        if (svc.hasConsent) {
          await svc.logEvent(AnalyticsEvents.appOpen, const <String, Object?>{});
        }
      } catch (_) {
        // never block UI
      }
    });
    if (!kIsWeb) {
      attachMeetingWebDeepLinks(_router).then((sub) {
        if (!mounted) {
          sub.cancel();
          return;
        }
        _meetingDeepLinksSub = sub;
      });
      // Phase B: системный «Поделиться → LighChat» (iOS Share Extension /
      // Android ACTION_SEND). На desktop (macOS/Windows/Linux) пакет
      // receive_sharing_intent не имеет нативной реализации
      // (MissingPluginException), поэтому пропускаем — drag&drop файлов
      // на desktop делается через `desktop_drop` (см. DesktopShell).
      if (defaultPlatformCapabilities.hasSystemShareIntent) {
        ShareIntentListener.attach(router: _router).then((l) {
          if (!mounted) {
            l?.dispose();
            return;
          }
          _shareIntentListener = l;
        });
      }
      // Desktop deep links (lighchat://). На mobile тоже работает, но там
      // у нас нет регистрации схемы — handler просто проигнорирует чужие
      // URI. На macOS/Windows/Linux это единственный путь open-from-browser.
      if (DesktopShell.instance.isSupported) {
        unawaited(DesktopDeepLinks.instance.attach(_router));
      }
    }
  }

  @override
  void dispose() {
    _meetingDeepLinksSub?.cancel();
    _shareIntentListener?.dispose();
    unawaited(DesktopDeepLinks.instance.detach());
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
    // На desktop при появлении uid (логин или cold-start с persistent
    // session) маркируем пользователя как desktop-владельца — серверный
    // mirror push в `users/{uid}/incomingNotifications` будет работать
    // только для UID с записью `devicePlatforms: ['desktop']`.
    if (uid != null && DesktopShell.instance.isSupported) {
      unawaited(DesktopShell.instance.markDesktopDevice());
    }
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
      builder: (context, child) => DesktopShortcuts(
        child: DeviceSessionFirestoreSync(
        child: LiveLocationFirestoreSync(
          child: InAppIncomingCallScope(
            child: InAppCallMiniWindowHost(
              child: PushMessagingScope(
                child: DesktopDropTarget(
                  router: _router,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
