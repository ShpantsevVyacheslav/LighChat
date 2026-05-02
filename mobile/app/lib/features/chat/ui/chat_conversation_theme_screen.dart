import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import 'chat_wallpaper_preview_styles.dart';
import 'effective_chat_wallpaper.dart';
import 'notification_settings_ui.dart';
import 'profile_subpage_header.dart';

/// Фон только для одного чата: `users/{uid}/chatConversationPrefs/{conversationId}.chatWallpaper`
/// (как [`ConversationThemePanel`] на вебе).
class ChatConversationThemeScreen extends ConsumerStatefulWidget {
  const ChatConversationThemeScreen({
    super.key,
    required this.currentUserId,
    required this.conversationId,
  });

  final String currentUserId;
  final String conversationId;

  @override
  ConsumerState<ChatConversationThemeScreen> createState() =>
      _ChatConversationThemeScreenState();
}

class _ChatConversationThemeScreenState
    extends ConsumerState<ChatConversationThemeScreen> {
  bool _uploading = false;

  Future<void> _savePatch(Map<String, Object?> patch) async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.patchChatConversationPrefs(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        patch: patch,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.chat_theme_save_error(e.toString()))));
    }
  }

  Future<void> _pickAndUploadWallpaper() async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final raw = await file.readAsBytes();
      final decoded = img.decodeImage(raw);
      final Uint8List uploadBytes;
      if (decoded == null) {
        uploadBytes = raw;
      } else {
        final resized = img.copyResize(
          decoded,
          width: decoded.width > 1920 ? 1920 : decoded.width,
        );
        uploadBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 84));
      }

      final url = await repo.uploadWallpaper(user.uid, uploadBytes);
      await repo.addCustomBackground(user.uid, url);
      await _savePatch(<String, Object?>{'chatWallpaper': url});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.chat_theme_load_error(e.toString()))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmRemoveCustomWallpaper(String url) async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) return;

    final prefsSnap = await repo
        .watchChatConversationPrefs(
          userId: widget.currentUserId,
          conversationId: widget.conversationId,
        )
        .first;
    final convActive = prefsSnap['chatWallpaper'] as String?;
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.chat_theme_delete_title),
          content: Text(
            AppLocalizations.of(context)!.chat_theme_delete_body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.common_delete),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    try {
      // `wasActive` в репозитории сбрасывает **глобальный** `chatSettings.chatWallpaper`;
      // для чата используем только `arrayRemove`, затем при необходимости чистим prefs.
      await repo.removeCustomBackground(user.uid, url, wasActive: false);
      if (convActive == url) {
        await _savePatch(<String, Object?>{
          'chatWallpaper': FieldValue.delete(),
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.chat_theme_delete_error(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(chatSettingsRepositoryProvider);
    final userDocAsync = ref.watch(
      userChatSettingsDocProvider(widget.currentUserId),
    );
    final userDoc = userDocAsync.asData?.value ?? const <String, dynamic>{};
    final rawChat = userDoc['chatSettings'];
    final chatMap = rawChat is Map
        ? Map<String, dynamic>.from(
            rawChat.map((k, v) => MapEntry(k.toString(), v)),
          )
        : const <String, dynamic>{};
    final globalWallpaper = chatMap['chatWallpaper'] as String?;
    final customRaw = userDoc['customBackgrounds'];
    final customBackgrounds = customRaw is List
        ? customRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.56)
        : scheme.onSurface.withValues(alpha: 0.62);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: repo == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<Map<String, dynamic>>(
                  stream: repo.watchChatConversationPrefs(
                    userId: widget.currentUserId,
                    conversationId: widget.conversationId,
                  ),
                  initialData: const <String, dynamic>{},
                  builder: (context, snap) {
                    final prefs = snap.data ?? const <String, dynamic>{};
                    final localRaw = prefs['chatWallpaper'];
                    final local = localRaw is String ? localRaw.trim() : '';
                    final hasOverride = local.isNotEmpty;
                    final effective = resolveEffectiveChatWallpaper(
                      globalChatWallpaper: globalWallpaper,
                      conversationPrefs: prefs,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        ChatProfileSubpageHeader(
                          title: AppLocalizations.of(context)!.chat_theme_title,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                NotificationSettingsMutedBanner(
                                  text: AppLocalizations.of(context)!.chat_theme_description,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  AppLocalizations.of(context)!.chat_theme_current_bg,
                                  style: TextStyle(
                                    fontSize:
                                        kNotificationSettingsCardTitleSize,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.94)
                                        : scheme.onSurface.withValues(
                                            alpha: 0.92,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color:
                                          (dark
                                                  ? Colors.white
                                                  : scheme.onSurface)
                                              .withValues(
                                                alpha: dark ? 0.14 : 0.12,
                                              ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(21),
                                    child: SizedBox(
                                      height: 120,
                                      width: double.infinity,
                                      child:
                                          effective == null || effective.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context)!.chat_theme_default_bg,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:
                                                        kNotificationSettingsMutedTextSize,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : DecoratedBox(
                                              decoration:
                                                  wallpaperPreviewDecoration(
                                                    context,
                                                    effective,
                                                  ),
                                              child:
                                                  effective.startsWith('http')
                                                  ? ColoredBox(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      child:
                                                          const SizedBox.expand(),
                                                    )
                                                  : const SizedBox.expand(),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  AppLocalizations.of(context)!.chat_theme_presets,
                                  style: TextStyle(
                                    fontSize:
                                        kNotificationSettingsCardTitleSize,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.94)
                                        : scheme.onSurface.withValues(
                                            alpha: 0.92,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      1 +
                                      kChatWallpaperGradientPresets.length +
                                      customBackgrounds.length +
                                      1,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 1.04,
                                      ),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      final selected = !hasOverride;
                                      return _WallpaperTile(
                                        selected: selected,
                                        decoration: wallpaperPreviewDecoration(
                                          context,
                                          null,
                                        ),
                                        centerLabel: AppLocalizations.of(context)!.chat_theme_global_label,
                                        onTap: () =>
                                            _savePatch(<String, Object?>{
                                              'chatWallpaper':
                                                  FieldValue.delete(),
                                            }),
                                      );
                                    }
                                    final presetStart = 1;
                                    final presetCount =
                                        kChatWallpaperGradientPresets.length;
                                    if (index < presetStart + presetCount) {
                                      final preset =
                                          kChatWallpaperGradientPresets[index -
                                              presetStart];
                                      final v = preset.value;
                                      final selected =
                                          hasOverride && local == v;
                                      return _WallpaperTile(
                                        selected: selected,
                                        decoration: wallpaperPreviewDecoration(
                                          context,
                                          v,
                                        ),
                                        centerLabel: preset.label,
                                        onTap: () => _savePatch(
                                          <String, Object?>{'chatWallpaper': v},
                                        ),
                                      );
                                    }
                                    final customStart =
                                        presetStart + presetCount;
                                    final customIdx = index - customStart;
                                    final customCount =
                                        customBackgrounds.length;
                                    if (customIdx < customCount) {
                                      final url = customBackgrounds[customIdx];
                                      final selected =
                                          hasOverride && local == url;
                                      return _WallpaperTile(
                                        selected: selected,
                                        decoration: wallpaperPreviewDecoration(
                                          context,
                                          url,
                                        ),
                                        onTap: () =>
                                            _savePatch(<String, Object?>{
                                              'chatWallpaper': url,
                                            }),
                                        onDelete: () =>
                                            _confirmRemoveCustomWallpaper(url),
                                      );
                                    }
                                    return _AddWallpaperTile(
                                      uploading: _uploading,
                                      onTap: _uploading
                                          ? null
                                          : _pickAndUploadWallpaper,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.chat_theme_hint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: kNotificationSettingsBodyTextSize,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.selected,
    required this.decoration,
    required this.onTap,
    this.onDelete,
    this.centerLabel,
  });

  final bool selected;
  final BoxDecoration decoration;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: decoration.copyWith(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F86FF)
                : fg.withValues(alpha: dark ? 0.12 : 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (centerLabel != null && centerLabel!.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
                  child: Text(
                    centerLabel!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: dark ? 0.88 : 0.86),
                    ),
                  ),
                ),
              ),
            if (selected)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2F86FF).withValues(alpha: 0.92),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            if (onDelete != null)
              Positioned(
                top: 5,
                right: 5,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (dark ? Colors.black : scheme.surface).withValues(
                        alpha: dark ? 0.42 : 0.32,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddWallpaperTile extends StatelessWidget {
  const _AddWallpaperTile({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.04 : 0.9,
          ),
          border: Border.all(
            color: fg.withValues(alpha: dark ? 0.26 : 0.12),
            width: 1.6,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: uploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: fg.withValues(alpha: dark ? 0.7 : 0.66),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.common_add,
                      style: TextStyle(
                        fontSize: 14,
                        color: fg.withValues(alpha: dark ? 0.64 : 0.62),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
