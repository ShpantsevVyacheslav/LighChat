import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Журнал админских действий из коллекции `adminAuditLog`.
///
/// Полный паритет с веб-панелью: actorName/action/target/details,
/// сортировка по createdAt desc, поиск по actor/action/target.id.
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('adminAuditLog')
        .orderBy('createdAt', descending: true)
        .limit(200);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по actor / action / target',
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
              final docs = _filter(snap.data?.docs ?? const [], _search.text);
              if (docs.isEmpty) {
                return const Center(child: Text('Записей нет'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _AuditEntryTile(doc: docs[i]),
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
      bool matches(Object? v) =>
          v is String && v.toLowerCase().contains(needle);
      final target = data['target'];
      return matches(data['actorName']) ||
          matches(data['actorId']) ||
          matches(data['action']) ||
          (target is Map && matches(target['id']));
    }).toList();
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final action = data['action'] as String? ?? '—';
    final actor = data['actorName'] as String? ?? data['actorId'] as String? ?? '?';
    final target = data['target'];
    final targetLabel = target is Map
        ? '${target['type'] ?? '?'}: ${target['id'] ?? '?'}'
        : '—';
    final details = data['details'];
    final createdAt = _parseDate(data['createdAt']);

    return ExpansionTile(
      title: Row(
        children: [
          _ActionBadge(action: action),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              targetLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          if (createdAt != null)
            Text(
              DateFormat('dd.MM HH:mm:ss').format(createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      subtitle: Text('actor: $actor'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (details is Map && details.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              details.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
      ],
    );
  }

  DateTime? _parseDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final String action;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final color = action.contains('block') || action.contains('delete')
        ? Colors.red
        : action.contains('reset')
            ? Colors.orange
            : c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
