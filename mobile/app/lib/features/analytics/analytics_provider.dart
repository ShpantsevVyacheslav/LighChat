import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app_bootstrap.dart' show logger;
import 'analytics_service.dart';

/// Корневой провайдер для аналитики. Создаёт sink, подходящий для текущей
/// платформы: `FirebaseAnalyticsSink` для iOS/Android/macOS,
/// `CallableAnalyticsSink` для Windows/Linux (где firebase_analytics не работает).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final AnalyticsSink sink;
  try {
    if (platformSupportsFirebaseAnalytics()) {
      sink = FirebaseAnalyticsSink(FirebaseAnalytics.instance, logger);
    } else {
      sink = CallableAnalyticsSink(FirebaseFunctions.instance, logger);
    }
  } catch (e) {
    Logger().d('analytics provider fallback to noop: $e');
    sink = NoopAnalyticsSink();
  }
  return AnalyticsService(sink: sink, logger: logger);
});

/// Удобный shortcut для логирования: `ref.read(trackEventProvider)('login', {...})`.
final trackEventProvider = Provider((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return (String name, Map<String, Object?> params) => service.logEvent(name, params);
});
