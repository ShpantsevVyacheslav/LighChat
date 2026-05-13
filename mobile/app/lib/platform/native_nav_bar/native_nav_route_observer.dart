import 'package:flutter/widgets.dart';

/// Глобальный [RouteObserver] для виджетов, которые управляют нативной
/// nav-bar overlay (`ChatBottomNav`, `ChatHeader`, `NativeNavScaffold` и т.п.).
///
/// Подключается в `GoRouter(observers: [nativeNavRouteObserver])`. Виджеты,
/// которым нужна реакция на push/pop, реализуют [RouteAware] и
/// подписываются/отписываются в `didChangeDependencies` / `dispose`.
///
/// Контракт по использованию overlay'ев:
/// - `didPush` / `didPopNext` (виджет снова на вершине) → виджет
///   пушит свой `setTopBar` / `setBottomBar` через [NativeNavBarFacade].
/// - `didPushNext` / `didPop` (виджет уходит) → виджет пушит
///   `hidden` конфигурацию, чтобы overlay не «прилип» на следующем экране.
final RouteObserver<ModalRoute<Object?>> nativeNavRouteObserver =
    RouteObserver<ModalRoute<Object?>>();
