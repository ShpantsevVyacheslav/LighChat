import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

const int _kMaxPollOptions = 12;

/// Нижняя шторка создания опроса (паритет веб `ChatAttachPollDialog`).
Future<ChatPollCreatePayload?> showChatPollCreateSheet(BuildContext context) {
  return showModalBottomSheet<ChatPollCreatePayload>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => const _ChatPollCreateSheet(),
  );
}

class _ChatPollCreateSheet extends StatefulWidget {
  const _ChatPollCreateSheet();

  @override
  State<_ChatPollCreateSheet> createState() => _ChatPollCreateSheetState();
}

class _ChatPollCreateSheetState extends State<_ChatPollCreateSheet> {
  final _questionCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _quizExplCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _anonymous = true;
  bool _allowMulti = false;
  bool _allowAddOpts = false;
  bool _allowRevote = true;
  bool _shuffle = false;
  bool _quiz = false;
  int _correctIdx = 0;
  DateTime? _closesAt;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _descCtrl.dispose();
    _quizExplCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _trimmedOptions() {
    return _optionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _publish() {
    final q = _questionCtrl.text.trim();
    final opts = _trimmedOptions();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите вопрос')),
      );
      return;
    }
    if (opts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нужно минимум 2 варианта')),
      );
      return;
    }
    if (_quiz) {
      if (_correctIdx < 0 || _correctIdx >= opts.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите правильный вариант')),
        );
        return;
      }
    }
    if (_closesAt != null && !_closesAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время закрытия должно быть в будущем')),
      );
      return;
    }

    final payload = ChatPollCreatePayload(
      question: q,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      options: opts,
      isAnonymous: _anonymous,
      allowMultipleAnswers: _allowMulti,
      allowAddingOptions: _allowAddOpts,
      allowRevoting: _allowRevote,
      shuffleOptions: _shuffle,
      quizMode: _quiz,
      correctOptionIndex: _quiz ? _correctIdx : null,
      quizExplanation: _quiz && _quizExplCtrl.text.trim().isNotEmpty
          ? _quizExplCtrl.text.trim()
          : null,
      closesAt: _closesAt,
    );
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final opts = _trimmedOptions();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            color: scheme.surface.withValues(alpha: 0.92),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Опрос в чате',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
                        shrinkWrap: true,
                        children: [
                          TextField(
                            controller: _questionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Вопрос',
                              hintText: 'Например: Во сколько встречаемся?',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Пояснение (необязательно)',
                            ),
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Варианты',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (var i = 0; i < _optionCtrls.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _optionCtrls[i],
                                      onChanged: (_) => setState(() {}),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: InputDecoration(
                                        hintText: 'Вариант ${i + 1}',
                                      ),
                                    ),
                                  ),
                                  if (_optionCtrls.length > 2)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _optionCtrls[i].dispose();
                                          _optionCtrls.removeAt(i);
                                          if (_correctIdx >= _optionCtrls.length) {
                                            _correctIdx = _optionCtrls.length - 1;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded),
                                    ),
                                ],
                              ),
                            ),
                          if (_optionCtrls.length < _kMaxPollOptions)
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _optionCtrls.add(TextEditingController()));
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Добавить вариант'),
                            ),
                          const SizedBox(height: 12),
                          _switchTile(
                            title: 'Анонимное голосование',
                            subtitle: 'Не показывать, кто за что голосовал',
                            value: _anonymous,
                            onChanged: (v) => setState(() => _anonymous = v),
                          ),
                          _switchTile(
                            title: 'Несколько ответов',
                            subtitle: 'Можно выбрать несколько вариантов',
                            value: _allowMulti,
                            onChanged: _quiz ? null : (v) => setState(() => _allowMulti = v),
                          ),
                          _switchTile(
                            title: 'Добавление вариантов',
                            subtitle: 'Участники могут предложить свой вариант',
                            value: _allowAddOpts,
                            onChanged: (v) => setState(() => _allowAddOpts = v),
                          ),
                          _switchTile(
                            title: 'Можно изменить голос',
                            subtitle: 'Переголосование до закрытия',
                            value: _allowRevote,
                            onChanged: (v) => setState(() => _allowRevote = v),
                          ),
                          _switchTile(
                            title: 'Перемешать варианты',
                            subtitle: 'Свой порядок у каждого участника',
                            value: _shuffle,
                            onChanged: (v) => setState(() => _shuffle = v),
                          ),
                          _switchTile(
                            title: 'Режим викторины',
                            subtitle: 'Один правильный ответ',
                            value: _quiz,
                            onChanged: (v) {
                              setState(() {
                                _quiz = v;
                                if (v) _allowMulti = false;
                              });
                            },
                          ),
                          if (_quiz && opts.length >= 2) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Правильный вариант',
                              ),
                              initialValue:
                                  _correctIdx.clamp(0, opts.length - 1),
                              items: [
                                for (var i = 0; i < opts.length; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      opts[i].length > 40
                                          ? '${opts[i].substring(0, 40)}…'
                                          : opts[i],
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _correctIdx = v);
                                }
                              },
                            ),
                            TextField(
                              controller: _quizExplCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Пояснение (необязательно)',
                              ),
                              maxLines: 2,
                            ),
                          ],
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Закрыть по времени'),
                            subtitle: Text(
                              _closesAt == null
                                  ? 'Не задано'
                                  : MaterialLocalizations.of(context).formatFullDate(_closesAt!),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.schedule_rounded),
                              onPressed: () async {
                                final now = DateTime.now();
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: now.add(const Duration(days: 1)),
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (!context.mounted || d == null) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
                                );
                                if (!context.mounted || t == null) return;
                                setState(() {
                                  _closesAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                });
                              },
                            ),
                          ),
                          if (_closesAt != null)
                            TextButton(
                              onPressed: () => setState(() => _closesAt = null),
                              child: const Text('Сбросить срок'),
                            ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _publish,
                            child: const Text('Опубликовать'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}
