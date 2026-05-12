import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app_bootstrap.dart' show logger;
import 'analytics_service.dart';

/// Корневой провайдер для аналитики. Создаёт sink, подходящий для текущей
/// платформы: `FirebaseAnalyticsSink` для iOS/Android/macOS,
/// `CallableAnalyticsSink` для Windows/Linux (где firebase_analytics не работает).
///
/// Замечание: Dart compiler на Windows (через flutter_assemble в MSBuild)
/// падает с `Final variable 'sink' might already be assigned` если sink
/// создаётся через closure-with-try внутри Provider builder. Поэтому
/// используем плоский inline-вариант с условным выражением.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  AnalyticsSink sink;
  try {
    sink = platformSupportsFirebaseAnalytics()
        ? FirebaseAnalyticsSink(FirebaseAnalytics.instance, logger)
        : CallableAnalyticsSink(FirebaseFunctions.instance, logger);
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
