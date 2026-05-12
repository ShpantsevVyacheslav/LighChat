import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/user_role_provider.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_storage_stats_screen.dart';
import 'admin_feature_flags_screen.dart';
import 'admin_push_notifications_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_support_screen.dart';

/// Главный scaffold админки: левая навигация + content area.
///
/// На широких окнах (desktop) — NavigationRail; на узких — NavigationBar.
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key, this.initialSection});

  final String? initialSection;

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  late _AdminSection _current;

  @override
  void initState() {
    super.initState();
    _current = _AdminSection.fromSlug(widget.initialSection) ??
        _AdminSection.overview;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider).asData?.value ?? AppUserRole.user;
    if (!role.canAccessAdmin) {
      // Не должно случиться — guard в роутере, но на всякий случай.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final visibleSections = _AdminSection.values
        .where((s) => s.requiredRole.index <= role.index)
        .toList();

    final selectedIndex = visibleSections.indexOf(_current).clamp(0, visibleSections.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Админ • ${_current.label}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Закрыть админку',
          onPressed: () => context.go('/'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          if (!wide) {
            return Column(
              children: [
                Expanded(child: _content()),
                NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _current = visibleSections[i]),
                  destinations: [
                    for (final s in visibleSections)
                      NavigationDestination(
                        icon: Icon(s.icon),
                        label: s.label,
                      ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1100,
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) =>
                    setState(() => _current = visibleSections[i]),
                destinations: [
                  for (final s in visibleSections)
                    NavigationRailDestination(
                      icon: Icon(s.icon),
                      label: Text(s.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _content()),
            ],
          );
        },
      ),
    );
  }

  Widget _content() {
    switch (_current) {
      case _AdminSection.overview:
        return const AdminOverviewScreen();
      case _AdminSection.users:
        return const AdminUsersScreen();
      case _AdminSection.moderation:
        return const AdminModerationScreen();
      case _AdminSection.announcements:
        return const AdminAnnouncementsScreen();
      case _AdminSection.storage:
        return const AdminStorageStatsScreen();
      case _AdminSection.featureFlags:
        return const AdminFeatureFlagsScreen();
      case _AdminSection.push:
        return const AdminPushNotificationsScreen();
      case _AdminSection.auditLog:
        return const AdminAuditLogScreen();
      case _AdminSection.support:
        return const AdminSupportScreen();
    }
  }
}

enum _AdminSection {
  overview('Обзор', Icons.dashboard, AppUserRole.worker, 'overview'),
  users('Пользователи', Icons.people, AppUserRole.admin, 'users'),
  moderation('Модерация', Icons.gavel, AppUserRole.worker, 'moderation'),
  announcements('Объявления', Icons.campaign, AppUserRole.admin, 'announcements'),
  storage('Хранилище', Icons.storage, AppUserRole.admin, 'storage'),
  featureFlags('Feature Flags', Icons.flag, AppUserRole.admin, 'feature-flags'),
  push('Push-уведомления', Icons.notifications, AppUserRole.admin, 'push'),
  auditLog('Audit Log', Icons.history, AppUserRole.worker, 'audit-log'),
  support('Поддержка', Icons.support_agent, AppUserRole.worker, 'support');

  const _AdminSection(this.label, this.icon, this.requiredRole, this.slug);

  final String label;
  final IconData icon;
  final AppUserRole requiredRole;
  final String slug;

  static _AdminSection? fromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    for (final s in values) {
      if (s.slug == slug) return s;
    }
    return null;
  }
}
