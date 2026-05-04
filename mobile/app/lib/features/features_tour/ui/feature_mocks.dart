import 'package:flutter/material.dart';

import '../data/features_data.dart';

/// Рамка-«экран» для мокапов: матовый фон + тонкая обводка + большой радиус.
/// Повторяет визуальный язык чатов LighChat (Card / glass).
class FeatureMockFrame extends StatelessWidget {
  const FeatureMockFrame({
    super.key,
    required this.child,
    this.aspectRatio = 16 / 10,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double aspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.10 : 0.06),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface.withValues(alpha: dark ? 0.55 : 0.85),
              scheme.surface.withValues(alpha: dark ? 0.30 : 0.65),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Lustre — лёгкий радиальный отблеск.
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.8),
                    radius: 1.2,
                    colors: [
                      featureAccentPrimary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _MockChatHeader extends StatelessWidget {
  const _MockChatHeader({
    required this.name,
    required this.status,
    this.withLock = false,
    this.timerLabel,
  });
  final String name;
  final String status;
  final bool withLock;
  final String? timerLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        color: scheme.surface.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: featureAccentPrimary,
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface)),
                    ),
                    if (withLock) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock_rounded, size: 11, color: featureAccentEmerald),
                    ],
                  ],
                ),
                Text(status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          if (timerLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: featureAccentViolet.withValues(alpha: 0.15),
                border: Border.all(color: featureAccentViolet.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timer_outlined, size: 10, color: featureAccentViolet),
                const SizedBox(width: 3),
                Text(timerLabel!,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: featureAccentViolet)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _MockBubble extends StatelessWidget {
  const _MockBubble({
    required this.text,
    required this.outgoing,
    this.fading = false,
    this.scheduled = false,
    this.scheduledHint,
    this.time = '12:34',
  });
  final String text;
  final bool outgoing;
  final bool fading;
  final bool scheduled;
  final String? scheduledHint;
  final String time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = outgoing ? featureAccentPrimary : scheme.surface.withValues(alpha: 0.85);
    final fg = outgoing ? Colors.white : scheme.onSurface;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: fading ? 0.55 : (scheduled ? 0.85 : 1.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: outgoing
                ? null
                : Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(outgoing ? 14 : 4),
              bottomRight: Radius.circular(outgoing ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: TextStyle(fontSize: 11, color: fg, height: 1.3)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (scheduled)
                  Icon(Icons.schedule_rounded, size: 9, color: fg.withValues(alpha: 0.7)),
                if (scheduled) const SizedBox(width: 2),
                if (fading)
                  Icon(Icons.visibility_off_outlined, size: 9, color: fg.withValues(alpha: 0.7)),
                if (fading) const SizedBox(width: 2),
                Text(time,
                    style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.7))),
              ]),
              if (scheduled && scheduledHint != null) ...[
                const SizedBox(height: 2),
                Text(scheduledHint!,
                    style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: fg.withValues(alpha: 0.7))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatLikeMock extends StatelessWidget {
  const _ChatLikeMock({required this.header, required this.bubbles, this.footer});
  final Widget header;
  final List<Widget> bubbles;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      header,
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (final b in bubbles) b,
              if (footer != null) ...[const Spacer(), footer!],
            ],
          ),
        ),
      ),
    ]);
  }
}

// ---------- Конкретные мокапы ----------

class MockEncryption extends StatelessWidget {
  const MockEncryption({super.key});
  @override
  Widget build(BuildContext context) {
    return _ChatLikeMock(
      header: const _MockChatHeader(name: 'Анна', status: 'онлайн · защищено', withLock: true),
      bubbles: const [
        _MockBubble(text: 'Привет! Это точно ты?', outgoing: false, time: '12:31'),
        _MockBubble(text: 'Я. Сравним отпечатки ключей.', outgoing: true, time: '12:32'),
        _MockBubble(text: 'Совпали — нас никто не слушает.', outgoing: false, time: '12:33'),
      ],
      footer: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: featureAccentEmerald.withValues(alpha: 0.15),
            border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_rounded, size: 12, color: featureAccentEmerald),
            const SizedBox(width: 4),
            Text('Отпечаток · 5F2A · 8B91',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: featureAccentEmerald)),
          ]),
        ),
      ),
    );
  }
}

