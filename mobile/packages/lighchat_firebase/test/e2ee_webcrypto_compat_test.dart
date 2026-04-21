/// Самопроверки для E2EE v2 crypto-слоя.
///
/// Что это проверяет:
///  - sanity: генерация ключей, экспорт/импорт SPKI и PKCS#8, consistency
///    между ними;
///  - round-trip wrap/unwrap, encrypt/decrypt;
///  - AAD: изменение любого AAD-компонента ломает расшифровку (GCM tag fails).
///
/// Что НЕ проверяется здесь: бит-в-бит совместимость с WebCrypto. Это делается
/// в Phase 3b через shared test vectors (`docs/arcitecture/e2ee-v2-test-vectors.json`).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

void main() {
  group('E2EE v2 crypto primitives', () {
    test('generateEcdhP256KeyPair produces 64-byte raw public', () async {
      final kp = await generateEcdhP256KeyPair();
      final raw = kp.rawPublicUncompressed();
      expect(raw.length, 65);
      expect(raw[0], 0x04);
    });

    test('SPKI export → import roundtrip', () async {
      final kp = await generateEcdhP256KeyPair();
      final spki = await kp.exportSpkiPublic();
      final pub = await importSpkiP256(spki: spki);
      expect(pub.Q!.x!.toBigInteger(), kp.publicKey.Q!.x!.toBigInteger());
      expect(pub.Q!.y!.toBigInteger(), kp.publicKey.Q!.y!.toBigInteger());
    });

    test('PKCS8 export → import roundtrip', () async {
      final kp = await generateEcdhP256KeyPair();
      final pkcs8 = await kp.exportPkcs8Private();
      final back = await importPkcs8P256(pkcs8: pkcs8);
      expect(back.privateKey.d, kp.privateKey.d);
    });

    test('hkdfSha256 is deterministic', () async {
      final ikm = List<int>.filled(22, 0x0b);
      final salt = List<int>.generate(13, (i) => i);
      const info = 'lighchat/v2/wrap';
      final a = await hkdfSha256(
        ikm: ikm, salt: salt, info: info, lengthBytes: 32);
      final b = await hkdfSha256(
        ikm: ikm, salt: salt, info: info, lengthBytes: 32);
      expect(a, b);
      final c = await hkdfSha256(
        ikm: ikm, salt: salt, info: 'lighchat/v2/OTHER', lengthBytes: 32);
      expect(a == c, isFalse);
    });

    test('AES-GCM encrypt / decrypt roundtrip with AAD', () async {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = Uint8List.fromList(List<int>.generate(12, (i) => 0xa0 + i));
      final aad = buildAadV2(['lighchat/v2/wrap', 'cid:1', 'dev-A']);
      final plain = Uint8List.fromList(utf8.encode('Привет, GCM!'));
      final ct = await aesGcmEncryptV2(
        key: key,
        iv: iv,
        plaintext: plain,
        aad: aad,
      );
      expect(ct.length, plain.length + 16);
      final back = await aesGcmDecryptV2(
        key: key,
        iv: iv,
        ciphertextPlusTag: ct,
        aad: aad,
      );
      expect(back, plain);

      final wrongAad = buildAadV2(['lighchat/v2/wrap', 'cid:1', 'dev-B']);
      expect(
        () => aesGcmDecryptV2(
          key: key,
          iv: iv,
          ciphertextPlusTag: ct,
          aad: wrongAad,
        ),
        throwsA(anything),
      );
    });

    test('wrap / unwrap chat key roundtrip', () async {
      final kp = await generateEcdhP256KeyPair();
      final spki = await kp.exportSpkiPublic();
      final chatKey = randomChatKeyRawV2();
      final wrap = await wrapChatKeyForDeviceV2(
        chatKey32: chatKey,
        recipientPublicSpki: spki,
        epochId: 'conv-1:1',
        deviceId: 'test-device-01',
      );
      final unwrapped = await unwrapChatKeyForDeviceV2(
        wrap: wrap,
        recipientPrivateKey: kp.privateKey,
        epochId: 'conv-1:1',
        deviceId: 'test-device-01',
      );
      expect(unwrapped, chatKey);
    });

    test('message encrypt / decrypt with AAD roundtrip', () async {
      final chatKey = randomChatKeyRawV2();
      const aad = V2MessageAadContext(
        conversationId: 'conv-abc',
        messageId: 'msg-42',
        epoch: 3,
      );
      final ct = await encryptMessageV2(
        chatKey: chatKey,
        plaintextUtf8: '<p>Hello E2EE v2 mobile</p>',
        aad: aad,
      );
      final back = await decryptMessageV2(
        chatKey: chatKey,
        ivB64: ct.ivB64,
        ciphertextB64: ct.ciphertextB64,
        aad: aad,
      );
      expect(back, '<p>Hello E2EE v2 mobile</p>');

      expect(
        () => decryptMessageV2(
          chatKey: chatKey,
          ivB64: ct.ivB64,
          ciphertextB64: ct.ciphertextB64,
          aad: const V2MessageAadContext(
            conversationId: 'conv-abc',
            messageId: 'msg-42',
            epoch: 4,
          ),
        ),
        throwsA(anything),
      );
    });

    test('buildAadV2 uses 0x1F separator', () {
      final aad = buildAadV2(['a', 'b', 42]);
      expect(aad, Uint8List.fromList(utf8.encode('a\u001Fb\u001F42')));
    });
  });
}

