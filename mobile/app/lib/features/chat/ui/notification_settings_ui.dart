import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Типографика и карточки экрана «Уведомления» (общие и для одного чата).
const double kNotificationSettingsHeaderTitleSize = 16;
const double kNotificationSettingsCardTitleSize = 18;
const double kNotificationSettingsBodyTextSize = 14;
const double kNotificationSettingsMutedTextSize = 13;

class NotificationSettingsPageHeader extends StatelessWidget {
  const NotificationSettingsPageHeader({
    super.key,
    required this.title,
    this.leadingIcon = Icons.notifications_none_rounded,
    this.iconColor = const Color(0xFF4DA2FF),
    this.onBack,
  });

  final String title;
  final IconData leadingIcon;
  final Color iconColor;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final titleColor = dark
        ? Colors.white.withValues(alpha: 0.95)
        : scheme.onSurface.withValues(alpha: 0.94);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: (dark ? Colors.white : scheme.surface).withValues(
              alpha: dark ? 0.08 : 0.74,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap:
                  onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/account');
                    }
                  },
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: titleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Icon(leadingIcon, color: iconColor, size: 30),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: kNotificationSettingsHeaderTitleSize,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsMutedBanner extends StatelessWidget {
  const NotificationSettingsMutedBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.56)
        : scheme.onSurface.withValues(alpha: 0.62);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.35 : 0.55,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: kNotificationSettingsMutedTextSize,
            color: subtitleColor,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: (dark ? const Color(0xFF0D121A) : scheme.surfaceContainerLow)
            .withValues(alpha: dark ? 0.78 : 0.92),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.14 : 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: kNotificationSettingsCardTitleSize,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: dark ? 0.95 : 0.94),
              ),
            ),
          ),
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: kNotificationSettingsMutedTextSize,
                  color: fg.withValues(alpha: dark ? 0.52 : 0.60),
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

class NotificationSettingsSwitchRow extends StatelessWidget {
  const NotificationSettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.disabled = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: kNotificationSettingsBodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: disabled
                        ? fg.withValues(alpha: dark ? 0.42 : 0.42)
                        : fg.withValues(alpha: dark ? 0.95 : 0.94),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: kNotificationSettingsMutedTextSize,
                      color: disabled
                          ? fg.withValues(alpha: dark ? 0.32 : 0.38)
                          : fg.withValues(alpha: dark ? 0.56 : 0.62),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2F86FF),
            inactiveThumbColor: (dark ? Colors.white : scheme.surface)
                .withValues(alpha: dark ? 0.9 : 1),
            inactiveTrackColor: (dark ? Colors.white : scheme.onSurface)
                .withValues(alpha: dark ? 0.2 : 0.2),
          ),
        ],
      ),
    );
  }
}
