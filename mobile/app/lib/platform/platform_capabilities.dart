import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Способ ввода в редакторе изображений.
enum ImageMarkupKind {
  /// iOS/macOS PencilKit (Apple Pencil / трекпад).
  applePencil,

  /// Flutter-native canvas (палец / мышь).
  flutterCanvas,

  /// Редактор отключён.
  none,
}

/// Доступная биометрия для разблокировки/recovery.
enum BiometricKind {
  touchId,
  faceId,
  windowsHello,
  fingerprintAndroid,
  linuxPolkit,
  none,
}

/// Каким каналом приходят входящие push'ы / звонки.
enum PushTransport {
  /// Нативный Firebase Messaging (iOS/Android/macOS).
  firebaseMessaging,

  /// Firestore listener fallback (Windows/Linux/web без SW).
  firestoreFallback,

  /// Web Push (PWA Service Worker).
  webPush,
}

/// Способ отображения входящего звонка.
enum IncomingCallPresentation {
  /// CallKit / ConnectionService (iOS/Android).
  systemCallScreen,

  /// Кастомное borderless-окно поверх всех приложений.
  customDesktopWindow,

  /// In-app overlay (web / fallback).
  inAppOverlay,
}

/// Единая точка ветвления платформо-зависимого поведения.
///
/// Заменяет россыпь `Platform.isIOS` / `Platform.isAndroid` в коде. Реализация
/// выбирается в [defaultPlatformCapabilities] на старте приложения; тесты
/// подменяют её через override [platformCapabilitiesProvider].
abstract class PlatformCapabilities {
  const PlatformCapabilities();

  // ──────────────── Идентификация ────────────────

  bool get isWeb;
  bool get isMobile;
  bool get isDesktop;
  bool get isIOS;
  bool get isAndroid;
  bool get isMacOS;
  bool get isWindows;
  bool get isLinux;

  /// Короткий ярлык платформы для отправки в Cloud Functions:
  /// `ios`, `android`, `macos`, `windows`, `linux`, `web`.
  String get platformTag;

  // ──────────────── Камера и медиа ────────────────

  /// Доступна ли камера через пакет `camera` (iOS/Android только).
  bool get hasNativeCameraPlugin;

  /// Можно ли захватывать видео-кружки и фото в чате.
  /// На desktop вместо `camera` используется `flutter_webrtc`-preview.
  bool get canCaptureCameraInChat;

  /// Можно ли сохранять медиа в системную галерею (`gal`).
  /// На desktop вместо галереи — Downloads.
  bool get hasSystemMediaGallery;

  // ──────────────── Контакты и шеринг ────────────────

  /// Доступна ли системная адресная книга (`flutter_contacts`).
  /// macOS — через MethodChannel поверх Contacts.framework.
  bool get hasSystemContactsBook;

  /// Доступен ли системный «Поделиться → LighChat» (Share Extension /
  /// ACTION_SEND). На desktop — нет, заменяется drag&drop + clipboard.
  bool get hasSystemShareIntent;

  // ──────────────── Биометрия и защита ────────────────

  /// Поддерживает ли ОС какую-либо биометрическую разблокировку.
  bool get hasBiometricAuth;
  BiometricKind get biometricKind;

  /// Можно ли запретить скриншоты / превью окна.
  /// Android — flutter_windowmanager_plus. macOS — NSWindow.sharingType.
  /// Windows — SetWindowDisplayAffinity. Linux — нет API.
  bool get hasScreenshotProtection;

  // ──────────────── Геолокация ────────────────

  /// Можно ли шарить live location.
  /// Desktop без GPS — отключаем, чтобы не показывать неработающую кнопку.
  bool get canShareLiveLocation;

  // ──────────────── Push / звонки ────────────────

  PushTransport get pushTransport;
  IncomingCallPresentation get incomingCallPresentation;

  // ──────────────── Редактор изображений ────────────────

  ImageMarkupKind get imageMarkupKind;

