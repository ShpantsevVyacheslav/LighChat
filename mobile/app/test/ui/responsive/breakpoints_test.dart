import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/ui/responsive/breakpoints.dart';

void main() {
  group('LayoutSize.fromWidth', () {
    test('compact: < 600dp', () {
      expect(LayoutSize.fromWidth(0), LayoutSize.compact);
      expect(LayoutSize.fromWidth(599), LayoutSize.compact);
    });

    test('medium: 600–840dp', () {
      expect(LayoutSize.fromWidth(600), LayoutSize.medium);
      expect(LayoutSize.fromWidth(839), LayoutSize.medium);
    });

    test('expanded: 840–1200dp', () {
      expect(LayoutSize.fromWidth(840), LayoutSize.expanded);
      expect(LayoutSize.fromWidth(1199), LayoutSize.expanded);
    });

    test('large: ≥1200dp', () {
      expect(LayoutSize.fromWidth(1200), LayoutSize.large);
      expect(LayoutSize.fromWidth(2560), LayoutSize.large);
    });
  });

  group('LayoutSize predicates', () {
    test('isCompact', () {
      expect(LayoutSize.compact.isCompact, isTrue);
      expect(LayoutSize.medium.isCompact, isFalse);
      expect(LayoutSize.expanded.isCompact, isFalse);
      expect(LayoutSize.large.isCompact, isFalse);
    });

    test('isAtLeastMedium', () {
      expect(LayoutSize.compact.isAtLeastMedium, isFalse);
      expect(LayoutSize.medium.isAtLeastMedium, isTrue);
      expect(LayoutSize.expanded.isAtLeastMedium, isTrue);
      expect(LayoutSize.large.isAtLeastMedium, isTrue);
    });

    test('isAtLeastExpanded — порог master-detail рендеринга', () {
      expect(LayoutSize.compact.isAtLeastExpanded, isFalse);
      expect(LayoutSize.medium.isAtLeastExpanded, isFalse);
      expect(LayoutSize.expanded.isAtLeastExpanded, isTrue);
      expect(LayoutSize.large.isAtLeastExpanded, isTrue);
    });

    test('isLarge', () {
      expect(LayoutSize.compact.isLarge, isFalse);
      expect(LayoutSize.medium.isLarge, isFalse);
      expect(LayoutSize.expanded.isLarge, isFalse);
      expect(LayoutSize.large.isLarge, isTrue);
    });
  });
}
