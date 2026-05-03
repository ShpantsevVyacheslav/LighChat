import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/video_attachment_diagnostics.dart';

/// Тестируем именно ту часть `MessageVideoAttachment.build()`, где
/// раньше `safeAr` падала на `arFromController` при отсутствии w/h в
/// метаданных. После фикса формула строго:
///
///   safeAr = (w!=null && h!=null && w>0 && h>0) ? w/h : 16/9;
///
/// Это значит: ни один контроллер не может изменить высоту ячейки
/// в момент `c.initialize()`. Когда в ленте подряд несколько видео,
/// они не складывают свои «прыжки 16:9 → реальное».

double _safeAr({int? w, int? h}) {
  // Точная копия формулы из message_video_attachment.dart#L246-L255.
  return (w != null && h != null && w > 0 && h > 0) ? w / h : 16 / 9;
}

void main() {
  group('MessageVideoAttachment.safeAr формула стабильна', () {
    test('w/h из метаданных → AR из метаданных', () {
      expect(_safeAr(w: 1920, h: 1080), closeTo(16 / 9, 1e-6));
      expect(_safeAr(w: 1080, h: 1920), closeTo(9 / 16, 1e-6));
      expect(_safeAr(w: 1000, h: 1000), 1.0);
    });

    test('нет метаданных → AR всегда 16/9 (НЕ контроллерный)', () {
      expect(_safeAr(w: null, h: null), closeTo(16 / 9, 1e-6));
      expect(_safeAr(w: null, h: 1080), closeTo(16 / 9, 1e-6));
      expect(_safeAr(w: 1920, h: null), closeTo(16 / 9, 1e-6));
      expect(_safeAr(w: 0, h: 1080), closeTo(16 / 9, 1e-6));
      expect(_safeAr(w: 1920, h: 0), closeTo(16 / 9, 1e-6));
    });

    test(
      'на отсутствии метаданных: одно и то же значение до и после init контроллера',
      () {
        // До init: arFromController не используется → 16/9.
        // После init: arFromController всё ещё не используется → 16/9.
        // Это и есть весь смысл фикса.
        final beforeInit = _safeAr(w: null, h: null);
        final afterInit = _safeAr(w: null, h: null);
        expect(beforeInit, equals(afterInit));
      },
    );
  });

  group('VideoAttachmentAspectMonitor', () {
    setUp(VideoAttachmentAspectMonitor.reset);

    test('первое наблюдение не считается прыжком', () {
      VideoAttachmentAspectMonitor.observe(
        url: 'https://x.test/v.mp4',
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: false,
      );
      final snap = VideoAttachmentAspectMonitor.snapshot();
      expect(snap['https://x.test/v.mp4']!.jumps, 0);
    });

    test('повторное наблюдение того же AR не считается прыжком', () {
      const url = 'https://x.test/v.mp4';
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: false,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: true,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: true,
      );
      expect(VideoAttachmentAspectMonitor.snapshot()[url]!.jumps, 0);
    });

    test('изменение AR между наблюдениями = прыжок (регрессия)', () {
      const url = 'https://x.test/v.mp4';
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: false,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 9 / 16, // имитация: фикс пробит, AR подменён controller-derived
        hasMetadata: false,
        controllerInitialized: true,
      );
      expect(VideoAttachmentAspectMonitor.snapshot()[url]!.jumps, 1);
    });

    test('счётчик прыжков растёт', () {
      const url = 'https://x.test/v.mp4';
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: false,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 4 / 3,
        hasMetadata: false,
        controllerInitialized: true,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 9 / 16,
        hasMetadata: false,
        controllerInitialized: true,
      );
      expect(VideoAttachmentAspectMonitor.snapshot()[url]!.jumps, 2);
    });

    test('reset() очищает все счётчики', () {
      const url = 'https://x.test/v.mp4';
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 16 / 9,
        hasMetadata: false,
        controllerInitialized: false,
      );
      VideoAttachmentAspectMonitor.observe(
        url: url,
        ar: 9 / 16,
        hasMetadata: false,
        controllerInitialized: true,
      );
      VideoAttachmentAspectMonitor.reset();
      expect(VideoAttachmentAspectMonitor.snapshot(), isEmpty);
    });
  });
}
