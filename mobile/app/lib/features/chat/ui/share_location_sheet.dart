import 'package:flutter/material.dart';

import '../data/live_location_duration_options.dart';

/// Нижний лист: «Как делиться» — паритет `ChatAttachLocationDialog` на вебе.
Future<String?> showShareLocationSettingsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          left: 12,
          right: 12,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: 0.88),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _ShareLocationSheetContent(
              onCancel: () => Navigator.of(ctx).pop(),
              onConfirm: (id) => Navigator.of(ctx).pop(id),
            ),
          ),
        ),
      );
    },
  );
}

class _ShareLocationSheetContent extends StatefulWidget {
  const _ShareLocationSheetContent({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final void Function(String durationId) onConfirm;

  @override
  State<_ShareLocationSheetContent> createState() =>
      _ShareLocationSheetContentState();
}

class _ShareLocationSheetContentState extends State<_ShareLocationSheetContent> {
  String _selectedId = 'once';

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.92);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Поделиться геолокацией',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Как делиться',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: fg.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _selectedId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E2E),
                icon: Icon(Icons.expand_more_rounded, color: fg.withValues(alpha: 0.7)),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                items: [
                  for (final o in kLiveLocationDurationOptions)
                    DropdownMenuItem<String>(
                      value: o.id,
                      child: Text(o.label, maxLines: 2),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedId = v);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => widget.onConfirm(_selectedId),
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: const Text('Отправить'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
