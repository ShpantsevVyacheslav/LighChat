import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';

class ChatConversationNotificationsScreen extends ConsumerWidget {
  const ChatConversationNotificationsScreen({
    super.key,
    required this.currentUserId,
    required this.conversationId,
  });

  final String currentUserId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(chatSettingsRepositoryProvider);
    final userDocAsync = ref.watch(userChatSettingsDocProvider(currentUserId));
    final userDoc = userDocAsync.asData?.value ?? const <String, dynamic>{};

    final rawGlobal = userDoc['notificationSettings'];
    final globalMap = rawGlobal is Map
        ? rawGlobal.map((k, v) => MapEntry(k.toString(), v))
        : const <String, Object?>{};
    final global = _GlobalNotificationSettings.fromRaw(globalMap);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: repo == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<Map<String, dynamic>>(
                  stream: repo.watchChatConversationPrefs(
                    userId: currentUserId,
                    conversationId: conversationId,
                  ),
                  builder: (context, snap) {
                    final prefsMap = snap.data ?? const <String, dynamic>{};
                    final prefs = _ConversationNotificationPrefs.fromRaw(
                      prefsMap,
                    );
                    final muted = prefs.notificationsMuted;
                    final preview =
                        prefs.notificationShowPreview ?? global.showPreview;

                    Future<void> savePatch(Map<String, Object?> patch) async {
                      try {
                        await repo.patchChatConversationPrefs(
                          userId: currentUserId,
                          conversationId: conversationId,
                          patch: patch,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Не удалось сохранить: $e')),
                        );
                      }
                    }

                    return _NotificationsInChatView(
                      muted: muted,
                      preview: preview,
                      onMutedChanged: (v) =>
                          savePatch(<String, Object?>{'notificationsMuted': v}),
                      onPreviewChanged: (v) => savePatch(<String, Object?>{
                        'notificationShowPreview': v,
                      }),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _NotificationsInChatView extends StatelessWidget {
  const _NotificationsInChatView({
    required this.muted,
    required this.preview,
    required this.onMutedChanged,
    required this.onPreviewChanged,
  });

  final bool muted;
  final bool preview;
  final ValueChanged<bool> onMutedChanged;
  final ValueChanged<bool> onPreviewChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.70)
        : scheme.onSurface.withValues(alpha: 0.68);
    final panelColor = dark
        ? const Color(0xFF071621).withValues(alpha: 0.82)
        : const Color(0xFF0A2534).withValues(alpha: 0.74);

    return LayoutBuilder(
      builder: (context, c) {
        final panelWidth = c.maxWidth > 1100
            ? 540.0
            : (c.maxWidth > 760 ? c.maxWidth * 0.56 : c.maxWidth * 0.92);
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: dark ? 0.34 : 0.22),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: panelWidth,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(34),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelColor,
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const AppBackButton(fallbackLocation: '/chats'),
                              Expanded(
                                child: Text(
                                  'Уведомления в этом чате',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.94),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Настройки ниже действуют только для этой беседы и не меняют общие уведомления приложения.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.35,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _SwitchRow(
                                    title: 'Без звука и скрытые оповещения',
                                    subtitle:
                                        'Не беспокоить по этому чату на этом устройстве.',
                                    value: muted,
                                    onChanged: onMutedChanged,
                                  ),
                                  _SwitchRow(
                                    title: 'Показывать превью текста',
                                    subtitle:
                                        'Если выключено — заголовок без фрагмента сообщения (где это поддерживается).',
                                    value: preview,
                                    onChanged: onPreviewChanged,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.95)
                        : scheme.onSurface.withValues(alpha: 0.94),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 15,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.68)
                          : scheme.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _GlobalNotificationSettings {
  const _GlobalNotificationSettings({required this.showPreview});

  final bool showPreview;

  factory _GlobalNotificationSettings.fromRaw(Map<String, Object?> raw) {
    return _GlobalNotificationSettings(
      showPreview: raw['showPreview'] != false,
    );
  }
}

class _ConversationNotificationPrefs {
  const _ConversationNotificationPrefs({
    required this.notificationsMuted,
    required this.notificationShowPreview,
  });

  final bool notificationsMuted;
  final bool? notificationShowPreview;

  factory _ConversationNotificationPrefs.fromRaw(Map<String, dynamic> raw) {
    final previewRaw = raw['notificationShowPreview'];
    return _ConversationNotificationPrefs(
      notificationsMuted: raw['notificationsMuted'] == true,
      notificationShowPreview: previewRaw is bool ? previewRaw : null,
    );
  }
}
