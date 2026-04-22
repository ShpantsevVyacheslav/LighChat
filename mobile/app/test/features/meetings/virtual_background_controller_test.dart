import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/meetings/data/virtual_background_controller.dart';
import 'package:lighchat_mobile/features/meetings/data/virtual_background_platform.dart';

/// Контракт контроллера виртуального фона.
///
/// Эти тесты фиксируют ожидания UI и `MeetingWebRtc`:
///   * noop всегда «видимо off» (isPlatformBacked == false);
///   * state-машина идемпотентна (повторный setMode не генерирует дубль event);
///   * MethodChannel-реализация шлёт корректный wire-формат и отдаёт ошибку
///     native обратно наверх.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoopVirtualBackgroundController', () {
    test('default state is VirtualBackgroundMode.none', () async {
      final c = NoopVirtualBackgroundController();
      expect(c.currentMode, VirtualBackgroundMode.none);
      expect(c.currentImageAssetPath, isNull);
      expect(c.isPlatformBacked, false);
      await c.dispose();
    });

    test('setMode transitions reflect in stream', () async {
      final c = NoopVirtualBackgroundController();
      final events = <VirtualBackgroundMode>[];
      final sub = c.modeStream.listen((u) => events.add(u.mode));
      await c.setMode(VirtualBackgroundMode.blur);
      await c.setMode(VirtualBackgroundMode.image, imageAssetPath: 'x.jpg');
      await c.setMode(VirtualBackgroundMode.none);
      await sub.cancel();
      expect(
        events,
        [
          VirtualBackgroundMode.blur,
          VirtualBackgroundMode.image,
          VirtualBackgroundMode.none,
        ],
      );
      expect(c.currentMode, VirtualBackgroundMode.none);
      await c.dispose();
    });

    test('setMode is idempotent for same args', () async {
      final c = NoopVirtualBackgroundController();
      final events = <VirtualBackgroundMode>[];
      final sub = c.modeStream.listen((u) => events.add(u.mode));
      await c.setMode(VirtualBackgroundMode.blur);
      await c.setMode(VirtualBackgroundMode.blur);
      await c.setMode(VirtualBackgroundMode.blur);
      await sub.cancel();
      expect(events, [VirtualBackgroundMode.blur]);
      await c.dispose();
    });
  });

  group('MethodChannelVirtualBackgroundController', () {
    const channel = MethodChannel('lighchat/virtual_background.test');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isPlatformBacked is true', () async {
      final c = MethodChannelVirtualBackgroundController(
        channelName: channel.name,
      );
      expect(c.isPlatformBacked, true);
      await c.dispose();
    });

    test('setMode forwards correct wire args', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final c = MethodChannelVirtualBackgroundController(
        channelName: channel.name,
      );
      await c.setMode(VirtualBackgroundMode.blur);
      await c.setMode(
        VirtualBackgroundMode.image,
        imageAssetPath: 'assets/bg.png',
      );
      await c.dispose();

      // setMode + setMode + dispose
      expect(calls.map((e) => e.method).toList(),
          ['setMode', 'setMode', 'dispose']);
      expect(calls[0].arguments, <String, Object?>{'mode': 'blur'});
      expect(calls[1].arguments, <String, Object?>{
        'mode': 'image',
        'imageAssetPath': 'assets/bg.png',
      });
    });

    test('native error resets state to none and rethrows', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'invalid_mode');
      });
      final c = MethodChannelVirtualBackgroundController(
        channelName: channel.name,
      );
      final events = <VirtualBackgroundMode>[];
      final sub = c.modeStream.listen((u) => events.add(u.mode));
      await expectLater(
        c.setMode(VirtualBackgroundMode.blur),
        throwsA(isA<PlatformException>()),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, [VirtualBackgroundMode.none]);
      expect(c.currentMode, VirtualBackgroundMode.none);
      await c.dispose();
    });

    test('same args do not re-emit native call', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final c = MethodChannelVirtualBackgroundController(
        channelName: channel.name,
      );
      await c.setMode(VirtualBackgroundMode.blur);
      await c.setMode(VirtualBackgroundMode.blur);
      await c.dispose();
      expect(
        calls.where((e) => e.method == 'setMode').length,
        1,
        reason: 'duplicate setMode should be debounced at Dart level',
      );
    });
  });
}
