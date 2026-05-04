import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'l10n/app_localizations.dart';
import 'features/auth/registration_profile_gate.dart';
import 'features/auth/ui/auth_screen.dart';
import 'features/auth/ui/google_complete_profile_screen.dart';
import 'features/auth/ui/qr_login_screen.dart';
import 'features/auth/ui/profile_screen.dart';
import 'features/chat/ui/chat_forward_screen.dart';
import 'features/chat/ui/chat_account_screen.dart';
import 'features/chat/ui/chat_contacts_screen.dart';
import 'features/chat/ui/chat_contact_profile_screen.dart';
import 'features/chat/ui/chat_contact_edit_screen.dart';
import 'features/chat/ui/chat_call_detail_screen.dart';
import 'features/chat/ui/chat_calls_screen.dart';
import 'features/chat/ui/chat_incoming_call_entry_screen.dart';
import 'features/chat/ui/chat_list_screen.dart';
import 'features/chat/ui/chat_meetings_screen.dart';
import 'features/meetings/ui/meeting_entry_screen.dart';
import 'features/chat/ui/chat_notifications_screen.dart';
import 'features/chat/ui/chat_privacy_screen.dart';
import 'features/chat/ui/chat_advanced_privacy_screen.dart';
import 'features/chat/ui/chat_settings_screen.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/chat/ui/conversation_threads_screen.dart';
import 'features/settings/ui/devices_screen.dart';
import 'features/settings/ui/e2ee_recovery_screen.dart';
import 'features/settings/ui/e2ee_qr_pairing_screen.dart';
import 'features/settings/ui/language_screen.dart';
import 'features/settings/ui/blacklist_screen.dart';
import 'features/settings/ui/storage_settings_screen.dart';
import 'features/chat/ui/secret_chat_settings_screen.dart';
import 'features/chat/ui/new_chat_screen.dart';
import 'features/chat/ui/secret_chat_compose_screen.dart';
import 'features/chat/ui/secret_chats_inbox_screen.dart';
import 'features/chat/ui/new_group_chat_screen.dart';
import 'features/chat/ui/edit_group_chat_screen.dart';
import 'features/chat/ui/group_members_screen.dart';
import 'features/chat/ui/thread_screen.dart';
import 'features/chat/ui/thread_route_payload.dart';
import 'features/welcome/data/first_login_animation_storage.dart';
import 'features/welcome/ui/welcome_animation_screen.dart';
import 'features/features_tour/data/features_data.dart';
import 'features/features_tour/ui/features_index_screen.dart';
import 'features/features_tour/ui/features_topic_screen.dart';

