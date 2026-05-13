import 'package:flutter/services.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'dart:io' show Platform;

/// Управление режимом «картинка-в-картинке» для активной видеоконференции.
///
/// Текущая реализация:
/// - **Android**: вызывает нативный `enterPictureInPictureMode()` на текущей
///   Activity через method channel `lighchat/pip:enter`. Flutter UI продолжает
///   отрисовываться внутри Activity, никакого спец-рендера на native-стороне
///   не нужно.
/// - **iOS**: `lighchat/pip:isSupported` возвращает `true` только если
///   зарегистрирован WebRTC-совместимый pipeline (AVSampleBufferDisplayLayer
///   + content source). Текущий iOS-бридж AppDelegate.swift поддерживает
///   только URL-видео и для live-конференции не подходит — поэтому
///   `enterPip()` на iOS вернёт `false`, а кнопка PiP скрывается.
///
/// Авто-PiP при сворачивании приложения подключается через
/// [PipLifecycleObserver] — он слушает `AppLifecycleState.inactive` и зовёт
/// [enterPip] (без падения в случае iOS).
class MeetingPipController {
  MeetingPipController({MethodChannel? channel})
      : _channel = channel ??
            MethodChannel(
              Platform.isIOS ? 'lighchat/meeting_pip' : 'lighchat/pip',
            );

  final MethodChannel _channel;
  bool? _supportedCache;

  /// Поддерживает ли платформа PiP-режим **в контексте текущей реализации**
  /// (не просто наличие API на уровне OS).
  Future<bool> isSupported() async {
    if (_supportedCache != null) return _supportedCache!;
    if (Platform.isAndroid) {
      // На Android Activity всегда умеет enterPictureInPictureMode при
      // выставленном android:supportsPictureInPicture в манифесте — а он у нас
      // выставлен. Метод-чек ниже валидирует наличие нативного handler'а.
      try {
        final v = await _channel.invokeMethod<bool>('isSupported');
        _supportedCache = v ?? false;
        appLogger.i('[meeting-pip] isSupported(android)=$_supportedCache');
      } catch (e) {
        appLogger.w('[meeting-pip] isSupported(android) failed', error: e);
        _supportedCache = false;
      }
      return _supportedCache!;
    }
    if (Platform.isIOS) {
      // iOS 15+ — нативный AVPictureInPictureController (см.
      // LighChatMeetingPipInlineBridge в AppDelegate.swift).
      try {
        final v = await _channel.invokeMethod<bool>('isSupported');
        _supportedCache = v ?? false;
        appLogger.i('[meeting-pip] isSupported(ios)=$_supportedCache');
      } catch (e) {
        appLogger.w('[meeting-pip] isSupported(ios) failed', error: e);
        _supportedCache = false;
      }
      return _supportedCache!;
    }
    _supportedCache = false;
    return false;
  }

  /// Войти в PiP-режим. Возвращает `true` при успехе.
  Future<bool> enterPip() async {
    final supported = await isSupported();
    appLogger.i('[meeting-pip] enterPip() requested, supported=$supported');
    if (!supported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('enter');
      appLogger.i('[meeting-pip] enterPip() result=$ok');
      return ok ?? false;
    } catch (e) {
      appLogger.w('[meeting-pip] enterPip() failed', error: e);
      return false;
    }
  }
}

/// Слушает жизненный цикл приложения и автоматически входит в PiP при
/// `AppLifecycleState.inactive` — т.е. когда пользователь свайпом сворачивает
/// приложение, открывает app switcher или нажимает home-кнопку.
///
/// Регистрируется в `initState` экрана конференции, снимается в `dispose`.
class PipLifecycleObserver with WidgetsBindingObserver {
  PipLifecycleObserver(this._controller);

  final MeetingPipController _controller;
  bool _autoPipEnabled = true;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // Если пользователь явно нажал PiP-кнопку — авто-режим уже не нужен,
  // не дублируем переход.
  void suppressAutoOnce() {
    _autoPipEnabled = false;
    Future<void>.delayed(const Duration(seconds: 5), () {
      _autoPipEnabled = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_autoPipEnabled) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Не ждём результат — если уже в PiP / не поддерживается, просто игнор.
      _controller.enterPip();
    }
  }
}
