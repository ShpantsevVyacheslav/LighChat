import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../l10n/app_localizations.dart';
import '../data/chat_haptics.dart';

/// Premium bottom-sheet выбора приложения для создания события из чата.
///
/// Опции:
///  - **Системный календарь** — Apple Calendar (iOS) / Google Calendar
///    (Android) через add_2_calendar Intent. Пользователь сам в EventKit
///    UI выбирает iCloud / Google / Outlook / Yandex (CalDAV).
///  - **Google Calendar (web)** — открывает calendar.google.com с
///    предзаполненными параметрами через `render?action=TEMPLATE`.
///    Полезно если у юзера несколько Google-аккаунтов: на сайте можно
///    выбрать нужный.
///  - **Яндекс.Календарь (web)** — calendar.yandex.ru с похожим deeplink.
///  - **Outlook (web)** — outlook.office.com compose-deeplink.
class CalendarPickerSheet {
  CalendarPickerSheet._();

  static Future<void> show({
    required BuildContext context,
    required cal.Event event,
  }) async {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _PickerContent(event: event),
    );
  }
}

class _PickerContent extends StatelessWidget {
  const _PickerContent({required this.event});
  final cal.Event event;

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? const Color(0xFF15171C) : const Color(0xFFF5F6F8);
    final fg = isDark ? const Color(0xFFEDEEF2) : const Color(0xFF14161A);
    final fgMuted = isDark
        ? const Color(0xFFA0A4AD)
        : const Color(0xFF5C6470);
    final cardBg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final border = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: bg.withValues(alpha: 0.96),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: fgMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Заголовок: иконка над текстом, всё центрировано —
                  // визуально симметричный header без «прижатого влево»
                  // выравнивания.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          size: 18,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.calendar_picker_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: fgMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CalendarTile(
                    icon: Icons.event_available_rounded,
                    iconColor: Platform.isIOS
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF1A73E8),
                    label: Platform.isIOS
                        ? 'Apple Calendar'
                        : 'Google Calendar',
                    subtitle: l10n.calendar_picker_native_subtitle,
                    cardBg: cardBg,
                    border: border,
                    fg: fg,
                    fgMuted: fgMuted,
                    assetPath: 'assets/services/calendar.svg',
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      unawaited(ChatHaptics.instance.selectionChanged());
                      try {
                        await cal.Add2Calendar.addEvent2Cal(event);
                        unawaited(ChatHaptics.instance.success());
                      } catch (_) {
                        unawaited(ChatHaptics.instance.error());
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _CalendarTile(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF1A73E8),
                    label: 'Google Calendar',
                    subtitle: l10n.calendar_picker_web_subtitle,
                    cardBg: cardBg,
                    border: border,
                    fg: fg,
                    fgMuted: fgMuted,
                    assetPath: 'assets/services/calendar.svg',
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      unawaited(ChatHaptics.instance.selectionChanged());
                      await _launchUrl(_buildGoogleUrl(event));
                    },
                  ),
                  const SizedBox(height: 8),
                  _CalendarTile(
                    icon: Icons.event_note_rounded,
                    iconColor: const Color(0xFFFF3333),
                    label: 'Яндекс Календарь',
                    subtitle: l10n.calendar_picker_web_subtitle,
                    cardBg: cardBg,
                    border: border,
                    fg: fg,
                    fgMuted: fgMuted,
                    assetPath: 'assets/services/calendar.svg',
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      unawaited(ChatHaptics.instance.selectionChanged());
                      await _launchUrl(_buildYandexUrl(event));
                    },
                  ),
                  const SizedBox(height: 8),
                  _CalendarTile(
                    icon: Icons.business_rounded,
                    iconColor: const Color(0xFF0078D4),
                    label: 'Outlook',
                    subtitle: l10n.calendar_picker_web_subtitle,
                    cardBg: cardBg,
                    border: border,
                    fg: fg,
                    fgMuted: fgMuted,
                    assetPath: 'assets/services/calendar.svg',
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      unawaited(ChatHaptics.instance.selectionChanged());
                      await _launchUrl(_buildOutlookUrl(event));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  /// `YYYYMMDDTHHmmssZ` для Google/Yandex/Outlook URL templates.
  static String _fmtUtc(DateTime dt) {
    final u = dt.toUtc();
    final s = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(u);
    return s;
  }

  /// `YYYYMMDD` для all-day.
  static String _fmtDay(DateTime dt) {
    return DateFormat('yyyyMMdd').format(dt);
  }

  static String _buildGoogleUrl(cal.Event e) {
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': e.title,
      'dates': e.allDay
          ? '${_fmtDay(e.startDate)}/${_fmtDay(e.endDate)}'
          : '${_fmtUtc(e.startDate)}/${_fmtUtc(e.endDate)}',
    };
    if (e.description != null && e.description!.isNotEmpty) {
      params['details'] = e.description!;
    }
    if (e.location != null && e.location!.isNotEmpty) {
      params['location'] = e.location!;
    }
    final q = params.entries
        .map((m) =>
            '${Uri.encodeQueryComponent(m.key)}=${Uri.encodeQueryComponent(m.value)}')
        .join('&');
    return 'https://calendar.google.com/calendar/render?$q';
  }

  static String _buildYandexUrl(cal.Event e) {
    // Yandex Calendar event create endpoint принимает date/time/duration
    // в локальной таймзоне. Формат:
    //  https://calendar.yandex.ru/event/new?
    //    name=TITLE
    //    &date=YYYY-MM-DD            (local date)
    //    &time_start=HH:MM
    //    &time_end=HH:MM
    //    &place=LOCATION
    //    &description=DESCR
    final start = e.startDate;
    final end = e.endDate;
    final dateStr =
        '${start.year.toString().padLeft(4, '0')}'
        '-${start.month.toString().padLeft(2, '0')}'
        '-${start.day.toString().padLeft(2, '0')}';
    final params = <String, String>{
      'name': e.title,
      'date': dateStr,
    };
    if (!e.allDay) {
      params['time_start'] =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      params['time_end'] =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    }
    if (e.description != null && e.description!.isNotEmpty) {
      params['description'] = e.description!;
    }
    if (e.location != null && e.location!.isNotEmpty) {
      params['place'] = e.location!;
    }
    final q = params.entries
        .map((m) =>
            '${Uri.encodeQueryComponent(m.key)}=${Uri.encodeQueryComponent(m.value)}')
        .join('&');
    return 'https://calendar.yandex.ru/event/new?$q';
  }

  static String _buildOutlookUrl(cal.Event e) {
    final params = <String, String>{
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': e.title,
      'startdt': e.startDate.toUtc().toIso8601String(),
      'enddt': e.endDate.toUtc().toIso8601String(),
      'allday': e.allDay ? 'true' : 'false',
    };
    if (e.description != null && e.description!.isNotEmpty) {
      params['body'] = e.description!;
    }
    if (e.location != null && e.location!.isNotEmpty) {
      params['location'] = e.location!;
    }
    final q = params.entries
        .map((m) =>
            '${Uri.encodeQueryComponent(m.key)}=${Uri.encodeQueryComponent(m.value)}')
        .join('&');
    return 'https://outlook.office.com/calendar/0/deeplink/compose?$q';
  }
}