class MockSecretChats extends StatelessWidget {
  const MockSecretChats({super.key});
  @override
  Widget build(BuildContext context) {
    return _ChatLikeMock(
      header: const _MockChatHeader(
          name: 'Группа · Проект',
          status: 'секретный · 6 участников',
          withLock: true,
          timerLabel: '1 ч'),
      bubbles: const [
        _MockBubble(text: 'Файл с ценой — пришлю одним просмотром.', outgoing: false, fading: true, time: '14:02'),
        _MockBubble(text: 'Принял. Запрет копии включён.', outgoing: true, time: '14:03'),
      ],
      footer: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: featureAccentViolet.withValues(alpha: 0.10),
              border: Border.all(color: featureAccentViolet.withValues(alpha: 0.30)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.timer_outlined, size: 12, color: featureAccentViolet),
              const SizedBox(width: 4),
              const Flexible(
                child: Text('Таймер 1 ч',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: featureAccentCoral.withValues(alpha: 0.10),
              border: Border.all(color: featureAccentCoral.withValues(alpha: 0.30)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.block_rounded, size: 12, color: featureAccentCoral),
              const SizedBox(width: 4),
              const Flexible(
                child: Text('Без пересылки',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class MockDisappearing extends StatelessWidget {
  const MockDisappearing({super.key});
  @override
  Widget build(BuildContext context) {
    return _ChatLikeMock(
      header: const _MockChatHeader(
          name: 'Команда · Дизайн', status: 'исчезают через 24 ч', timerLabel: '24 ч'),
      bubbles: const [
        _MockBubble(text: 'Делюсь черновиком — потом удалится.', outgoing: false, time: '09:14'),
        _MockBubble(text: 'Ок, дам комментарии до вечера.', outgoing: true, time: '09:15'),
        _MockBubble(text: 'Цвет хедера лучше тёмный.', outgoing: false, fading: true, time: '09:16'),
      ],
      footer: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: featureAccentCoral.withValues(alpha: 0.12),
            border: Border.all(color: featureAccentCoral.withValues(alpha: 0.30)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('Сообщения исчезают через 24 часа',
              style: TextStyle(fontSize: 10, color: featureAccentCoral, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class MockScheduled extends StatelessWidget {
  const MockScheduled({super.key});
  @override
  Widget build(BuildContext context) {
    return _ChatLikeMock(
      header: const _MockChatHeader(name: 'Михаил', status: 'был сегодня в 21:40'),
      bubbles: const [
        _MockBubble(text: 'Не забудь напомнить про планёрку.', outgoing: false, time: '20:11'),
        _MockBubble(text: 'Уже поставил на утро.', outgoing: true, time: '20:12'),
        _MockBubble(
          text: 'Доброе утро! Через 15 минут начинаем планёрку.',
          outgoing: true,
          scheduled: true,
          scheduledHint: 'Отправится завтра в 08:45',
          time: '08:45',
        ),
      ],
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: featureAccentPrimary.withValues(alpha: 0.10),
          border: Border.all(color: featureAccentPrimary.withValues(alpha: 0.30)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(Icons.schedule_rounded, size: 12, color: featureAccentPrimary),
          const SizedBox(width: 4),
          Text('В очереди · 1 сообщение',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: featureAccentPrimary)),
          const Spacer(),
          Text('завтра 08:45',
              style: TextStyle(fontSize: 10, color: featureAccentPrimary.withValues(alpha: 0.85))),
        ]),
      ),
    );
  }
}

class MockGames extends StatelessWidget {
  const MockGames({super.key});
  @override
  Widget build(BuildContext context) {
    final cards = ['6♠', '7♥', 'В♦', 'Д♣', 'К♠'];
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F5F47), Color(0xFF0F2D24)],
          ),
        ),
      ),
      Positioned(
        top: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: featureAccentAmber,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('Дурак · ход Анны',
              style: TextStyle(color: Color(0xFF3F2D00), fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ),
      Center(
        child: SizedBox(
          width: 220,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < cards.length; i++)
                Transform.translate(
                  offset: Offset((i - 2) * 28.0, -4),
                  child: Transform.rotate(
                    angle: (i - 2) * 0.20,
                    child: Container(
                      width: 50,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8)],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(cards[i],
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cards[i].contains('♥') || cards[i].contains('♦')
                                    ? Colors.red
                                    : Colors.black)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: 8,
        left: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Text('Козырь · ♥', style: TextStyle(color: Colors.white, fontSize: 10)),
            Spacer(),
            Text('В колоде · 12', style: TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
        ),
      ),
    ]);
  }
}

class MockMeetings extends StatelessWidget {
  const MockMeetings({super.key});
  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('А', const Color(0xFFB91C5C)),
      ('М', featureAccentPrimary),
      ('Ю', featureAccentEmerald),
      ('К', featureAccentViolet),
    ];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Встреча · 24:18',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.people_alt_outlined, size: 12),
            const SizedBox(width: 3),
            const Text('4', style: TextStyle(fontSize: 10)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              for (var i = 0; i < tiles.length; i++)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tiles[i].$2.withValues(alpha: 0.85), tiles[i].$2.withValues(alpha: 0.55)],
                    ),
                    border: Border.all(
                        color: i == 2
                            ? featureAccentEmerald.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.10),
                        width: i == 2 ? 2 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(tiles[i].$1,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class MockCalls extends StatelessWidget {
  const MockCalls({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: featureAccentEmerald.withValues(alpha: 0.10),
            border: Border.all(color: featureAccentEmerald.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            CircleAvatar(radius: 16, backgroundColor: featureAccentEmerald, child: const Text('А', style: TextStyle(color: Colors.white))),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Анна · аудио-звонок',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('3:42 · качество HD',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            for (final h in const <double>[4, 8, 12, 7, 10, 14, 6])
              Container(
                margin: const EdgeInsets.only(left: 1),
                width: 2,
                height: h,
                color: featureAccentEmerald,
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [featureAccentViolet, featureAccentPrimary],
            ),
            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 4),
          ),
          alignment: Alignment.center,
          child: const Text('М',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        const Text('Видео-кружок · 0:42 / 1:00', style: TextStyle(fontSize: 10)),
      ]),
    );
  }
}

class MockFoldersThreads extends StatelessWidget {
  const MockFoldersThreads({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final folders = [
      ('Все', 24, false),
      ('Работа', 8, true),
      ('Семья', 4, false),
      ('Учёба', 12, false),
    ];
    return Row(children: [
      Container(
        width: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.40),
          border: Border(right: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in folders)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: f.$3 ? featureAccentViolet.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: f.$3
                      ? Border.all(color: featureAccentViolet.withValues(alpha: 0.30))
                      : null,
                ),
                child: Row(children: [
                  Icon(f.$3 ? Icons.folder_open_rounded : Icons.folder_outlined,
                      size: 12,
                      color: f.$3 ? featureAccentViolet : scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(f.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: f.$3 ? featureAccentViolet : scheme.onSurface.withValues(alpha: 0.7))),
                  ),
                  Text('${f.$2}', style: TextStyle(fontSize: 9, color: scheme.onSurface.withValues(alpha: 0.55))),
                ]),
              ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('РАБОТА · ЧАТЫ',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.6)),
              const SizedBox(height: 6),
              for (final c in [
                ('Команда · Дизайн', 'Юля: пушнул новый вариант', 3),
                ('Маркетинг', 'Костя: отчёт готов', 0),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    CircleAvatar(radius: 12, backgroundColor: featureAccentPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          Text(c.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                    if (c.$3 > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: featureAccentPrimary, borderRadius: BorderRadius.circular(999)),
                        child: Text('${c.$3}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: featureAccentViolet.withValues(alpha: 0.08),
                  border: Border.all(color: featureAccentViolet.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: featureAccentViolet),
                  const SizedBox(width: 4),
                  Text('Тред · «Цена пакета»',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: featureAccentViolet)),
                ]),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class MockLiveLocation extends StatelessWidget {
  const MockLiveLocation({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [Color(0xFF6EC5E8), Color(0xFF1F4566)],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: featureAccentCoral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Делитесь геолокацией · ещё 14 мин',
                    style: TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: featureAccentCoral.withValues(alpha: 0.6),
                        blurRadius: 24,
                        spreadRadius: 4),
                  ],
                ),
                child: Icon(Icons.location_on_rounded, color: featureAccentCoral, size: 30),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: featureAccentCoral.withValues(alpha: 0.18),
                border: Border.all(color: featureAccentCoral.withValues(alpha: 0.40)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.stop_rounded, size: 14, color: featureAccentCoral),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Остановить трансляцию',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}

class MockMultiDevice extends StatelessWidget {
  const MockMultiDevice({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Phone
        Container(
          width: 70,
          height: 130,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Container(width: 24, height: 3, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 6),
              Icon(Icons.phone_iphone_rounded, color: featureAccentPrimary, size: 18),
              const SizedBox(height: 4),
              const Text('Подтвердите\nвход',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: 48,
                height: 48,
                color: Colors.white,
                child: GridView.count(
                  crossAxisCount: 6,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(2),
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  children: List.generate(36, (i) {
                    final on = ((i * 7) % 11) < 5 || (i % 7 == 0);
                    return Container(color: on ? Colors.black : Colors.white);
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 24, height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: featureAccentEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999)),
            child: Text('QR-паринг',
                style:
                    TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: featureAccentEmerald)),
          ),
          const SizedBox(height: 4),
          Container(width: 24, height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ]),
        const SizedBox(width: 10),
        // Laptop
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 130,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.desktop_mac_outlined, size: 10),
                  const SizedBox(width: 3),
                  const Text('LighChat · Desktop',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(children: [
                    Expanded(child: Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10))),
                    const SizedBox(width: 4),
                    Expanded(flex: 2, child: Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10))),
                  ]),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4))),
          ),
        ]),
      ]),
    );
  }
}

