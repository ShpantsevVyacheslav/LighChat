import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:flutter/material.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

import '../data/chat_haptics.dart';
import '../data/local_entity_extractor.dart';
import '../data/user_profile.dart';
import 'calendar_picker_sheet.dart';
import 'navigator_picker_sheet.dart';

/// Ряд кликабельных «чипов» под сообщением — quick-actions для
/// распознанных сущностей.
///
/// Tap:
///  - phone → `tel:`, email → `mailto:`, url → browser, address → Maps,
///    flight → web search
/// Long-press:
///  - **date** → нативное «Добавить в календарь» с предзаполненными
///    title (из текста сообщения), startDate (из timestamp ML Kit) и
///    description (полный текст + список вложений)
class EntityChipsRow extends StatefulWidget {
  const EntityChipsRow({
    super.key,
    required this.text,
    required this.languageHint,
    required this.isMine,
    this.attachmentLabels = const <String>[],
    this.knownProfiles = const <UserProfile>[],
    this.forceDarkPanel = false,
  });

  final String text;
  final String languageHint;
  final bool isMine;

  /// `true` — чипы рендерятся на гарантированно тёмном фоне (например внутри
  /// voice attachment glass-panel). Тогда текст и иконки переключаются на
  /// белые с alpha, иначе они унаследовали бы scheme.onSurface (тёмный в
  /// light-теме → нечитаемо).
  final bool forceDarkPanel;

  /// Имена / краткие подписи вложений сообщения. Добавляются в description
  /// события календаря, чтобы пользователь видел контекст «к этому событию
  /// прикреплены такие-то файлы».
  final List<String> attachmentLabels;

  /// Известные профили (участники чата + контакты), у которых есть email.
  /// При long-press на дате ищем в тексте упомянутые имена и подставляем
  /// их email-ы в Event.invitees (Android) / description (iOS).
  ///
  /// Без сетевых запросов — берём из локальных моделей и кэша.
  final List<UserProfile> knownProfiles;

  @override
  State<EntityChipsRow> createState() => _EntityChipsRowState();
}