class _CalendarTile extends StatefulWidget {
  const _CalendarTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.cardBg,
    required this.border,
    required this.fg,
    required this.fgMuted,
    required this.onTap,
    this.assetPath,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final Color cardBg;
  final Color border;
  final Color fg;
  final Color fgMuted;
  final Future<void> Function() onTap;

  /// Опциональный путь к брендовой иконке в assets/services/.
  /// Если файл отсутствует — рисуем Material [icon] как fallback.
  final String? assetPath;

  @override
  State<_CalendarTile> createState() => _CalendarTileState();
}

class _CalendarTileState extends State<_CalendarTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.border, width: 1),
            ),
            child: Row(
              children: [
                _CalendarServiceLogo(
                  assetPath: widget.assetPath,
                  fallbackIcon: widget.icon,
                  fallbackColor: widget.iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: widget.fg,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: widget.fg.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Логотип сервиса 40×40 для calendar-picker. Грузит PNG из
/// assets/services/, при отсутствии файла рисует Material иконку.
class _CalendarServiceLogo extends StatelessWidget {
  const _CalendarServiceLogo({
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  final String? assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) return _fallback();
    final isSvg = assetPath!.toLowerCase().endsWith('.svg');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: isSvg
            ? SvgPicture.asset(
                assetPath!,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => _fallback(),
              )
            : Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: fallbackColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: fallbackColor, size: 22),
    );
  }
}
