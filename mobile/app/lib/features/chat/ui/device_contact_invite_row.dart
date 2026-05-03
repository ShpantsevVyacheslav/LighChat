import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/device_contacts_suggestions.dart';

class DeviceContactInviteRow extends StatelessWidget {
  const DeviceContactInviteRow({
    super.key,
    required this.candidate,
    required this.registered,
    required this.enabled,
    this.onOpenChat,
    this.onInvite,
  });

  final DeviceContactCandidate candidate;
  final bool registered;
  final bool enabled;
  final VoidCallback? onOpenChat;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? (registered ? onOpenChat : null)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: fg.withValues(alpha: 0.08),
                  child: Text(
                    candidate.displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      if (candidate.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          candidate.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fg.withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (!registered)
                  OutlinedButton.icon(
                    onPressed: enabled ? onInvite : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(AppLocalizations.of(context)!.chat_invite_button),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: fg.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

