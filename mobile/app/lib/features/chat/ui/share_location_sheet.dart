import 'package:flutter/material.dart';
import 'dart:ui';

import '../../../l10n/app_localizations.dart';
import '../data/live_location_duration_options.dart';

/// Нижний лист: «Как делиться» — паритет `ChatAttachLocationDialog` на вебе.
Future<String?> showShareLocationSettingsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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
                alpha: dark ? 0.78 : 0.90,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.16 : 0.42),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _ShareLocationSheetContent(
                  onCancel: () => Navigator.of(ctx).pop(),
                  onConfirm: (id) => Navigator.of(ctx).pop(id),
                ),
              ),
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

class _ShareLocationSheetContentState
    extends State<_ShareLocationSheetContent> {
  String _selectedId = 'once';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark
        ? Colors.white.withValues(alpha: 0.92)
        : scheme.onSurface.withValues(alpha: 0.90);
    final sub = dark
        ? Colors.white.withValues(alpha: 0.72)
        : scheme.onSurface.withValues(alpha: 0.62);

    Widget durationItem(String id, String label) {
      final selected = _selectedId == id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedId = id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected
                    ? (dark
                          ? scheme.primary.withValues(alpha: 0.20)
                          : scheme.primary.withValues(alpha: 0.14))
                    : (dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03)),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.64)
                      : Colors.white.withValues(alpha: dark ? 0.14 : 0.26),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, color: scheme.primary, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.share_location_title,
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
          l10n.share_location_how,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sub,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final o in liveLocationDurationOptions(l10n))
                  durationItem(o.id, o.label),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(l10n.share_location_cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => widget.onConfirm(_selectedId),
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: Text(l10n.share_location_send),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
