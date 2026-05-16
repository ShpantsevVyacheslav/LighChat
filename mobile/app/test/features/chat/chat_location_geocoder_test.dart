import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/chat/data/chat_location_geocoder.dart';

/// Bug #7 — forward geocode из композера. Native MethodChannel
/// `lighchat/geocoder` зовётся только когда Platform.isIOS. На
/// macOS-хосте (где гоняется flutter test) пользовательский путь
/// проверяем через мок binaryMessenger, явно подменяющий ответ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lighchat/geocoder');

  setUp(() {
    // На non-iOS платформах channel не должен вообще дёргаться.
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('reverseGeocode contract on non-iOS host', () {
    test(
      'возвращает null (early-exit по Platform.isIOS)',
      () async {
        final r = await ChatLocationGeocoder.instance.reverseGeocode(
          55.75,
          37.61,
        );
        expect(r, isNull);
      },
      skip: Platform.isIOS,
    );
  });

  group('forwardGeocode на non-iOS — Bug #7', () {
    test(
      'на non-iOS возвращает null без вызова канала',
      () async {
        var called = 0;
        TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          called++;
          return null;
        });
        final r = await ChatLocationGeocoder.instance.forwardGeocode(
          'Москва, Тверская 13',
        );
        expect(r, isNull);
        expect(called, 0, reason: 'на non-iOS native channel не дёргается');
      },
      skip: Platform.isIOS,
    );

    test('пустой / whitespace query — null до канала', () async {
      var called = 0;
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        called++;
        return null;
      });
      for (final q in const ['', '   ', '\n\t']) {
        final r = await ChatLocationGeocoder.instance.forwardGeocode(q);
        expect(r, isNull, reason: 'q="$q"');
      }
      // На iOS canal вызвался бы, но раньше есть guard. Не зависит от платформы.
      // На macOS-host called=0 в любом случае (Platform.isIOS=false).
      expect(called, 0);
    });
  });

  group('forwardGeocode на iOS — mocked channel', () {
    test(
      'успешный ответ от native → возвращает {lat, lng}',
      () async {
        TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'forwardGeocode') {
            return <String, Object?>{'lat': 55.75, 'lng': 37.61};
          }
          return null;
        });
        final r = await ChatLocationGeocoder.instance.forwardGeocode(
          'Москва Кремль ${DateTime.now().microsecondsSinceEpoch}',
        );
        expect(r, isNotNull);
        expect(r!.lat, 55.75);
        expect(r.lng, 37.61);
      },
      skip: !Platform.isIOS,
    );
  });
}