/// Notifier, который дёргает GoRouter на пересчёт redirect-ов при изменении
/// auth-стейта. Без этого при cold-start с persistent Firebase session первый
/// redirect видит `currentUser == null` (ещё не восстановлен), и welcome-чек
/// не срабатывает; повторный redirect после восстановления auth не
/// запускается автоматически.
///
/// Также этот listener детектит «успешную авторизацию» (переход null→user
/// или смену uid) и сбрасывает welcome-флаг для текущего uid, чтобы
/// анимация показывалась **после каждой** авторизации, а не только при
/// первом логине на устройстве. Cold-start с уже восстановленной session
/// (previousUser == currentUser) не считается авторизацией — флаг не
/// сбрасывается, анимация не повторяется без необходимости.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _previousUid = FirebaseAuth.instance.currentUser?.uid;
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final prevUid = _previousUid;
      final newUid = user?.uid;
      // Sign-in event: был null (или другой uid) → теперь non-null uid.
      if (newUid != null && newUid.isNotEmpty && newUid != prevUid) {
        // На cold-start prevUid выставлен синхронно из currentUser в
        // конструкторе, поэтому первое событие с тем же uid сюда не
        // попадает — анимация не повторится при перезапуске.
        FirstLoginAnimationStorage.clearForUid(newUid);
      }
      _previousUid = newUid;
      notifyListeners();
    });
  }

  String? _previousUid;
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/chats',
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) async {
      final uri = state.uri;
      final isSignedIn = FirebaseAuth.instance.currentUser != null;

      // Firebase Auth (Google / Apple) iOS callback comes as:
      //   app-<...>://firebaseauth/link?deep_link_id=...
      // GoRouter receives it as a location; we must redirect it to an internal route.
      if (uri.host == 'firebaseauth' && uri.path == '/link') {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return '/auth';
        final status = await getFirestoreRegistrationProfileStatusWithDeadline(
          user,
        );
        final next = googleRouteFromProfileStatus(status);
        return next ?? '/chats';
      }

      // If user is already signed in, never land on auth screen.
      if (isSignedIn &&
          (state.matchedLocation == '/auth' ||
              state.matchedLocation == '/auth/qr')) {
        return '/chats';
      }

      // First-login welcome animation: показывается per-uid + per-device.
      // Не перехватываем deep-link на звонки/митинги/auth-callback —
      // важные сценарии не должны блокироваться приветствием.
      if (isSignedIn) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          final path = uri.path;
          const skipPaths = {'/welcome', '/auth/google-complete'};
          final isCallDeepLink = path.startsWith('/calls/');
          final isMeetingDeepLink = path.startsWith('/meetings/');
          if (!skipPaths.contains(path) &&
              !isCallDeepLink &&
              !isMeetingDeepLink) {
            final shown = await FirstLoginAnimationStorage.isShownFor(uid);
            if (kDebugMode) {
              debugPrint(
                '[welcome-redirect] path=$path uid=$uid shown=$shown',
              );
            }
            if (!shown) return '/welcome';
          }
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/qr',
        builder: (context, state) => const QrLoginScreen(),
      ),
      GoRoute(
        path: '/auth/google-complete',
        builder: (context, state) => const GoogleCompleteProfileScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeAnimationScreen(),
      ),
      GoRoute(
        path: '/features',
        builder: (context, state) {
          final source = state.uri.queryParameters['source'];
          return FeaturesIndexScreen(fromWelcome: source == 'welcome');
        },
      ),
      GoRoute(
        path: '/features/:topic',
        builder: (context, state) {
          final raw = state.pathParameters['topic'] ?? '';
          final topicId = featureTopicIdFromSlug(raw);
          if (topicId == null) {
            return const FeaturesIndexScreen();
          }
          return FeaturesTopicScreen(topicId: topicId);
        },
      ),
      GoRoute(
        path: '/chats',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ChatListScreen(),
        ),
      ),
      GoRoute(
        path: '/contacts',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ChatContactsScreen(),
        ),
      ),
      GoRoute(
        path: '/contacts/user/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ChatContactProfileScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/contacts/user/:userId/edit',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ChatContactEditScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/calls',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ChatCallsScreen(),
        ),
      ),
      GoRoute(
        path: '/meetings',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ChatMeetingsScreen(),
        ),
      ),
      GoRoute(
        path: '/meetings/:meetingId',
        pageBuilder: (context, state) {
          final meetingId = state.pathParameters['meetingId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: MeetingEntryScreen(meetingId: meetingId),
          );
        },
      ),
      GoRoute(
        path: '/calls/:callId',
        pageBuilder: (context, state) {
          final callId = state.pathParameters['callId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ChatCallDetailScreen(callId: callId),
          );
        },
      ),
      GoRoute(
        path: '/calls/incoming/:callId',
        pageBuilder: (context, state) {
          final callId = state.pathParameters['callId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ChatIncomingCallEntryScreen(callId: callId),
          );
        },
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const ChatAccountScreen(),
      ),
      GoRoute(
        path: '/chats/new',
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: '/chats/new/group',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is NewGroupChatScreenArgs) {
            return NewGroupChatScreen(
              initialSelectedUserIds: extra.initialSelectedUserIds,
            );
          }
          return const NewGroupChatScreen();
        },
      ),
      GoRoute(
        path: '/chats/edit/group/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return EditGroupChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chats/group/:conversationId/members',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return GroupMembersScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chats/new/secret',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is SecretChatComposeArgs) {
            return SecretChatComposeScreen(args: extra);
          }
          return Scaffold(
            body: Center(child: Text(AppLocalizations.of(context)!.nav_error_invalid_secret_compose)),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/chats',
        builder: (context, state) => const ChatSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const ChatNotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const ChatPrivacyScreen(),
      ),
      GoRoute(
        path: '/settings/devices',
        builder: (context, state) => const DevicesScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/settings/blacklist',
        builder: (context, state) => const BlacklistScreen(),
      ),
      GoRoute(
        path: '/settings/storage',
        builder: (context, state) => const StorageSettingsScreen(),
      ),
      // Phase 6: recovery (password backup + QR pairing entry point).
      GoRoute(
        path: '/settings/e2ee-recovery',
        builder: (context, state) => const E2eeRecoveryScreen(),
      ),
      // Phase 9 gap #1: полноценный QR-pairing экран (initiator + donor).
      GoRoute(
        path: '/settings/e2ee-qr-pairing',
        builder: (context, state) => const E2eeQrPairingScreen(),
      ),
      GoRoute(
        path: '/chats/secret-inbox',
        builder: (context, state) => const SecretChatsInboxScreen(),
      ),
      GoRoute(
        path: '/chats/forward',
        builder: (context, state) {
          final raw = state.extra;
          final msgs = <ChatMessage>[];
          if (raw is List<ChatMessage>) {
            msgs.addAll(raw);
          } else if (raw is List) {
            for (final e in raw) {
              if (e is ChatMessage) msgs.add(e);
            }
          }
          return ChatForwardScreen(messages: msgs);
        },
      ),
      GoRoute(
        path: '/chats/:conversationId/threads',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return ConversationThreadsScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chats/:conversationId/privacy-advanced',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return ChatAdvancedPrivacyScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chats/:conversationId/secret-settings',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return SecretChatSettingsScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chats/:conversationId/thread/:parentMessageId',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          final parentMessageId = state.pathParameters['parentMessageId'] ?? '';
          final extra = state.extra;
          ChatMessage? parentMessage;
          String? focusMessageId;
          if (extra is ThreadRoutePayload) {
            parentMessage = extra.parentMessage;
            focusMessageId = extra.focusMessageId;
          } else if (extra is ChatMessage) {
            parentMessage = extra;
          } else if (extra is Map) {
            final m = extra.map((k, v) => MapEntry(k.toString(), v));
            final rawFocus = m['focusMessageId'];
            if (rawFocus is String && rawFocus.trim().isNotEmpty) {
              focusMessageId = rawFocus.trim();
            }
            final rawParent = m['parentMessage'];
            if (rawParent is ChatMessage) {
              parentMessage = rawParent;
            }
          }
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ThreadScreen(
              conversationId: conversationId,
              parentMessageId: parentMessageId,
              parentMessage: parentMessage,
              focusMessageId: focusMessageId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/chats/:conversationId',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            name: state.name,
            child: ChatScreen(conversationId: conversationId),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.nav_error_title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(state.error?.toString() ?? 'Unknown error'),
      ),
    ),
  );
}

/// Устанавливается из [MyApp] для deep link из push (без [BuildContext]).
GoRouter? appGoRouterRef;

void attachAppGoRouter(GoRouter router) {
  appGoRouterRef = router;
}
