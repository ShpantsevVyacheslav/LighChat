import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сводка по использованию Firebase Storage:
///   - Топ-30 беседы по агрегированному `storageBytes`
///     (поле `conversations/{cid}.storage.totalBytes`, поддерживается
///     onChatMessageMediaTranscode и related триггерами).
///   - Запуск ad-hoc пересчёта через `adminRecomputeStorageStats` callable.
class AdminStorageStatsScreen extends ConsumerStatefulWidget {
  const AdminStorageStatsScreen({super.key});

  @override
  ConsumerState<AdminStorageStatsScreen> createState() =>
      _AdminStorageStatsScreenState();
}

class _AdminStorageStatsScreenState
    extends ConsumerState<AdminStorageStatsScreen> {
  bool _recomputing = false;
  String? _recomputeResult;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('conversations')
        .orderBy('storage.totalBytes', descending: true)
        .limit(30);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Топ бесед по объёму медиа',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                icon: _recomputing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: const Text('Пересчитать'),
                onPressed: _recomputing ? null : _recompute,
              ),
            ],
          ),
        ),
        if (_recomputeResult != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(_recomputeResult!),
              ),
            ),
          ),
        const Divider(height: 24),
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
                    child: Text(
                      'Ошибка: ${snap.error}\n\nЕсли поле storage.totalBytes '
                      'не индексировано — создайте composite index в Firestore Console.',
                    ),
                  ),
                );
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(child: Text('Нет данных'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _ConversationStorageTile(doc: docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _recompute() async {
    setState(() {
      _recomputing = true;
      _recomputeResult = null;
    });
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('adminRecomputeStorageStats');
      final res = await callable.call<dynamic>();
      setState(() {
        _recomputeResult = 'OK: ${res.data}';
      });
    } catch (e) {
      setState(() {
        _recomputeResult = 'Ошибка: $e\n(Серверный callable '
            'adminRecomputeStorageStats должен быть задеплоен; пока недоступен '
            '— используйте веб-панель.)';
      });
    } finally {
      if (mounted) setState(() => _recomputing = false);
    }
  }
}

class _ConversationStorageTile extends StatelessWidget {
  const _ConversationStorageTile({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final storage = (data['storage'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final total = (storage['totalBytes'] as num?)?.toInt() ?? 0;
    final video = (storage['videoBytes'] as num?)?.toInt() ?? 0;
    final image = (storage['imageBytes'] as num?)?.toInt() ?? 0;
    final audio = (storage['audioBytes'] as num?)?.toInt() ?? 0;
    final file = (storage['fileBytes'] as num?)?.toInt() ?? 0;
    final title = data['name'] as String? ?? doc.id;
    final participants = data['participants'] as List? ?? [];

    return ListTile(
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Text(_formatBytes(total),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (video > 0) Text('video: ${_formatBytes(video)}'),
          if (image > 0) Text('image: ${_formatBytes(image)}'),
          if (audio > 0) Text('audio: ${_formatBytes(audio)}'),
          if (file > 0) Text('file: ${_formatBytes(file)}'),
        ],
      ),
      trailing: Text(
        '${participants.length}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
