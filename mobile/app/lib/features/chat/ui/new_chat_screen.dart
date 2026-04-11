import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../shared/ui/app_back_button.dart';
import '../data/user_profile.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _search = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final repo = ref.watch(chatRepositoryProvider);
    final profilesRepo = ref.watch(userProfilesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/chats'),
        title: const Text('Новый чат'),
      ),
      body: SafeArea(
        child: userAsync.when(
          data: (u) {
            if (u == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth'));
              return const Center(child: CircularProgressIndicator());
            }

            if (profilesRepo == null || repo == null) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Firebase не готов.'),
              );
            }

            return FutureBuilder<List<UserProfile>>(
              future: profilesRepo.listAllUsers(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = (snap.data ?? const <UserProfile>[])
                    .where((p) => p.id != u.uid)
                    .toList(growable: false);

                final term = _search.text.trim().toLowerCase();
                final filtered = term.isEmpty
                    ? all
                    : all
                        .where((p) =>
                            p.name.toLowerCase().contains(term) ||
                            (p.username ?? '').toLowerCase().contains(term))
                        .toList(growable: false);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Поиск...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final avatarUrl = (p.avatarThumb ?? p.avatar);
                          final canRenderAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty && !_looksLikeSvg(avatarUrl);
                          final avatarImage = canRenderAvatar ? NetworkImage(avatarUrl) : null;
                          return ListTile(
                            enabled: !_busy,
                            leading: CircleAvatar(
                              backgroundImage: avatarImage,
                              child: !canRenderAvatar ? Text(p.name.characters.first) : null,
                            ),
                            title: Text(p.name),
                            subtitle: (p.username ?? '').isNotEmpty ? Text('@${p.username}') : null,
                            onTap: _busy
                                ? null
                                : () async {
                                    setState(() {
                                      _busy = true;
                                      _error = null;
                                    });
                                    try {
                                      // Load current user profile for participantInfo.
                                      final meList = (snap.data ?? const <UserProfile>[]);
                                      final me = meList.where((x) => x.id == u.uid).cast<UserProfile?>().firstWhere(
                                            (x) => x != null,
                                            orElse: () => null,
                                          );
                                      if (me == null) {
                                        throw StateError('Не найден профиль текущего пользователя в users/{uid}.');
                                      }
                                      final convId = await repo.createOrOpenDirectChat(
                                        currentUserId: u.uid,
                                        otherUserId: p.id,
                                        currentUserInfo: (name: me.name, avatar: me.avatar, avatarThumb: me.avatarThumb),
                                        otherUserInfo: (name: p.name, avatar: p.avatar, avatarThumb: p.avatarThumb),
                                      );
                                      if (!mounted) return;
                                      context.go('/chats/$convId');
                                    } catch (e) {
                                      setState(() => _error = e.toString());
                                    } finally {
                                      if (mounted) setState(() => _busy = false);
                                    }
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Auth error: $e'),
          ),
        ),
      ),
    );
  }
}

bool _looksLikeSvg(String url) {
  final u = url.toLowerCase();
  if (u.contains('/svg')) return true;
  if (u.endsWith('.svg')) return true;
  if (u.contains('format=svg')) return true;
  return false;
}

