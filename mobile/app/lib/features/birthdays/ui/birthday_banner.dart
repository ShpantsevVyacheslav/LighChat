import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/brand_colors.dart';
import 'package:lighchat_mobile/features/birthdays/data/birthday_banner_dismiss.dart';
import 'package:lighchat_mobile/features/birthdays/data/contact_birthday.dart';
import 'package:lighchat_mobile/features/birthdays/data/contact_birthdays_provider.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_avatar.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

/// Плашка над списком чатов: "{Имя} празднует день рождения!". Показывается
/// только в день ДР и только если есть хотя бы один именинник среди
/// контактов. При нескольких именинниках перелистывает их каждые 4 секунды.
/// Скрывается тапом по ✕ — только в рамках текущего запуска приложения
/// (in-memory). После полного закрытия и повторного открытия — появляется
/// снова, пока пользователь не закроет её ещё раз.
class BirthdayBanner extends ConsumerStatefulWidget {
  const BirthdayBanner({super.key});

  @override
  ConsumerState<BirthdayBanner> createState() => _BirthdayBannerState();
}

class _BirthdayBannerState extends ConsumerState<BirthdayBanner> {
  int _index = 0;
  Timer? _rotation;

  void _restartRotation(int total) {
    _rotation?.cancel();
    if (total <= 1) return;
    _rotation = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % total;
      });
    });
  }

  void _dismissForToday() {
    ref.read(birthdayBannerDismissProvider.notifier).dismissForToday();
  }

  @override
  void dispose() {
    _rotation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authUserProvider);
    final user = authAsync.value;
    if (user == null) return const SizedBox.shrink();

    final birthdays = ref.watch(todayBirthdaysProvider(user.uid));
    if (birthdays.isEmpty) return const SizedBox.shrink();

    final dismissed = ref
        .watch(birthdayBannerDismissProvider.notifier)
        .isDismissedToday();
    // watch также сам state, чтобы перестроиться при изменении.
    ref.watch(birthdayBannerDismissProvider);
    if (dismissed) return const SizedBox.shrink();

    // Поддерживаем валидный _index при изменении длины списка.
    final safeIndex = birthdays.isEmpty ? 0 : _index % birthdays.length;
    _restartRotation(birthdays.length);

    final current = birthdays[safeIndex];
    final extras = birthdays.length - 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -8),
          child: child,
        ),
      ),
      child: _BannerCard(
        current: current,
        extrasCount: extras,
        onTap: () => context.push('/birthdays'),
        onDismiss: _dismissForToday,
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.current,
    required this.extrasCount,
    required this.onTap,
    required this.onDismiss,
  });

  final ContactBirthday current;
  final int extrasCount;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kBrandOrange.withValues(alpha: isDark ? 0.18 : 0.16),
                kBrandOrange.withValues(alpha: isDark ? 0.06 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: kBrandOrange.withValues(alpha: 0.25),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Hero(
                    tag: 'birthday-avatar-${current.userId}',
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ChatAvatar(
                            title: current.displayName,
                            radius: 18,
                            avatarUrl: current.avatarThumb ?? current.avatarUrl,
                          ),
                          const Positioned(
                            right: -4,
                            bottom: -4,
                            child: Text('🎂',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(anim);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                              position: slide, child: child),
                        );
                      },
                      child: Column(
                        key: ValueKey<String>(current.userId),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                              children: [
                                TextSpan(
                                  text: current.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                    text:
                                        ' ${l10n.birthday_banner_celebrates}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            l10n.birthday_banner_action,
                            style: TextStyle(
                              fontSize: 12,
                              color: kBrandOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (extrasCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBrandOrange.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+$extrasCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : kBrandOrange,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
