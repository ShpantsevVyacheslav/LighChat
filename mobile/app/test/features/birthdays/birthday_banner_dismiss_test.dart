import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/birthdays/data/birthday_banner_dismiss.dart';

void main() {
  test('starts as not dismissed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final n = container.read(birthdayBannerDismissProvider.notifier);
    expect(n.isDismissedToday(), isFalse);
    expect(container.read(birthdayBannerDismissProvider), isNull);
  });

  test('dismissForToday sets isDismissedToday true within same day', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final n = container.read(birthdayBannerDismissProvider.notifier);
    n.dismissForToday();
    expect(n.isDismissedToday(), isTrue);
    expect(container.read(birthdayBannerDismissProvider), isNotNull);
  });

  test('fresh container after restart sees no dismiss (in-memory only)', () {
    // Симуляция «перезапуска приложения»: новый ProviderContainer = новое
    // состояние. Поведение по задаче: dismiss НЕ персистится.
    final c1 = ProviderContainer();
    c1.read(birthdayBannerDismissProvider.notifier).dismissForToday();
    expect(
      c1.read(birthdayBannerDismissProvider.notifier).isDismissedToday(),
      isTrue,
    );
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(
      c2.read(birthdayBannerDismissProvider.notifier).isDismissedToday(),
      isFalse,
    );
  });
}
