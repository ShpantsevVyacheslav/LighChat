import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/platform/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities (defaultPlatformCapabilities)', () {
    final caps = defaultPlatformCapabilities;

    test('идентификация: ровно один isMobile/isDesktop/isWeb true', () {
      final flags = <bool>[caps.isMobile, caps.isDesktop, caps.isWeb];
      expect(flags.where((f) => f).length, 1,
          reason: 'Должна быть выбрана одна семья платформы');
    });

    test('platformTag не "unknown" в тестовой среде', () {
      expect(caps.platformTag, isNot('unknown'));
    });

    test(
      'mobile-only фичи отключены на desktop',
      () {
        if (!caps.isDesktop) return;
        expect(caps.hasNativeCameraPlugin, false);
        expect(caps.hasSystemMediaGallery, false);
        expect(caps.canShareLiveLocation, false);
        expect(caps.incomingCallPresentation,
            IncomingCallPresentation.customDesktopWindow);
      },
    );

    test(
      'incomingCall на mobile — system call screen',
      () {
        if (!caps.isMobile) return;
        expect(caps.incomingCallPresentation,
            IncomingCallPresentation.systemCallScreen);
        expect(caps.hasSystemShareIntent, true);
      },
    );

    test('Apple-only image markup на iOS и macOS', () {
      if (caps.isIOS || caps.isMacOS) {
        expect(caps.imageMarkupKind, ImageMarkupKind.applePencil);
      }
      if (caps.isAndroid || caps.isWindows || caps.isLinux) {
        expect(caps.imageMarkupKind, ImageMarkupKind.flutterCanvas);
      }
    });

    test('pushTransport детерминирован для каждой платформы', () {
      if (caps.isWeb) {
        expect(caps.pushTransport, PushTransport.webPush);
      } else if (caps.isWindows || caps.isLinux) {
        expect(caps.pushTransport, PushTransport.firestoreFallback);
      } else {
        expect(caps.pushTransport, PushTransport.firebaseMessaging);
      }
    });
  });
}
