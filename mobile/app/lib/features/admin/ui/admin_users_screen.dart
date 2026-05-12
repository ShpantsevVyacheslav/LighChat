import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_user_callables.dart';

/// Список пользователей системы с фильтром и базовыми actions.
///
/// MVP-версия: список всех документов `users/`, поиск по
/// displayName/email/phone, бан/анбан/reset password/revoke sessions
/// через [AdminUserCallables]. Не реализовано: пагинация на сервере
/// (читаем все, мобильный лимит не дёргаем), редактирование ролей,
/// просмотр устройств (открыть через web — см. AdminPlaceholder
/// remainingexpect TODO links).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  final _callables = AdminUserCallables();
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(500); // mobile guard — больше через web/CF

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по имени, email, телефону',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Ошибка: ${snap.error}'),
                  ),
                );
              }
              final docs = snap.data?.docs ?? const [];
              final filtered = _filter(docs, _search.text);
              if (filtered.isEmpty) {
                return const Center(child: Text('Никого не найдено'));
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _UserTile(
                  doc: filtered[i],
                  busy: _busy,
                  onAction: _runAction,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String q,
  ) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return docs;
    return docs.where((d) {
      final data = d.data();
      bool match(Object? v) {
        if (v is! String) return false;
        return v.toLowerCase().contains(needle);
      }
      return match(data['displayName']) ||
          match(data['email']) ||
          match(data['phoneNumber']) ||
          match(data['username']);
    }).toList();
  }

  Future<void> _runAction(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    _UserAction action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final uid = doc.id;
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case _UserAction.toggleBlock:
          final blocked = doc.data()['blocked'] == true ||
              (doc.data()['accountBlock'] as Map?)?.isNotEmpty == true;
          if (blocked) {
            await _callables.unblockUser(uid);
            messenger.showSnackBar(
              const SnackBar(content: Text('Пользователь разблокирован')),
            );
          } else {
            final reason = await _askReason(context);
            if (reason == null) break;
            await _callables.blockUser(uid: uid, reason: reason);
            messenger.showSnackBar(
              const SnackBar(content: Text('Пользователь заблокирован')),
            );
          }
          break;
        case _UserAction.resetPassword:
          final temp = await _callables.resetPassword(uid);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                temp != null
                    ? 'Новый пароль: $temp (скопируйте)'
                    : 'Письмо для сброса отправлено',
              ),
              duration: const Duration(seconds: 8),
            ),
          );
          break;
        case _UserAction.revokeSessions:
          await _callables.revokeSessions(uid);
          messenger.showSnackBar(
            const SnackBar(content: Text('Все сессии завершены')),
          );
          break;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Причина блокировки'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Например: спам'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }
}

enum _UserAction { toggleBlock, resetPassword, revokeSessions }

class _UserTile extends StatelessWidget {
  const _UserTile({required this.doc, required this.busy, required this.onAction});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool busy;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>, _UserAction)
      onAction;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = (data['displayName'] as String?)?.trim() ??
        (data['username'] as String?)?.trim() ??
        '(без имени)';
    final email = data['email'] as String?;
    final phone = data['phoneNumber'] as String?;
    final role = data['role'] as String? ?? 'user';
    final blocked = data['blocked'] == true ||
        (data['accountBlock'] as Map?)?.isNotEmpty == true;
    final avatarUrl = data['photoURL'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? Text(name.characters.first.toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          if (role != 'user')
            Chip(
              label: Text(role),
              labelStyle: const TextStyle(fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          if (blocked)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.block, color: Colors.red, size: 18),
            ),
        ],
      ),
      subtitle: Text(
        [email, phone, doc.id].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: busy
          ? const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : PopupMenuButton<_UserAction>(
              onSelected: (a) => onAction(doc, a),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _UserAction.toggleBlock,
                  child: Text(blocked ? 'Разблокировать' : 'Заблокировать'),
                ),
                const PopupMenuItem(
                  value: _UserAction.resetPassword,
                  child: Text('Сбросить пароль'),
                ),
                const PopupMenuItem(
                  value: _UserAction.revokeSessions,
                  child: Text('Завершить все сессии'),
                ),
              ],
            ),
    );
  }
}
