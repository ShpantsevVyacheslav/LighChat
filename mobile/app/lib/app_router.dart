import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'features/auth/registration_profile_gate.dart';
import 'features/auth/ui/auth_screen.dart';
import 'features/auth/ui/google_complete_profile_screen.dart';
import 'features/auth/ui/profile_screen.dart';
import 'features/chat/ui/chat_forward_screen.dart';
import 'features/chat/ui/chat_list_screen.dart';
import 'features/chat/ui/chat_settings_screen.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/chat/ui/new_chat_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/chats',
    redirect: (context, state) async {
      final uri = state.uri;
      final isSignedIn = FirebaseAuth.instance.currentUser != null;

      // Firebase Auth (Google) iOS callback comes as:
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
      if (isSignedIn && state.matchedLocation == '/auth') {
        return '/chats';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/google-complete',
        builder: (context, state) => const GoogleCompleteProfileScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chats/new',
        builder: (context, state) => const NewChatScreen(),
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
        path: '/chats/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'];
          return ChatScreen(conversationId: conversationId ?? '');
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Navigation error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(state.error?.toString() ?? 'Unknown error'),
      ),
    ),
  );
}
