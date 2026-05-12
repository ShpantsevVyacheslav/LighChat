import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:lighchat_mobile/core/app_logger.dart';

import 'nav_bar_config.dart';

/// Native UIKit/AppKit navigation bar overlay.
///
/// - **iOS**: `UINavigationBar` + `UITabBar` rendered as subviews over the
///   `FlutterViewController.view`. Liquid Glass appearance on iOS 26+.
/// - **macOS**: `NSToolbar` on the host window. Liquid Glass on macOS 26+.
/// - **Android / Windows / Linux / Web**: facade is a no-op — Flutter
///   `Scaffold` / `AppBar` / `bottomNavigationBar` fallback handles the UI.
///
/// Channel contract: see `docs/arcitecture/native-nav-bar.md`.
class NativeNavBarFacade {
  NativeNavBarFacade._() {
    if (isSupported) {
      _eventChannel.receiveBroadcastStream().listen(
        _onEvent,
        onError: (Object error, StackTrace st) {
          appLogger.w('[native-nav] event stream error', error: error);
        },
      );
    }
  }

  static final NativeNavBarFacade instance = NativeNavBarFacade._();

  static const MethodChannel _methodChannel =
      MethodChannel('lighchat/native_nav');
  static const EventChannel _eventChannel =
      EventChannel('lighchat/native_nav/events');

  final StreamController<NavBarEvent> _events =
      StreamController<NavBarEvent>.broadcast();

  Stream<NavBarEvent> get events => _events.stream;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Future<void> setTopBar(NavBarTopConfig config) =>
      _invoke('setTopBar', config.toMap());

  Future<void> setBottomBar(NavBarBottomConfig config) =>
      _invoke('setBottomBar', config.toMap());

  Future<void> setSearchMode(NavBarSearchConfig config) =>
      _invoke('setSearchMode', config.toMap());

  Future<void> setSelectionMode(NavBarSelectionConfig config) =>
      _invoke('setSelectionMode', config.toMap());

  Future<void> setScrollOffset(double offset) =>
      _invoke('setScrollOffset', {'contentOffset': offset});

  Future<void> hideAll() async {
    await setTopBar(const NavBarTopConfig.hidden());
    await setBottomBar(const NavBarBottomConfig.hidden());
  }

  Future<void> _invoke(String method, Map<String, Object?> args) async {
    if (!isSupported) return;
    try {
      await _methodChannel.invokeMethod<void>(method, args);
    } catch (e) {
      appLogger.w('[native-nav] $method failed', error: e);
    }
  }

  void _onEvent(dynamic raw) {
    final event = NavBarEvent.fromMap(raw);
    if (event != null) _events.add(event);
  }
}
