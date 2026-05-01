import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import 'notification_settings_ui.dart';
import 'profile_subpage_header.dart';

/// Уведомления для одной беседы: `users/{uid}/chatConversationPrefs/{conversationId}`.
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
                  initialData: const <String, dynamic>{},
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        ChatProfileSubpageHeader(
                          title: 'Уведомления в этом чате',
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                NotificationSettingsMutedBanner(
                                  text:
                                      'Настройки ниже действуют только для этой '
                                      'беседы и не меняют общие уведомления приложения.',
                                ),
                                const SizedBox(height: 22),
                                NotificationSettingsCard(
                                  title: 'Этот чат',
                                  children: [
                                    NotificationSettingsSwitchRow(
                                      title: 'Без звука и скрытые оповещения',
                                      subtitle:
                                          'Не беспокоить по этому чату на этом устройстве.',
                                      value: muted,
                                      onChanged: (v) =>
                                          savePatch(<String, Object?>{
                                            'notificationsMuted': v,
                                          }),
                                    ),
                                    const SizedBox(height: 4),
                                    NotificationSettingsSwitchRow(
                                      title: 'Показывать превью текста',
                                      subtitle:
                                          'Если выключено — заголовок без фрагмента сообщения (где это поддерживается).',
                                      value: preview,
                                      onChanged: (v) =>
                                          savePatch(<String, Object?>{
                                            'notificationShowPreview': v,
                                          }),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
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
