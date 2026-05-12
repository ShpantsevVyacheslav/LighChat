import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Inbox обращений в поддержку (`supportTickets/`).
///
/// MVP: список + просмотр треда + быстрая смена статуса. Reply на тикет
/// сейчас доступен только через веб (server action `replyToTicketAction`).
class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() =>
      _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _selectedTicketId;
  String _statusFilter = 'open';

  @override
  Widget build(BuildContext context) {
    final ticketsQuery = (_statusFilter == 'all'
        ? FirebaseFirestore.instance.collection('supportTickets')
        : FirebaseFirestore.instance
            .collection('supportTickets')
            .where('status', isEqualTo: _statusFilter)
    ).orderBy('createdAt', descending: true).limit(100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'open', label: Text('Открытые')),
                    ButtonSegment(value: 'pending', label: Text('В работе')),
                    ButtonSegment(value: 'closed', label: Text('Закрытые')),
                    ButtonSegment(value: 'all', label: Text('Все')),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (s) =>
                      setState(() => _statusFilter = s.first),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ticketsQuery.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final docs = snap.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Тикетов нет'));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        return _TicketRow(
                          doc: doc,
                          selected: _selectedTicketId == doc.id,
                          onTap: () =>
                              setState(() => _selectedTicketId = doc.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _selectedTicketId == null
              ? const Center(child: Text('Выберите тикет'))
              : _TicketDetail(
                  ticketId: _selectedTicketId!,
                  key: ValueKey(_selectedTicketId),
                ),
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.doc, required this.selected, required this.onTap});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final subject = data['subject'] as String? ?? '(без темы)';
    final status = data['status'] as String? ?? 'open';
    final reporter = data['reporterName'] as String? ?? data['reporterId'] as String? ?? '';
    final createdAt = (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : (data['createdAt'] is String
            ? DateTime.tryParse(data['createdAt'] as String)
            : null);

    return ListTile(
      selected: selected,
      title: Text(subject, overflow: TextOverflow.ellipsis),
      subtitle: Text(reporter, overflow: TextOverflow.ellipsis),
      leading: _StatusDot(status: status),
      trailing: createdAt != null
          ? Text(DateFormat('dd.MM').format(createdAt),
              style: Theme.of(context).textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'open' => Colors.orange,
      'pending' => Colors.blue,
      'closed' => Colors.grey,
      _ => Colors.purple,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TicketDetail extends ConsumerStatefulWidget {
  const _TicketDetail({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<_TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends ConsumerState<_TicketDetail> {
  @override
  Widget build(BuildContext context) {
    final ticketRef =
        FirebaseFirestore.instance.collection('supportTickets').doc(widget.ticketId);
    final messages = ticketRef
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(200);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ticketRef.snapshots(),
      builder: (context, ticketSnap) {
        final data = ticketSnap.data?.data() ?? const {};
        final subject = data['subject'] as String? ?? '';
        final reporter = data['reporterName'] as String? ??
            data['reporterId'] as String? ??
            '';
        final status = data['status'] as String? ?? 'open';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(reporter,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Открыт')),
                      DropdownMenuItem(value: 'pending', child: Text('В работе')),
                      DropdownMenuItem(value: 'closed', child: Text('Закрыт')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ticketRef.update(<String, dynamic>{'status': v});
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: messages.snapshots(),
                builder: (context, msgSnap) {
                  if (msgSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = msgSnap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Сообщений нет'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final m = docs[i].data();
                      final from = m['from'] as String? ?? 'unknown';
                      final isAdmin = m['isAdmin'] == true || from == 'admin';
                      final text = m['text'] as String? ?? '';
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 480),
                          child: Card(
                            color: isAdmin
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(text),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ответ доступен в веб-админке (server action `replyToTicketAction`).',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      },
    );
  }
}
