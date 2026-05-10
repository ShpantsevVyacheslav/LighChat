import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/user_sticker_packs_repository.dart';

Future<void> saveAttachmentToMyStickersFlow({
  required BuildContext context,
  required UserStickerPacksRepository repo,
  required String userId,
  required ChatAttachment attachment,
  required void Function(String message) onToast,
}) async {
  final packId = await _pickPackSheet(context, repo: repo, userId: userId);
  if (packId == null) return;
  final ok = await repo.addRemoteImageToPack(
    userId: userId,
    packId: packId,
    att: attachment,
  );
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  onToast(ok ? l10n.sticker_saved_to_pack : l10n.sticker_save_gif_failed);
}

Future<String?> _pickPackSheet(
  BuildContext context, {
  required UserStickerPacksRepository repo,
  required String userId,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1E),
    builder: (ctx) {
      return SafeArea(
        child: StreamBuilder<List<dynamic>>(
          stream: repo.watchMyPacks(userId),
          builder: (context, snap) {
            final packs = snap.data ?? const [];
            final l10n = AppLocalizations.of(context)!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.sticker_save_to_pack,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (packs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.sticker_no_packs_hint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in packs)
                          ListTile(
                            title: Text(p.name),
                            onTap: () => Navigator.pop(ctx, p.id),
                          ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.sticker_new_pack_option),
                  onTap: () async {
                    final id = await _promptNewPackName(
                      ctx,
                      repo: repo,
                      userId: userId,
                    );
                    if (id != null && ctx.mounted) Navigator.pop(ctx, id);
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<String?> _promptNewPackName(
  BuildContext context, {
  required UserStickerPacksRepository repo,
  required String userId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: l10n.sticker_default_pack_name);
  final id = await showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (ctx) {
      return Dialog(
        backgroundColor: const Color(0xFF17191D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sticker_new_pack_dialog_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.sticker_pack_name_hint,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2A79FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () async {
                      final name = ctrl.text;
                      final pid = await repo.createPack(
                        userId,
                        name,
                        l10n: AppLocalizations.of(ctx),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, pid);
                    },
                    child: Text(l10n.common_create),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.11),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.common_cancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return id;
}