class MockStickersMedia extends StatelessWidget {
  const MockStickersMedia({super.key});
  @override
  Widget build(BuildContext context) {
    final faces = ['😀', '😎', '🤩', '😴', '😡', '🤔', '🥳', '😇'];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(children: [
            Icon(Icons.search_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text('поиск стикеров и GIF',
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const Spacer(),
            Icon(Icons.emoji_emotions_outlined, size: 14, color: featureAccentAmber),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < faces.length; i++)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: i.isEven
                          ? [featureAccentAmber, featureAccentCoral]
                          : [featureAccentViolet, featureAccentPrimary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(faces[i], style: const TextStyle(fontSize: 22)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class MockPrivacy extends StatelessWidget {
  const MockPrivacy({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget row(String label, String hint, bool on) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.6),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text(hint,
                    style: TextStyle(fontSize: 9, color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 16,
            decoration: BoxDecoration(
              color: on ? featureAccentPrimary : scheme.onSurface.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: featureAccentPrimary.withValues(alpha: 0.10),
            border: Border.all(color: featureAccentPrimary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.shield_outlined, size: 14, color: featureAccentPrimary),
            const SizedBox(width: 6),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Приватность', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('Решайте, что видят другие.', style: TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        row('Статус «онлайн»', 'Видят, что вы сейчас в сети', true),
        row('Был в сети', 'Точное время последнего визита', false),
        row('Отчёты о прочтении', 'Двойная галочка собеседнику', true),
      ]),
    );
  }
}

Widget buildFeatureMockFor(FeatureTopicId id) {
  switch (id) {
    case FeatureTopicId.encryption:
      return const MockEncryption();
    case FeatureTopicId.secretChats:
      return const MockSecretChats();
    case FeatureTopicId.disappearingMessages:
      return const MockDisappearing();
    case FeatureTopicId.scheduledMessages:
      return const MockScheduled();
    case FeatureTopicId.games:
      return const MockGames();
    case FeatureTopicId.meetings:
      return const MockMeetings();
    case FeatureTopicId.calls:
      return const MockCalls();
    case FeatureTopicId.foldersThreads:
      return const MockFoldersThreads();
    case FeatureTopicId.liveLocation:
      return const MockLiveLocation();
    case FeatureTopicId.multiDevice:
      return const MockMultiDevice();
    case FeatureTopicId.stickersMedia:
      return const MockStickersMedia();
    case FeatureTopicId.privacy:
      return const MockPrivacy();
  }
}