class _EntityChipsRowState extends State<EntityChipsRow> {
  List<EntityAnnotation>? _annotations;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant EntityChipsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.languageHint != widget.languageHint) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final res = await LocalEntityExtractor.instance.annotate(
      widget.text,
      languageHint: widget.languageHint,
    );
    if (!mounted) return;
    setState(() => _annotations = res);
  }

  @override
  Widget build(BuildContext context) {
    final ann = _annotations;
    if (ann == null || ann.isEmpty) return const SizedBox.shrink();

    // Подготовка: смерджим близко расположенные date+time аннотации в одну
    // (например ML Kit отдельно распознал «15 мая» и «15:00», в чате нужен
    // один чип «15 мая в 15:00» с точным timestamp).
    final merged = _mergeDateTimeAnnotations(ann, widget.text);

    final seen = <String>{};
    final chips = <_EntityChipData>[];
    for (final a in merged) {
      for (final e in a.entities) {
        final icon = _iconFor(e.type);
        if (icon == null) continue;
        final key = '${e.type.name}|${a.text}';
        if (!seen.add(key)) continue;
        chips.add(_EntityChipData(
          annotation: a,
          entity: e,
          icon: icon,
          color: entityTypeColor(e.type),
        ));
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips
            .map((c) => _EntityChip(
                  data: c,
                  isMine: widget.isMine,
                  forceDarkPanel: widget.forceDarkPanel,
                  onLongPressDate: c.entity.type == EntityType.dateTime
                      ? () => _addDateToCalendar(c)
                      : null,
                ))
            .toList(),
      ),
    );
  }

  Future<void> _addDateToCalendar(_EntityChipData c) async {
    final entity = c.entity;
    if (entity is! DateTimeEntity) return;
    await ChatHaptics.instance.longPress();
    final start = DateTime.fromMillisecondsSinceEpoch(entity.timestamp);
    // Гранулярность DAY → all-day event; иначе час по умолчанию.
    final allDay =
        entity.dateTimeGranularity == DateTimeGranularity.day ||
            entity.dateTimeGranularity == DateTimeGranularity.week ||
            entity.dateTimeGranularity == DateTimeGranularity.month ||
            entity.dateTimeGranularity == DateTimeGranularity.year;

    // 1) Длительность: «на 30 минут», «на 1.5 часа», «for 2 hours» — если
    //    нашли явное упоминание, переопределяем дефолтный 1 час.
    Duration? explicitDuration;
    if (!allDay) {
      explicitDuration = _parseDuration(widget.text);
    }
    final end = allDay
        ? start.add(const Duration(days: 1))
        : start.add(explicitDuration ?? const Duration(hours: 1));

    final location = _findAddress(_annotations);

    // 2) Участники: emails из ML Kit аннотаций + matched-by-name из
    //    knownProfiles. «давай созвонимся с Аней завтра» → в чате есть
    //    профиль «Богдашко Алина» с email alina.bogdashko@... → подставляем.
    //    Android: уходит в Intent.EXTRA_EMAIL (auto-invitees в Google Calendar).
    //    iOS: попадает в description (EKEventStore не разрешает программно).
    final attendees = <String>{
      ..._findEmails(_annotations),
      ..._matchProfilesByName(widget.text, widget.knownProfiles),
    }.toList(growable: false);

    // 3) Повторение: detect by keyword («каждый день/неделю/месяц/год»,
    //    «daily/weekly/monthly/yearly», «every Monday», «по пятницам»).
    final recurrence = _parseRecurrence(widget.text);

    final title = _buildTitle(
      widget.text,
      excerpts: [c.annotation.text, ?location],
    );
    final description = _buildDescription(
      widget.text,
      widget.attachmentLabels,
      attendees: attendees,
      recurrence: recurrence,
      duration: explicitDuration,
    );

    final event = cal.Event(
      title: title,
      description: description.isEmpty ? null : description,
      location: location,
      startDate: start,
      endDate: end,
      allDay: allDay,
      recurrence: recurrence,
      // Android: emails сразу пробрасываются в поле «Гости» Google Calendar
      // через Intent.EXTRA_EMAIL. iOS — EKEventStore не даёт программно
      // добавлять invitees, остаются только в description.
      androidParams: cal.AndroidParams(
        emailInvites: attendees.isEmpty ? null : attendees,
      ),
    );
    if (!mounted) return;
    await CalendarPickerSheet.show(context: context, event: event);
  }

  /// Ищем в тексте сообщения упоминания участников из [profiles] по имени.
  /// Возвращаем email-ы тех, чьё имя нашлось хотя бы по одному токену.
  /// Token = первое слово, второе слово, etc. — чтобы «Аня» матчилось
  /// с «Анна Иванова» (если первый токен «Анна» начинается с того же
  /// корня) и «Иванова» матчилось с фамилией.
  static List<String> _matchProfilesByName(
    String text,
    List<UserProfile> profiles,
  ) {
    if (profiles.isEmpty) return const [];
    final lower = text.toLowerCase();
    // Делим текст на слова (буквы Unicode), чтобы матчить по границе слова.
    final words = lower
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.length >= 3)
        .toSet();
    if (words.isEmpty) return const [];
    final out = <String>{};
    for (final p in profiles) {
      final email = (p.email ?? '').trim();
      if (email.isEmpty) continue;
      final tokens = p.name
          .toLowerCase()
          .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
          .where((t) => t.length >= 3)
          .toList();
      // Полное совпадение хотя бы одного из имён/фамилий — добавляем.
      // Игнорируем «короткие хвосты» (≤2 символа) чтобы избежать ложных
      // срабатываний на «и», «ом» и т.п.
      final matched = tokens.any((t) => words.contains(t));
      if (matched) out.add(email);
    }
    return out.toList(growable: false);
  }

  /// Извлекает email-адреса из аннотаций ML Kit.
  static List<String> _findEmails(List<EntityAnnotation>? annotations) {
    if (annotations == null) return const [];
    final out = <String>{};
    for (final a in annotations) {
      for (final e in a.entities) {
        if (e.type == EntityType.email) out.add(a.text.trim());
      }
    }
    return out.toList(growable: false);
  }

  /// Парсим длительность из текста сообщения:
  ///  - «на 30 минут / 30 мин / 30 min»
  ///  - «на 2 часа / 1.5 часа / 2 hours / 1h»
  /// Возвращаем `null` если ничего не нашли.
  static Duration? _parseDuration(String text) {
    final lower = text.toLowerCase();
    // часы (с десятичной точкой/запятой): «на 1.5 часа», «for 2 hours»
    final hours = RegExp(
      r'(?:на|for|in|in)?\s*(\d+(?:[.,]\d+)?)\s*(?:час(?:а|ов|у)?|ч|hours?|hrs?|h)\b',
    ).firstMatch(lower);
    if (hours != null) {
      final v = double.tryParse(hours.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0 && v < 24) {
        return Duration(milliseconds: (v * 3600 * 1000).round());
      }
    }
    // минуты
    final mins = RegExp(
      r'(?:на|for)?\s*(\d+)\s*(?:минут(?:ы|у)?|мин|minutes?|mins?|m)\b',
    ).firstMatch(lower);
    if (mins != null) {
      final v = int.tryParse(mins.group(1)!);
      if (v != null && v > 0 && v < 24 * 60) {
        return Duration(minutes: v);
      }
    }
    return null;
  }

  /// Парсим recurrence из текста: «каждый день / каждую неделю /
  /// ежемесячно / по понедельникам / every day / weekly».
  static cal.Recurrence? _parseRecurrence(String text) {
    final lower = text.toLowerCase();
    // Daily
    if (RegExp(
      r'\b(?:каждый\s+день|ежедневно|каждое\s+утро|каждый\s+вечер|every\s+day|daily)\b',
    ).hasMatch(lower)) {
      return cal.Recurrence(frequency: cal.Frequency.daily);
    }
    // Weekly: «каждую неделю», «еженедельно», «по понедельникам/вторникам…»,
    // «every monday», «every week», «weekly».
    if (RegExp(
      r'\b(?:каждую\s+неделю|еженедельно|по\s+(?:понедельникам|вторникам|средам|четвергам|пятницам|субботам|воскресеньям)|every\s+(?:week|monday|tuesday|wednesday|thursday|friday|saturday|sunday)|weekly)\b',
    ).hasMatch(lower)) {
      return cal.Recurrence(frequency: cal.Frequency.weekly);
    }
    // Monthly
    if (RegExp(
      r'\b(?:каждый\s+месяц|ежемесячно|every\s+month|monthly)\b',
    ).hasMatch(lower)) {
      return cal.Recurrence(frequency: cal.Frequency.monthly);
    }
    // Yearly
    if (RegExp(
      r'\b(?:каждый\s+год|ежегодно|every\s+year|yearly|annually)\b',
    ).hasMatch(lower)) {
      return cal.Recurrence(frequency: cal.Frequency.yearly);
    }
    return null;
  }

  /// Сливаем подряд идущие DateTime-аннотации в одну. ML Kit может вернуть
  /// «15 мая» и «15:00» отдельными матчами с разной granularity. Если в
  /// исходном тексте между ними ≤6 символов (типичный союз/пробел «в»,
  /// «,», «—»), мерджим:
  ///  - display = подстрока из min(start)..max(end)
  ///  - timestamp = из той аннотации, чья granularity мельче (минуты/секунды
  ///    предпочтительнее дня)
  ///  - granularity = более точная из двух
  static List<EntityAnnotation> _mergeDateTimeAnnotations(
    List<EntityAnnotation> input,
    String text,
  ) {
    if (input.length < 2) return input;
    final sorted = [...input]..sort((a, b) => a.start.compareTo(b.start));
    final out = <EntityAnnotation>[];
    EntityAnnotation? pending;
    for (final a in sorted) {
      if (pending == null) {
        pending = a;
        continue;
      }
      final pendingIsDate =
          pending.entities.any((e) => e.type == EntityType.dateTime);
      final currentIsDate =
          a.entities.any((e) => e.type == EntityType.dateTime);
      final gap = a.start - pending.end;
      if (pendingIsDate && currentIsDate && gap >= 0 && gap <= 6) {
        // Берём ту дату, чья granularity мельче (точное время > день).
        final pendingDt = pending.entities.whereType<DateTimeEntity>().first;
        final currentDt = a.entities.whereType<DateTimeEntity>().first;
        final betterEntity = _isFinerGranularity(
          currentDt.dateTimeGranularity,
          pendingDt.dateTimeGranularity,
        )
            ? currentDt
            : pendingDt;
        // А вот timestamp лучше брать комбинированный: дата из «дневной»
        // аннотации + время из той, что с timeOfDay. ML Kit уже комбинирует
        // это в одном из них (тот, что точнее), поэтому просто берём better.
        final newStart = pending.start < a.start ? pending.start : a.start;
        final newEnd = pending.end > a.end ? pending.end : a.end;
        final newText =
            newStart >= 0 && newEnd <= text.length && newStart < newEnd
                ? text.substring(newStart, newEnd)
                : '${pending.text} ${a.text}';
        pending = EntityAnnotation(
          start: newStart,
          end: newEnd,
          text: newText,
          entities: <Entity>[betterEntity],
        );
      } else {
        out.add(pending);
        pending = a;
      }
    }
    if (pending != null) out.add(pending);
    return out;
  }

  static bool _isFinerGranularity(
    DateTimeGranularity a,
    DateTimeGranularity b,
  ) {
    // Чем меньше index в enum, тем мельче (секунды первыми).
    return a.index < b.index;
  }

  /// Ищем в списке аннотаций первую с типом `address`. Если найдена —
  /// возвращаем её raw-текст для использования как `location` события.
  static String? _findAddress(List<EntityAnnotation>? annotations) {
    if (annotations == null) return null;
    for (final a in annotations) {
      for (final e in a.entities) {
        if (e.type == EntityType.address) return a.text.trim();
      }
    }
    return null;
  }

  /// Берём текст сообщения, вычёркиваем матчи даты и адреса (если есть) —
  /// остаток становится заголовком события. Если ничего не осталось —
  /// fallback на «Событие».
  static String _buildTitle(
    String fullText, {
    required List<String> excerpts,
  }) {
    var t = fullText;
    for (final e in excerpts) {
      if (e.isEmpty) continue;
      t = t.replaceFirst(e, '');
    }
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Trim хвостовые предлоги-связки типа «в», «на», «у» — после удаления
    // адреса/даты они часто остаются висеть.
    t = t.replaceAll(
      RegExp(r'(?:\s*[,;\-—]+\s*)+$|^(?:\s*[,;\-—]+\s*)+'),
      '',
    );
    if (t.isEmpty) return 'Событие';
    if (t.length > 100) t = '${t.substring(0, 97)}…';
    return t;
  }

  static String _buildDescription(
    String fullText,
    List<String> attachments, {
    List<String> attendees = const [],
    cal.Recurrence? recurrence,
    Duration? duration,
  }) {
    final buf = StringBuffer();
    final trimmed = fullText.trim();
    if (trimmed.isNotEmpty) buf.writeln(trimmed);

    if (attendees.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln();
      buf.writeln('Участники:');
      for (final a in attendees) {
        buf.writeln('— $a');
      }
    }

    if (recurrence != null) {
      if (buf.isNotEmpty) buf.writeln();
      buf.writeln('Повтор: ${_recurrenceLabel(recurrence.frequency)}');
    }

    if (duration != null) {
      if (buf.isNotEmpty) buf.writeln();
      final mins = duration.inMinutes;
      final h = mins ~/ 60;
      final m = mins % 60;
      final parts = <String>[];
      if (h > 0) parts.add('$h ч');
      if (m > 0) parts.add('$m мин');
      buf.writeln('Длительность: ${parts.join(' ')}');
    }

    if (attachments.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln();
      buf.writeln('Вложения:');
      for (final a in attachments) {
        buf.writeln('— $a');
      }
    }
    return buf.toString().trim();
  }

  static String _recurrenceLabel(cal.Frequency? f) {
    switch (f) {
      case cal.Frequency.daily:
        return 'ежедневно';
      case cal.Frequency.weekly:
        return 'еженедельно';
      case cal.Frequency.monthly:
        return 'ежемесячно';
      case cal.Frequency.yearly:
        return 'ежегодно';
      case null:
        return 'разово';
    }
  }

  IconData? _iconFor(EntityType t) {
    switch (t) {
      case EntityType.phone:
        return Icons.call_rounded;
      case EntityType.email:
        return Icons.mail_outline_rounded;
      case EntityType.address:
        return Icons.location_on_outlined;
      case EntityType.dateTime:
        return Icons.event_outlined;
      case EntityType.url:
        return Icons.open_in_new_rounded;
      case EntityType.flightNumber:
        return Icons.flight_takeoff_rounded;
      case EntityType.iban:
        return Icons.account_balance_outlined;
      case EntityType.trackingNumber:
        return Icons.local_shipping_outlined;
      default:
        return null;
    }
  }
}

