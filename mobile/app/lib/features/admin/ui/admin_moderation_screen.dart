import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Очередь жалоб на сообщения (`messageReports`).
///
/// Реализован: список с фильтром по статусу, просмотр текста и автора.
/// Действия hide/dismiss требуют серверного callable (его сейчас в проекте
/// нет — есть только Next.js Server Actions), поэтому в этой версии
/// действия открывают веб-версию для finishing.
class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  _StatusFilter _filter = _StatusFilter.pending;

  @override
  Widget build(BuildContext context) {
    final query = _filter == _StatusFilter.all
        ? FirebaseFirestore.instance
            .collection('messageReports')
            .orderBy('createdAt', descending: true)
            .limit(100)
        : FirebaseFirestore.instance
            .collection('messageReports')
            .where('status', isEqualTo: _filter.firestoreValue)
            .orderBy('createdAt', descending: true)
            .limit(100);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_StatusFilter>(
            segments: _StatusFilter.values
                .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                .toList(),
            selected: {_filter},
            onSelectionChanged: (set) => setState(() => _filter = set.first),
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
              if (docs.isEmpty) {
                return const Center(child: Text('Жалоб нет'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _ReportTile(doc: docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final reason = data['reason'] as String? ?? '—';
    final status = data['status'] as String? ?? 'pending';
    final text = (data['messageText'] as String?)?.trim() ?? '';
    final author = data['messageSenderName'] as String? ??
        data['messageSenderId'] as String? ??
        '';
    final reporter = data['reporterName'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return ExpansionTile(
      title: Row(
        children: [
          _StatusBadge(status: status),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (createdAt != null)
            Text(
              DateFormat('dd.MM HH:mm').format(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      subtitle: Text(
        'Автор: $author • Жалоба: $reporter',
        overflow: TextOverflow.ellipsis,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (text.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Открыть в чате'),
              onPressed: () {
                final cid = data['conversationId'] as String?;
                if (cid != null && cid.isNotEmpty) {
                  Navigator.of(context).pushNamed('/chats/$cid');
                }
              },
            ),
            Text(
              'Полные действия (hide/dismiss) — в веб-админке',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      'pending' => (Colors.orange, 'pending'),
      'action_taken' => (Colors.red, 'action'),
      'dismissed' => (Colors.grey, 'dismissed'),
      'reviewed' => (Colors.blue, 'reviewed'),
      _ => (c.onSurfaceVariant, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _StatusFilter {
  pending('Pending', 'pending'),
  actionTaken('Action taken', 'action_taken'),
  dismissed('Dismissed', 'dismissed'),
  all('Все', 'all');

  const _StatusFilter(this.label, this.firestoreValue);
  final String label;
  final String firestoreValue;
}
