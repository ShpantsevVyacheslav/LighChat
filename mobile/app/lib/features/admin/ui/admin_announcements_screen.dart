import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Объявления для рассылки в `announcements/`.
///
/// MVP: список существующих + быстрая публикация нового. Тип/таргетирование
/// по ролям — `info|warning|critical` без сегментации (полноценная сегментация
/// доступна в веб-версии через server action).
class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _type = 'info';
  bool _isActive = true;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Левая колонка: список существующих
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Активные и недавние',
                  style: Theme.of(context).textTheme.titleMedium,
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
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final docs = snap.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Объявлений нет'));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _AnnouncementTile(doc: docs[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Правая колонка: создание нового
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Новое объявление',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Заголовок',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Текст',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Тип',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                    DropdownMenuItem(value: 'warning', child: Text('Warning')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'info'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Опубликовано'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Опубликовать'),
                  onPressed: _busy ? null : _publish,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заголовок и тело обязательны')),
      );
      return;
    }
    setState(() => _busy = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final col = FirebaseFirestore.instance.collection('announcements');
    final doc = col.doc();
    try {
      await doc.set(<String, dynamic>{
        'id': doc.id,
        'title': title,
        'body': body,
        'type': _type,
        'isActive': _isActive,
        'priority': 0,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'createdBy': uid,
        'dismissible': true,
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Опубликовано')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title'] as String? ?? '—';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'info';
    final isActive = data['isActive'] == true;
    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : (createdAtRaw is Timestamp ? createdAtRaw.toDate() : null);

    final (color, label) = switch (type) {
      'warning' => (Colors.orange, 'warning'),
      'critical' => (Colors.red, 'critical'),
      _ => (Colors.blue, 'info'),
    };

    return ListTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, overflow: TextOverflow.ellipsis),
          ),
          if (!isActive)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.visibility_off, size: 16),
            ),
        ],
      ),
      subtitle: Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: createdAt != null
          ? Text(
              DateFormat('dd.MM HH:mm').format(createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () => _toggleActive(doc, !isActive),
    );
  }

  Future<void> _toggleActive(
      QueryDocumentSnapshot<Map<String, dynamic>> doc, bool active) async {
    await doc.reference.update(<String, dynamic>{'isActive': active});
  }
}
