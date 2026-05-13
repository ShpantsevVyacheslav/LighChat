import 'package:flutter/widgets.dart';

import 'native_nav_bar_facade.dart';

/// Глобальный [RouteObserver] для виджетов, которые управляют нативной
/// nav-bar overlay (`ChatBottomNav`, `ChatHeader`, `NativeNavScaffold` и т.п.).
///
/// Подключается в `GoRouter(observers: [nativeNavRouteObserver])`. Виджеты,
/// которым нужна реакция на push/pop, реализуют [RouteAware] и
/// подписываются/отписываются в `didChangeDependencies` / `dispose`.
///
/// Контракт:
/// - На каждом переходе (push / pop / replace) сам observer вызывает
///   [NativeNavBarFacade.hideAll] **до** уведомления подписчиков. Это
///   гарантирует, что новый экран начинает с чистой overlay-областью.
/// - Подписчики (виджет-владелец native bar) перепушивают свой config:
///   * в `initState` через postFrameCallback (первичный mount, RouteObserver
///     не присылает didPush ретроспективно),
///   * в `didPopNext` (вернулись на вершину после pop'a верхнего экрана).
/// - Виджет НЕ должен сам шлёть hidden в dispose / didPushNext — observer
///   решает это раньше, и dispose-hide ловит race-condition с анимацией
///   перехода (dispose откладывается до конца transition).
class _NativeNavRouteObserver extends RouteObserver<ModalRoute<Object?>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NativeNavBarFacade.instance.hideAll();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NativeNavBarFacade.instance.hideAll();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    NativeNavBarFacade.instance.hideAll();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NativeNavBarFacade.instance.hideAll();
    super.didRemove(route, previousRoute);
  }
}

final RouteObserver<ModalRoute<Object?>> nativeNavRouteObserver =
    _NativeNavRouteObserver();
