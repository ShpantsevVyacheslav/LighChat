import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'birthday_date_utils.dart';

/// In-memory флаг «плашка ДР скрыта на сегодня». НЕ персистится:
/// если пользователь полностью закрыл приложение и открыл заново —
/// плашка появляется снова (поведение, заказанное явно). Сбрасывается
/// также при смене календарного дня.
class BirthdayBannerDismissNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Скрыть плашку до конца текущего локального дня.
  void dismissForToday() {
    state = localYmd(DateTime.now());
  }

  /// `true`, если плашку уже скрыли сегодня.
  bool isDismissedToday() {
    final ymd = state;
    if (ymd == null) return false;
    return ymd == localYmd(DateTime.now());
  }
}

final birthdayBannerDismissProvider =
    NotifierProvider<BirthdayBannerDismissNotifier, String?>(
  BirthdayBannerDismissNotifier.new,
);
