import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SecretChatTtlSheet extends StatelessWidget {
  const SecretChatTtlSheet({super.key, this.initialSec = 3600});

  final int initialSec;

  static const presets = <int>[
    300,
    900,
    1800,
    3600,
    7200,
    21600,
    43200,
    86400,
  ];

  String _label(AppLocalizations l10n, int sec) {
    if (sec < 3600) return l10n.disappearing_ttl_minutes((sec / 60).round());
    if (sec < 86400) return l10n.disappearing_ttl_hours((sec / 3600).round());
    return l10n.disappearing_ttl_days((sec / 86400).round());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.secret_chat_ttl_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final sec in presets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(_label(l10n, sec)),
                  onTap: () => Navigator.of(context).pop(sec),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop<int?>(null),
              child: Text(l10n.common_cancel),
            ),
          ],
        ),
      ),
    );
  }
}

