import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
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

  /// Дедуп: храним последний отправленный (по method) jsonEncoded args,
  /// чтобы не спамить native одинаковыми пушами при ребилдах Flutter
  /// widget'ов (типичная серия: каждый rebuild ChatHeader → 5 одинаковых
  /// setSearchMode'ов подряд).
  final Map<String, String> _lastSent = <String, String>{};

  Stream<NavBarEvent> get events => _events.stream;

  /// Сбросить дедуп-кэш — используется в тестах между сценариями.
  @visibleForTesting
  void resetDedupeCacheForTests() {
    _lastSent.clear();
  }

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Дополнительный bottom-padding, который Flutter-список (chat_list,
  /// chat_calls, chat_meetings, chat_screen messages) должен добавить,
  /// чтобы последний item можно было проскроллить ВЫШЕ нативного
  /// tab-bar'а. Соответствует `tabBarContentHeight (49) +
  /// tabBarBottomOverlap (16)` в Swift = 65pt. На Android / Web / Win /
  /// Linux возвращает 0 — Flutter-side ChatBottomNav сам занимает
  /// место в Scaffold.bottomNavigationBar.
  double get bottomBarOverlayPadding => isSupported ? 65.0 : 0.0;

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

  Future<void> hideAll() {
    // КРИТИЧЕСКИЙ race condition был с `await` между двумя вызовами:
    // observer (didPop + didPush на context.go) запускал hideAll() ДВА
    // раза подряд. Каждый `await` yield'ил микротаск, и постframe-push
    // нового экрана (`setBottomBar(visible)`) успевал протиснуться
    // МЕЖДУ hide-top и hide-bottom continuations. В итоге канал получал:
    //   hide_top_1, hide_top_2, visible_push, hide_bottom_1, hide_bottom_2
    // — последний hide убивал bar. Стреляем оба invokeMethod
    // синхронно (без yield), Future.wait ждёт обе.
    return Future.wait([
      setTopBar(const NavBarTopConfig.hidden()),
      setBottomBar(const NavBarBottomConfig.hidden()),
    ]);
  }

  Future<void> _invoke(String method, Map<String, Object?> args) async {
    if (!isSupported) return;
    // Dedupe: одинаковый config второй раз подряд не шлём в native.
    // jsonEncode стабилен для наших скалярных-only моделей.
    final encoded = jsonEncode(args);
    if (_lastSent[method] == encoded) {
      return;
    }
    _lastSent[method] = encoded;
    try {
      appLogger.d('[native-nav] -> $method ${_summarize(args)}');
      await _methodChannel.invokeMethod<void>(method, args);
    } catch (e) {
      appLogger.w('[native-nav] $method failed', error: e);
    }
  }

  /// Лог-friendly короткое представление аргументов (без длинных URL'ов).
  String _summarize(Map<String, Object?> args) {
    final visible = args['visible'];
    final selected = args['selectedId'];
    final active = args['active'];
    final count = args['count'];
    final items = args['items'];
    final tail = <String>[
      if (visible != null) 'visible=$visible',
      if (selected != null) "selected=$selected",
      if (active != null) "active=$active",
      if (count != null) "count=$count",
      if (items is List) 'items=${items.length}',
    ].join(' ');
    return tail.isEmpty ? '{}' : '{$tail}';
  }

  void _onEvent(dynamic raw) {
    final event = NavBarEvent.fromMap(raw);
    if (event != null) {
      appLogger.d('[native-nav] <- ${event.runtimeType}');
      _events.add(event);
    } else {
      appLogger.w('[native-nav] <- unparsable event payload: $raw');
    }
  }
}
