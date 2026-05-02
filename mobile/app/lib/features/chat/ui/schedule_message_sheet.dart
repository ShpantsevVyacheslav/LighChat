import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ScheduleMessageSheet(
      initialSendAt: initialSendAt,
      showE2eeWarning: showE2eeWarning,
    ),
  );
}

class _ScheduleMessageSheet extends StatefulWidget {
  const _ScheduleMessageSheet({this.initialSendAt, this.showE2eeWarning = false});

  final DateTime? initialSendAt;
  final bool showE2eeWarning;

  @override
  State<_ScheduleMessageSheet> createState() => _ScheduleMessageSheetState();
}

class _ScheduleMessageSheetState extends State<_ScheduleMessageSheet> {
  late DateTime _now;
  late DateTime _selected;

  static const Duration _minLead = Duration(minutes: 1);

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
      locale: const Locale('ru'),
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

  List<({String label, DateTime? at})> _presets() {
    final today18 = DateTime(_now.year, _now.month, _now.day, 18, 0);
    final tomorrow = _now.add(const Duration(days: 1));
    final tomorrow09 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    final tomorrow18 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
    return [
      (
        label: 'Сегодня в 18:00',
        at: today18.isAfter(_now.add(_minLead)) ? today18 : null,
      ),
      (label: 'Завтра в 09:00', at: tomorrow09),
      (label: 'Завтра в 18:00', at: tomorrow18),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMMM yyyy', 'ru');
    final timeFmt = DateFormat('HH:mm', 'ru');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_send_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Запланировать сообщение',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets())
                  OutlinedButton(
                    onPressed: p.at == null ? null : () => _applyPreset(p.at!),
                    child: Text(p.label),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(dateFmt.format(_selected)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text(timeFmt.format(_selected)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isInPast
                    ? cs.errorContainer.withValues(alpha: 0.5)
                    : cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isInPast
                    ? 'Время должно быть в будущем (минимум через минуту).'
                    : 'Будет отправлено: '
                          '${dateFmt.format(_selected)}, ${timeFmt.format(_selected)}',
                style: TextStyle(
                  color: _isInPast ? cs.error : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.showE2eeWarning) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(10),
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
                        'Это E2EE-чат. Отложенное сообщение будет сохранено '
                        'в открытом виде на сервере и опубликовано без шифрования.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isInPast
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  icon: const Icon(Icons.schedule_send_rounded, size: 18),
                  label: const Text('Запланировать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
