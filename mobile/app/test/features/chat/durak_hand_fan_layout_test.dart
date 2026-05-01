import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/durak_hand_fan.dart';

void main() {
  testWidgets('DurakHandFan handles unconstrained width without exceptions', (
    tester,
  ) async {
    final keyById = <String, GlobalKey>{};
    final cards = <Map<String, dynamic>>[
      <String, dynamic>{'r': 6, 's': 'H'},
      <String, dynamic>{'r': 10, 's': 'S'},
      <String, dynamic>{'r': 14, 's': 'D'},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnconstrainedBox(
            child: DurakHandFan(
              cards: cards,
              cardId: (c, i) => '${c['s']}:${c['r']}#$i',
              keyForCardId: (id) => keyById.putIfAbsent(id, () => GlobalKey()),
              rankLabel: (c) => (c['r'] ?? '').toString(),
              suitLabel: (c) => (c['s'] ?? '').toString(),
              isRedSuit: (s) => s == 'H' || s == 'D',
              enabled: (_) => true,
              highlight: (_) => false,
              selectedId: null,
              onTap: (_, __) {},
              onDragStarted: null,
              onDragAcceptedByTable: (_) {},
              onDragRejected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
