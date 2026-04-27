import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../data/user_block_providers.dart';
import '../data/user_profile.dart';

/// Список пользователей из `users/{me}.blockedUserIds` с возможностью разблокировать.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final blockedAsync = ref.watch(userBlockedUserIdsProvider(uid));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заблокированные'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (ids) {
          if (ids.isEmpty) {
            return Center(
              child: Text(
                'Нет заблокированных пользователей',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 16,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ids.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final id = ids[i];
              return _BlockedUserTile(userId: id);
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends ConsumerStatefulWidget {
  const _BlockedUserTile({required this.userId});

  final String userId;

  @override
  ConsumerState<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends ConsumerState<_BlockedUserTile> {
  bool _busy = false;

  Future<void> _unblock() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Разблокировать?'),
        content: const Text(
          'Пользователь снова сможет писать вам (если политика контактов позволит) и видеть ваш профиль в поиске.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(me).set(
        <String, Object?>{
          'blockedUserIds': FieldValue.arrayRemove([widget.userId]),
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        // Success SnackBars are intentionally suppressed (errors only).
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(userProfilesRepositoryProvider);
    return FutureBuilder<Map<String, UserProfile>>(
      future: repo?.getUsersByIdsOnce([widget.userId]),
      builder: (context, snap) {
        final p = snap.data?[widget.userId];
        final nameTrim = (p?.name ?? '').trim();
        final title = nameTrim.isNotEmpty ? nameTrim : widget.userId;
        return ListTile(
          title: Text(title),
          subtitle: Text(
            widget.userId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
            ),
          ),
          trailing: TextButton(
            onPressed: _busy ? null : _unblock,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Разблокировать'),
          ),
        );
      },
    );
  }
}
