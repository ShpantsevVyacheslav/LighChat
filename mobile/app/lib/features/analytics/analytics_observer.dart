import 'package:flutter/widgets.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';

/// NavigatorObserver, который шлёт `screen_view` при каждом push/pop/replace.
/// Подключается в GoRouter через `observers: [AnalyticsRouteObserver(service)]`.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._service);
  final AnalyticsService _service;

  String? _prevScreen;
  DateTime _prevTs = DateTime.now();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _report(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _report(previousRoute);
  }

  void _report(Route<dynamic> route) {
    final name = _routeName(route);
    if (name == null) return;

    final now = DateTime.now();
    final dtMs = now.difference(_prevTs).inMilliseconds;

    _service.logEvent(AnalyticsEvents.screenView, {
      'screen_name': name,
      'prev_screen': _prevScreen,
      'time_on_prev_ms': _prevScreen != null ? dtMs : 0,
    });

    _prevScreen = name;
    _prevTs = now;
  }

  String? _routeName(Route<dynamic> route) {
    final raw = route.settings.name;
    if (raw == null || raw.isEmpty) return null;
    // GoRouter передаёт полный путь — заменяем динамические сегменты на [id].
    return raw.split('/').map((seg) {
      if (seg.isEmpty) return seg;
      if (RegExp(r'^[0-9a-fA-F]{20,}$').hasMatch(seg)) return '[id]';
      if (RegExp(r'^[0-9]+$').hasMatch(seg)) return '[id]';
      return seg;
    }).join('/');
  }
}
