import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  bool _busy = false;
  String? _lastResult;

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance.collection('admin').doc('stats').snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final dau = (data['dau'] as num?)?.toInt();
        final mau = (data['mau'] as num?)?.toInt();
        final totalUsers = (data['totalUsers'] as num?)?.toInt();
        final totalMessages = (data['totalMessages'] as num?)?.toInt();
        final activeConversations =
            (data['activeConversations'] as num?)?.toInt();
        final recomputedAt = _parseTs(data['recomputedAt']);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сводка',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (recomputedAt != null)
                          Text(
                            'Обновлено: ${DateFormat('dd.MM.yyyy HH:mm').format(recomputedAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Text(
                            'Stats ещё не пересчитывались — нажмите «Пересчитать».',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Пересчитать'),
                    onPressed: _busy ? null : _recompute,
                  ),
                ],
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(_lastResult!),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Всего пользователей',
                    value: totalUsers?.toString() ?? '—',
                    icon: Icons.people,
                  ),
                  _StatCard(
                    label: 'DAU (24ч)',
                    value: dau?.toString() ?? '—',
                    icon: Icons.today,
                  ),
                  _StatCard(
                    label: 'MAU (30д)',
                    value: mau?.toString() ?? '—',
                    icon: Icons.calendar_month,
                  ),
                  _StatCard(
                    label: 'Активных чатов (7д)',
                    value: activeConversations?.toString() ?? '—',
                    icon: Icons.chat_bubble_outline,
                  ),
                  _StatCard(
                    label: 'Сообщений',
                    value: totalMessages?.toString() ?? '—',
                    icon: Icons.message,
                  ),
                  if (mau != null && totalUsers != null && totalUsers > 0)
                    _StatCard(
                      label: 'Engagement (MAU/Users)',
                      value:
                          '${((mau / totalUsers) * 100).toStringAsFixed(1)} %',
                      icon: Icons.trending_up,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime? _parseTs(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Future<void> _recompute() async {
    setState(() {
      _busy = true;
      _lastResult = null;
    });
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('adminRecomputeStats')
          .call<dynamic>();
      setState(() {
        _lastResult = 'OK: ${res.data}';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Ошибка: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: c.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c.primary, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
