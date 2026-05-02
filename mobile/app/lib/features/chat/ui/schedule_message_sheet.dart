import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// Bottom-sheet для выбора даты/времени отложенного сообщения.
/// Возвращает [DateTime] (в локальной TZ) — конвертация в UTC ISO выполняется
/// в репозитории. Возвращает null при отмене.
///
/// Параметр [initialSendAt] предзаполняет (используется в режиме «Изменить
/// время»). [showE2eeWarning] показывает баннер про plaintext-публикацию.
Future<DateTime?> showScheduleMessageSheet({
  required BuildContext context,
  DateTime? initialSendAt,
  bool showE2eeWarning = false,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final dark = scheme.brightness == Brightness.dark;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          left: 12,
          right: 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: (dark ? const Color(0xFF0D1A24) : Colors.white).withValues(
                alpha: dark ? 0.78 : 0.92,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.16 : 0.42),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: _ScheduleMessageSheetContent(
                  initialSendAt: initialSendAt,
                  showE2eeWarning: showE2eeWarning,
                  onCancel: () => Navigator.of(ctx).pop(),
                  onConfirm: (dt) => Navigator.of(ctx).pop(dt),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ScheduleMessageSheetContent extends StatefulWidget {
  const _ScheduleMessageSheetContent({
    required this.initialSendAt,
    required this.showE2eeWarning,
    required this.onCancel,
    required this.onConfirm,
  });

  final DateTime? initialSendAt;
  final bool showE2eeWarning;
  final VoidCallback onCancel;
  final void Function(DateTime sendAt) onConfirm;

  @override
  State<_ScheduleMessageSheetContent> createState() =>
      _ScheduleMessageSheetContentState();
}

class _ScheduleMessageSheetContentState
    extends State<_ScheduleMessageSheetContent> {
  static const Duration _minLead = Duration(minutes: 1);

  late DateTime _now;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    final init = widget.initialSendAt ?? _now.add(const Duration(hours: 1));
    _selected = init.isBefore(_now.add(_minLead))
        ? _now.add(const Duration(hours: 1))
        : init;
  }

  bool get _isInPast => _selected.isBefore(_now.add(_minLead));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(_now.year, _now.month, _now.day),
      lastDate: _now.add(const Duration(days: 365 * 5)),
      initialDate: _selected,
      locale: Localizations.localeOf(context),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _applyPreset(DateTime at) {
    setState(() {
      _selected = at;
    });
  }

  List<({String label, DateTime? at})> _presets(AppLocalizations l10n) {
    final today18 = DateTime(_now.year, _now.month, _now.day, 18, 0);
    final tomorrow = _now.add(const Duration(days: 1));
    final tomorrow09 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    final tomorrow18 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
    return [
      (
        label: l10n.schedule_message_preset_today_at('18:00'),
        at: today18.isAfter(_now.add(_minLead)) ? today18 : null,
      ),
      (
        label: l10n.schedule_message_preset_tomorrow_at('09:00'),
        at: tomorrow09,
      ),
      (
        label: l10n.schedule_message_preset_tomorrow_at('18:00'),
        at: tomorrow18,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat('d MMMM yyyy', localeTag);
    final timeFmt = DateFormat('HH:mm', localeTag);
    final fg = dark
        ? Colors.white.withValues(alpha: 0.94)
        : scheme.onSurface.withValues(alpha: 0.92);
    final sub = dark
        ? Colors.white.withValues(alpha: 0.66)
        : scheme.onSurface.withValues(alpha: 0.58);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle.
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          children: [
            Icon(Icons.schedule_send_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.schedule_message_sheet_title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets(l10n))
              _PresetChip(
                label: p.label,
                onTap: p.at == null ? null : () => _applyPreset(p.at!),
                dark: dark,
                primary: scheme.primary,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                icon: Icons.calendar_today_rounded,
                label: l10n.schedule_date_label,
                value: dateFmt.format(_selected),
                onTap: _pickDate,
                dark: dark,
                primary: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerTile(
                icon: Icons.access_time_rounded,
                label: l10n.schedule_time_label,
                value: timeFmt.format(_selected),
                onTap: _pickTime,
                dark: dark,
                primary: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isInPast
                ? scheme.error.withValues(alpha: dark ? 0.22 : 0.14)
                : scheme.primary.withValues(alpha: dark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isInPast
                  ? scheme.error.withValues(alpha: 0.55)
                  : scheme.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isInPast
                    ? Icons.error_outline_rounded
                    : Icons.send_time_extension_rounded,
                size: 18,
                color: _isInPast ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isInPast
                      ? l10n.schedule_message_must_be_in_future
                      : l10n.schedule_message_will_send_at(
                          '${dateFmt.format(_selected)}, ${timeFmt.format(_selected)}',
                        ),
                  style: TextStyle(
                    color: _isInPast ? scheme.error : fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showE2eeWarning) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: dark ? 0.18 : 0.14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.schedule_message_e2ee_warning,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: sub,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: dark ? 0.20 : 0.32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l10n.schedule_message_cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isInPast
                    ? null
                    : () => widget.onConfirm(_selected),
                icon: const Icon(Icons.schedule_send_rounded, size: 18),
                label: Text(
                  widget.initialSendAt != null
                      ? l10n.schedule_message_save
                      : l10n.schedule_message_confirm,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
    required this.dark,
    required this.primary,
  });

  final String label;
  final VoidCallback? onTap;
  final bool dark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: disabled
                ? Colors.transparent
                : primary.withValues(alpha: dark ? 0.18 : 0.10),
            border: Border.all(
              color: disabled
                  ? Colors.white.withValues(alpha: dark ? 0.10 : 0.20)
                  : primary.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: disabled
                  ? (dark
                        ? Colors.white.withValues(alpha: 0.40)
                        : Colors.black.withValues(alpha: 0.36))
                  : (dark ? Colors.white.withValues(alpha: 0.92) : primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.dark,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool dark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = dark
        ? Colors.white.withValues(alpha: 0.92)
        : scheme.onSurface.withValues(alpha: 0.90);
    final sub = dark
        ? Colors.white.withValues(alpha: 0.62)
        : scheme.onSurface.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.14 : 0.26),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sub,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