class _EntityChipData {
  const _EntityChipData({
    required this.annotation,
    required this.entity,
    required this.icon,
    required this.color,
  });
  final EntityAnnotation annotation;
  final Entity entity;
  final IconData icon;
  final Color color;
}

class _EntityChip extends StatelessWidget {
  const _EntityChip({
    required this.data,
    required this.isMine,
    required this.onLongPressDate,
    this.forceDarkPanel = false,
  });

  final _EntityChipData data;
  final bool isMine;
  final bool forceDarkPanel;

  /// Long-press handler — только для date-чипов. На остальных `null`.
  /// Async чтобы вызывающий мог дождаться закрытия CalendarPickerSheet
  /// и не сбросить `_actionInFlight` гард досрочно.
  final Future<void> Function()? onLongPressDate;

  /// Глобальный guard от множественных тапов: если юзер быстро жмёт по
  /// чипу адреса/даты несколько раз подряд (или по разным чипам подряд),
  /// без него каждый тап открывал свой инстанс NavigatorPicker /
  /// CalendarPicker / launchEntity — стек шторок наложенных друг на
  /// друга. Флаг ставится при первом тапе и сбрасывается **только** когда
  /// открытое действие завершилось (sheet закрылся, launch вернулся).
  static bool _actionInFlight = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // На тёмной glass-панели (voice attachment) принудительно белый, иначе
    // нечитаемо в light-теме. В обычном bubble — следуем colorScheme.
    final fg = forceDarkPanel
        ? Colors.white
        : (isMine ? scheme.onPrimary : scheme.onSurface);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_actionInFlight) return;
          _actionInFlight = true;
          try {
            await ChatHaptics.instance.tick();
            // Адрес → picker навигатора (Apple Maps / Google Maps /
            // Яндекс Карты/Навигатор / 2ГИС / Waze + такси).
            if (data.entity.type == EntityType.address) {
              if (!context.mounted) return;
              await NavigatorPickerSheet.show(
                context: context,
                address: data.annotation.text,
              );
              return;
            }
            // Дата → picker календарей (Apple / Google / Яндекс /
            // Outlook). Изначально это было на long-press, но юзеры
            // ожидают что основное действие — тап.
            if (data.entity.type == EntityType.dateTime &&
                onLongPressDate != null) {
              await onLongPressDate!();
              return;
            }
            await LocalEntityExtractor.instance.launchEntity(data.annotation);
          } finally {
            _actionInFlight = false;
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: data.color.withValues(alpha: 0.36),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 13, color: data.color),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  data.annotation.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg.withValues(alpha: 0.92),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
