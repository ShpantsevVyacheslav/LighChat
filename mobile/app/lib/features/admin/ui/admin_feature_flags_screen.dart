import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags из `platformSettings/main.featureFlags` (паритет с
/// `src/components/admin/admin-feature-flags-panel.tsx`).
///
/// Каждый флаг: `{enabled: bool, description?: string}`. Toggle делается
/// прямой записью в Firestore — security rules должны разрешать
/// `request.auth.token.role in ['admin']` писать в `platformSettings/main`.
class AdminFeatureFlagsScreen extends ConsumerStatefulWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  ConsumerState<AdminFeatureFlagsScreen> createState() =>
      _AdminFeatureFlagsScreenState();
}

class _AdminFeatureFlagsScreenState
    extends ConsumerState<AdminFeatureFlagsScreen> {
  final _newNameCtrl = TextEditingController();
  final _newDescCtrl = TextEditingController();
  String? _busy;

  static const _docPath = 'platformSettings/main';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.doc(_docPath);

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _newDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _docRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final raw = (snap.data?.data()?['featureFlags'] as Map?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final entries = raw.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Column(
          children: [
            _AddFlagBar(
              nameController: _newNameCtrl,
              descController: _newDescCtrl,
              onAdd: _addFlag,
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Флагов пока нет'))
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final v = (e.value as Map?) ?? const {};
                        final enabled = v['enabled'] == true;
                        final desc = v['description'] as String? ?? '';
                        return SwitchListTile(
                          title: Text(e.key,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600)),
                          subtitle: desc.isNotEmpty ? Text(desc) : null,
                          value: enabled,
                          onChanged: _busy == e.key
                              ? null
                              : (v) => _toggle(e.key, v, desc),
                          secondary: _busy == e.key
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  tooltip: 'Удалить',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(e.key),
                                ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(String name, bool enabled, String description) async {
    setState(() => _busy = name);
    try {
      await _docRef.set(
        {
          'featureFlags': {
            name: {
              'enabled': enabled,
              if (description.isNotEmpty) 'description': description,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          }
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _addFlag() async {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) return;
    final desc = _newDescCtrl.text.trim();
    await _toggle(name, false, desc);
    _newNameCtrl.clear();
    _newDescCtrl.clear();
  }

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить флаг "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = name);
    try {
      await _docRef.set(
        {
          'featureFlags': {name: FieldValue.delete()},
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }
}

class _AddFlagBar extends StatelessWidget {
  const _AddFlagBar({
    required this.nameController,
    required this.descController,
    required this.onAdd,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя флага',
                hintText: 'enableSecretChats',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