  /// Доступна ли разметка фото перед отправкой (текущий iOS-only флоу).
  bool get hasImageMarkup => imageMarkupKind != ImageMarkupKind.none;

  // ──────────────── Окно и системный трей ────────────────

  /// Есть ли отдельное прикладное окно (управляется window_manager).
  bool get hasWindowChrome;

  /// Доступен ли системный tray + dock badge.
  bool get hasSystemTray;
}

/// Базовая реализация поверх `dart:io` + `kIsWeb`.
class _IoPlatformCapabilities extends PlatformCapabilities {
  const _IoPlatformCapabilities();

  @override
  bool get isWeb => kIsWeb;

  @override
  bool get isIOS => !kIsWeb && Platform.isIOS;

  @override
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  bool get isMacOS => !kIsWeb && Platform.isMacOS;

  @override
  bool get isWindows => !kIsWeb && Platform.isWindows;

  @override
  bool get isLinux => !kIsWeb && Platform.isLinux;

  @override
  bool get isMobile => isIOS || isAndroid;

  @override
  bool get isDesktop => isMacOS || isWindows || isLinux;

  @override
  String get platformTag {
    if (isWeb) return 'web';
    if (isIOS) return 'ios';
    if (isAndroid) return 'android';
    if (isMacOS) return 'macos';
    if (isWindows) return 'windows';
    if (isLinux) return 'linux';
    return 'unknown';
  }

  // ── Камера ──
  @override
  bool get hasNativeCameraPlugin => isMobile;

  @override
  bool get canCaptureCameraInChat => true; // на desktop через flutter_webrtc

  @override
  bool get hasSystemMediaGallery => isMobile;

  // ── Контакты / шеринг ──
  @override
  bool get hasSystemContactsBook => isMobile || isMacOS;

  @override
  bool get hasSystemShareIntent => isMobile;

  // ── Биометрия ──
  @override
  bool get hasBiometricAuth =>
      isIOS || isAndroid || isMacOS || isWindows; // Linux — без OOB-биометрии

  @override
  BiometricKind get biometricKind {
    if (isIOS) return BiometricKind.faceId; // в рантайме уточняется local_auth
    if (isAndroid) return BiometricKind.fingerprintAndroid;
    if (isMacOS) return BiometricKind.touchId;
    if (isWindows) return BiometricKind.windowsHello;
    if (isLinux) return BiometricKind.linuxPolkit;
    return BiometricKind.none;
  }

  @override
  bool get hasScreenshotProtection => isAndroid || isMacOS || isWindows;

  // ── Геолокация ──
  @override
  bool get canShareLiveLocation => isMobile;

  // ── Push ──
  @override
  PushTransport get pushTransport {
    if (isIOS || isAndroid || isMacOS) return PushTransport.firebaseMessaging;
    if (isWeb) return PushTransport.webPush;
    return PushTransport.firestoreFallback; // Windows / Linux
  }

  @override
  IncomingCallPresentation get incomingCallPresentation {
    if (isMobile) return IncomingCallPresentation.systemCallScreen;
    if (isDesktop) return IncomingCallPresentation.customDesktopWindow;
    return IncomingCallPresentation.inAppOverlay;
  }

  // ── Image markup ──
  @override
  ImageMarkupKind get imageMarkupKind {
    if (isIOS || isMacOS) return ImageMarkupKind.applePencil;
    if (isAndroid || isWindows || isLinux) return ImageMarkupKind.flutterCanvas;
    return ImageMarkupKind.none;
  }

  // ── Окно ──
  @override
  bool get hasWindowChrome => isDesktop;

  @override
  bool get hasSystemTray => isDesktop;
}

const PlatformCapabilities defaultPlatformCapabilities =
    _IoPlatformCapabilities();

/// Riverpod-провайдер для доступа к [PlatformCapabilities]. В тестах
/// переопределяется через `ProviderScope(overrides: [...])`.
final Provider<PlatformCapabilities> platformCapabilitiesProvider =
    Provider<PlatformCapabilities>((ref) => defaultPlatformCapabilities);
