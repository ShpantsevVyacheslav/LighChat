/// E2EE v2 — WebCrypto-совместимый слой для Flutter.
///
/// Функции этого модуля дают **бит-в-бит те же** результаты, что и
/// `src/lib/e2ee/v2/webcrypto-v2.ts`. Проверяется тестовыми векторами
/// `docs/arcitecture/e2ee-v2-test-vectors.json`.
///
/// Под капотом — `pointycastle` (pure Dart, BouncyCastle-порт). Выбор
/// мотивирован тем, что альтернатива (`cryptography` 2.9) в pure-Dart режиме
/// бросает `UnimplementedError` на `Ecdh.p256` — непригодна для мобайла.
///
/// Совместимость с WebCrypto гарантируется вручную:
///   - AES-GCM: 12-байтный IV, 128-битный тег, output = `ct || tag`.
///   - ECDH P-256: shared secret = X-координата, 32-байтное big-endian.
///   - HKDF-SHA-256 — стандартный RFC 5869.
///   - SPKI/PKCS#8: минимальный DER, идентичный тому, что генерит
///     `crypto.subtle.exportKey('spki'|'pkcs8')` на secp256r1.
library;

import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

const String _aadSep = '\u001F';

/// Публичные константы — именованы так же, как в TS.
const int aesKeyBitsV2 = 256;
const int gcmTagBitsV2 = 128;
const int gcmIvBytes = 12;
const String v2Protocol = 'v2-p256-aesgcm-multi';
const String v2WrapContext = 'lighchat/v2/session';
const String v2WrapInfo = 'lighchat/v2/wrap';
const String v2MsgAadContext = 'msg/v2';
const String v2MediaWrapInfo = 'lighchat/v2/media-wrap';

final ECDomainParameters _p256 = ECDomainParameters('prime256v1');
const int _p256CoordinateBytes = 32;

SecureRandom? _prngOverride;

/// Единственный источник криптостойких случайных байт. Выделен в функцию
/// для возможности детерминированного теста (`debugOverridePrng`).
Uint8List randomBytes(int n) {
  final rnd = _prngOverride;
  if (rnd != null) {
    return rnd.nextBytes(n);
  }
  final r = Random.secure();
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = r.nextInt(256);
  }
  return out;
}

/// ТОЛЬКО для тестов: подменить SecureRandom на детерминированный. Передавайте
/// `null`, чтобы вернуться к `Random.secure()`.
void debugOverridePrng(SecureRandom? prng) {
  _prngOverride = prng;
}

/// Собирает AAD из строк/чисел, идентично TS `buildAad` — join через 0x1F.
Uint8List buildAadV2(List<Object> parts) {
  final joined = parts.map((p) => p.toString()).join(_aadSep);
  return Uint8List.fromList(utf8.encode(joined));
}

/// HKDF-SHA-256. Семантика параметров полностью идентична TS `hkdfSha256`.
Future<Uint8List> hkdfSha256({
  required List<int> ikm,
  required List<int> salt,
  required String info,
  required int lengthBytes,
}) async {
  final hkdf = HKDFKeyDerivator(SHA256Digest());
  hkdf.init(HkdfParameters(
    Uint8List.fromList(ikm),
    lengthBytes,
    Uint8List.fromList(salt),
    Uint8List.fromList(utf8.encode(info)),
  ));
  final out = Uint8List(lengthBytes);
  hkdf.deriveKey(Uint8List(0), 0, out, 0);
  return out;
}

/// AES-256-GCM encrypt. Возвращает `ct || tag` (так же, как WebCrypto).
Future<Uint8List> aesGcmEncryptV2({
  required Uint8List key,
  required Uint8List iv,
  required Uint8List plaintext,
  Uint8List? aad,
}) async {
  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      true,
      AEADParameters(
        KeyParameter(key),
        gcmTagBitsV2,
        iv,
        aad ?? Uint8List(0),
      ),
    );
  return cipher.process(plaintext);
}

Future<Uint8List> aesGcmDecryptV2({
  required Uint8List key,
  required Uint8List iv,
  required Uint8List ciphertextPlusTag,
  Uint8List? aad,
}) async {
  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(
        KeyParameter(key),
        gcmTagBitsV2,
        iv,
        aad ?? Uint8List(0),
      ),
    );
  return cipher.process(ciphertextPlusTag);
}

// -----------------------------------------------------------------------------
// ECDH P-256 keypair + SPKI/PKCS#8 совместимость с WebCrypto.
// -----------------------------------------------------------------------------

class EcdhP256KeyPair {
  EcdhP256KeyPair({required this.privateKey, required this.publicKey});

  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;

  /// Сырой публичник (0x04 || X || Y, 65 байт, не-сжатый).
  Uint8List rawPublicUncompressed() {
    final q = publicKey.Q!;
    final x = _bigIntToUnsignedBytes(q.x!.toBigInteger()!, _p256CoordinateBytes);
    final y = _bigIntToUnsignedBytes(q.y!.toBigInteger()!, _p256CoordinateBytes);
    final out = Uint8List(1 + x.length + y.length);
    out[0] = 0x04;
    out.setRange(1, 1 + x.length, x);
    out.setRange(1 + x.length, out.length, y);
    return out;
  }

  /// Raw d, 32-байтное big-endian (приватник).
  Uint8List rawPrivateD() {
    return _bigIntToUnsignedBytes(privateKey.d!, _p256CoordinateBytes);
  }

  /// Экспорт публичника в WebCrypto-совместимый SPKI DER.
  Future<Uint8List> exportSpkiPublic() async {
    return wrapSpkiP256(rawPublicUncompressed());
  }

  /// Экспорт приватника в WebCrypto-совместимый PKCS#8 DER.
  Future<Uint8List> exportPkcs8Private() async {
    return wrapPkcs8P256(rawPrivateD(), rawPublicUncompressed());
  }
}

/// SecureRandom-обёртка над dart:math.Random.secure для pointycastle.
SecureRandom _pcSecureRandom() {
  final rnd = FortunaRandom();
  final seed = Uint8List(32);
  final r = Random.secure();
  for (var i = 0; i < seed.length; i++) {
    seed[i] = r.nextInt(256);
  }
  rnd.seed(KeyParameter(seed));
  return rnd;
}

Future<EcdhP256KeyPair> generateEcdhP256KeyPair() async {
  final keyGen = KeyGenerator('EC')
    ..init(
      ParametersWithRandom(
        ECKeyGeneratorParameters(_p256),
        _pcSecureRandom(),
      ),
    );
  final pair = keyGen.generateKeyPair();
  return EcdhP256KeyPair(
    privateKey: pair.privateKey as ECPrivateKey,
    publicKey: pair.publicKey as ECPublicKey,
  );
}

Future<ECPublicKey> importSpkiP256({required Uint8List spki}) async {
  final raw = unwrapSpkiP256(spki);
  return _ecPublicFromRawXY(raw);
}

Future<EcdhP256KeyPair> importPkcs8P256({required Uint8List pkcs8}) async {
  final parts = unwrapPkcs8P256(pkcs8);
  final dBig = _bigIntFromUnsignedBytes(parts.privRaw);
  final priv = ECPrivateKey(dBig, _p256);
  final pub = _ecPublicFromRawXY(parts.pubRaw);
  // Cross-check: derive pub from priv и сверяем.
  final derivedPub = _p256.G * dBig;
  if (derivedPub == null ||
      derivedPub.x!.toBigInteger() != pub.Q!.x!.toBigInteger() ||
      derivedPub.y!.toBigInteger() != pub.Q!.y!.toBigInteger()) {
    throw StateError(
      'E2EE v2: PKCS#8 public key mismatch — приватник и публичник не совпадают',
    );
  }
  return EcdhP256KeyPair(privateKey: priv, publicKey: pub);
}

ECPublicKey _ecPublicFromRawXY(Uint8List raw) {
  if (raw.length != 64) {
    throw StateError('SPKI raw public key must be 64 bytes (X||Y), got ${raw.length}');
  }
  final x = _bigIntFromUnsignedBytes(raw.sublist(0, _p256CoordinateBytes));
  final y = _bigIntFromUnsignedBytes(raw.sublist(_p256CoordinateBytes));
  final point = _p256.curve.createPoint(x, y);
  return ECPublicKey(point, _p256);
}

Future<Uint8List> ecdhP256DeriveBits32({
  required ECPrivateKey privateKey,
  required ECPublicKey remotePublic,
}) async {
  final agree = ECDHBasicAgreement()..init(privateKey);
  final z = agree.calculateAgreement(remotePublic);
  return _bigIntToUnsignedBytes(z, _p256CoordinateBytes);
}

// -----------------------------------------------------------------------------
// Высокоуровневые wrap / encrypt операции (зеркало TS v2).
// -----------------------------------------------------------------------------

class WrapEntryBase64 {
  const WrapEntryBase64({
    required this.ephPub,
    required this.iv,
    required this.ct,
  });

  final String ephPub;
  final String iv;
  final String ct;

  Map<String, Object?> toJson() => {'ephPub': ephPub, 'iv': iv, 'ct': ct};

  factory WrapEntryBase64.fromJson(Map<String, Object?> json) =>
      WrapEntryBase64(
        ephPub: (json['ephPub'] as String?) ?? '',
        iv: (json['iv'] as String?) ?? '',
        ct: (json['ct'] as String?) ?? '',
      );
}

Future<WrapEntryBase64> wrapChatKeyForDeviceV2({
  required Uint8List chatKey32,
  required Uint8List recipientPublicSpki,
  required String epochId,
  required String deviceId,
}) async {
  final eph = await generateEcdhP256KeyPair();
  final recipient = await importSpkiP256(spki: recipientPublicSpki);
  final z = await ecdhP256DeriveBits32(
    privateKey: eph.privateKey,
    remotePublic: recipient,
  );
  final salt = Uint8List.fromList(utf8.encode('$epochId|$deviceId'));
  final wrapKey = await hkdfSha256(
    ikm: z,
    salt: salt,
    info: v2WrapInfo,
    lengthBytes: 32,
  );
  final iv = randomBytes(gcmIvBytes);
  final aad = buildAadV2([v2WrapInfo, epochId, deviceId]);
  final ct = await aesGcmEncryptV2(
    key: wrapKey,
    iv: iv,
    plaintext: chatKey32,
    aad: aad,
  );
  final ephSpki = await eph.exportSpkiPublic();
  return WrapEntryBase64(
    ephPub: base64.encode(ephSpki),
    iv: base64.encode(iv),
    ct: base64.encode(ct),
  );
}

Future<Uint8List> unwrapChatKeyForDeviceV2({
  required WrapEntryBase64 wrap,
  required ECPrivateKey recipientPrivateKey,
  required String epochId,
  required String deviceId,
}) async {
  final ephSpkiBytes = Uint8List.fromList(base64.decode(wrap.ephPub));
  final ephPub = await importSpkiP256(spki: ephSpkiBytes);
  final z = await ecdhP256DeriveBits32(
    privateKey: recipientPrivateKey,
    remotePublic: ephPub,
  );
  final salt = Uint8List.fromList(utf8.encode('$epochId|$deviceId'));
  final wrapKey = await hkdfSha256(
    ikm: z,
    salt: salt,
    info: v2WrapInfo,
    lengthBytes: 32,
  );
  final aad = buildAadV2([v2WrapInfo, epochId, deviceId]);
  return aesGcmDecryptV2(
    key: wrapKey,
    iv: Uint8List.fromList(base64.decode(wrap.iv)),
    ciphertextPlusTag: Uint8List.fromList(base64.decode(wrap.ct)),
    aad: aad,
  );
}

class V2MessageAadContext {
  const V2MessageAadContext({
    required this.conversationId,
    required this.messageId,
    required this.epoch,
  });

  final String conversationId;
  final String messageId;
  final int epoch;
}

class MessageCiphertext {
  const MessageCiphertext({required this.ivB64, required this.ciphertextB64});
  final String ivB64;
  final String ciphertextB64;
}

Future<MessageCiphertext> encryptMessageV2({
  required Uint8List chatKey,
  required String plaintextUtf8,
  required V2MessageAadContext aad,
}) async {
  final iv = randomBytes(gcmIvBytes);
  final aadBytes = buildAadV2([
    v2MsgAadContext,
    aad.conversationId,
    aad.messageId,
    aad.epoch,
  ]);
  final ct = await aesGcmEncryptV2(
    key: chatKey,
    iv: iv,
    plaintext: Uint8List.fromList(utf8.encode(plaintextUtf8)),
    aad: aadBytes,
  );
  return MessageCiphertext(
    ivB64: base64.encode(iv),
    ciphertextB64: base64.encode(ct),
  );
}

Future<String> decryptMessageV2({
  required Uint8List chatKey,
  required String ivB64,
  required String ciphertextB64,
  required V2MessageAadContext aad,
}) async {
  final aadBytes = buildAadV2([
    v2MsgAadContext,
    aad.conversationId,
    aad.messageId,
    aad.epoch,
  ]);
  final plain = await aesGcmDecryptV2(
    key: chatKey,
    iv: Uint8List.fromList(base64.decode(ivB64)),
    ciphertextPlusTag: Uint8List.fromList(base64.decode(ciphertextB64)),
    aad: aadBytes,
  );
  return utf8.decode(plain);
}

Uint8List randomChatKeyRawV2() => randomBytes(32);

// -----------------------------------------------------------------------------
// SPKI / PKCS#8 (DER) упаковка для P-256 — минимальная реализация без asn1lib.
// Формат совпадает с `crypto.subtle.exportKey('spki'|'pkcs8')` на secp256r1.
// -----------------------------------------------------------------------------

const List<int> _oidEcPublicKey = <int>[
  0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01,
];

const List<int> _oidP256 = <int>[
  0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07,
];

Uint8List _derSequence(List<int> inner) =>
    Uint8List.fromList([0x30, ..._derLength(inner.length), ...inner]);

Uint8List _derInteger(List<int> bytes) {
  final b = List<int>.from(bytes);
  if (b.isNotEmpty && (b.first & 0x80) != 0) b.insert(0, 0x00);
  return Uint8List.fromList([0x02, ..._derLength(b.length), ...b]);
}

Uint8List _derOctetString(List<int> bytes) =>
    Uint8List.fromList([0x04, ..._derLength(bytes.length), ...bytes]);

Uint8List _derBitString(List<int> bytes, {int unusedBits = 0}) =>
    Uint8List.fromList([
      0x03,
      ..._derLength(bytes.length + 1),
      unusedBits,
      ...bytes,
    ]);

List<int> _derLength(int n) {
  if (n < 0x80) return <int>[n];
  final bytes = <int>[];
  var v = n;
  while (v > 0) {
    bytes.insert(0, v & 0xff);
    v >>= 8;
  }
  return <int>[0x80 | bytes.length, ...bytes];
}

Uint8List wrapSpkiP256(Uint8List rawPublic) {
  Uint8List uncompressed;
  if (rawPublic.length == 65 && rawPublic[0] == 0x04) {
    uncompressed = rawPublic;
  } else if (rawPublic.length == 64) {
    uncompressed = Uint8List(65);
    uncompressed[0] = 0x04;
    uncompressed.setRange(1, 65, rawPublic);
  } else {
    throw ArgumentError(
      'Unsupported P-256 public key length: ${rawPublic.length}',
    );
  }
  final algorithmId = _derSequence([..._oidEcPublicKey, ..._oidP256]);
  final bitString = _derBitString(uncompressed);
  return _derSequence([...algorithmId, ...bitString]);
}

Uint8List unwrapSpkiP256(Uint8List spki) {
  var i = 0;
  i = _expectTag(spki, i, 0x30);
  i = _skipLength(spki, i);
  i = _expectTag(spki, i, 0x30);
  final algLen = _readLength(spki, i);
  i += _lengthByteCount(spki, i) + algLen;
  i = _expectTag(spki, i, 0x03);
  final bitLen = _readLength(spki, i);
  final bitStart = i + _lengthByteCount(spki, i);
  if (spki[bitStart] != 0) {
    throw StateError('SPKI: unsupported unused-bits=${spki[bitStart]}');
  }
  final pubStart = bitStart + 1;
  final pubEnd = bitStart + bitLen;
  final pub = spki.sublist(pubStart, pubEnd);
  if (pub.length == 65 && pub[0] == 0x04) {
    return Uint8List.fromList(pub.sublist(1));
  }
  if (pub.length == 64) return Uint8List.fromList(pub);
  throw StateError('SPKI: unexpected public key length ${pub.length}');
}

class Pkcs8Parts {
  const Pkcs8Parts({required this.privRaw, required this.pubRaw});
  final Uint8List privRaw;
  final Uint8List pubRaw;
}

Uint8List wrapPkcs8P256(Uint8List privRaw, Uint8List pubRaw) {
  Uint8List d;
  if (privRaw.length == 32) {
    d = privRaw;
  } else {
    d = Uint8List(32);
    d.setRange(32 - privRaw.length, 32, privRaw);
  }
  Uint8List pubUncompressed;
  if (pubRaw.length == 65 && pubRaw[0] == 0x04) {
    pubUncompressed = pubRaw;
  } else if (pubRaw.length == 64) {
    pubUncompressed = Uint8List(65);
    pubUncompressed[0] = 0x04;
    pubUncompressed.setRange(1, 65, pubRaw);
  } else {
    throw ArgumentError(
      'Unsupported P-256 public key length: ${pubRaw.length}',
    );
  }
  // ECPrivateKey (RFC 5915):
  //   SEQUENCE {
  //     INTEGER 1,
  //     OCTET STRING d,
  //     [1] EXPLICIT BIT STRING publicKey
  //   }
  final pubBitString = _derBitString(pubUncompressed);
  final ecPrivateKeyInner = <int>[
    ..._derInteger([0x01]),
    ..._derOctetString(d),
    0xa1,
    ..._derLength(pubBitString.length),
    ...pubBitString,
  ];
  final ecPrivateKey = _derSequence(ecPrivateKeyInner);
  final algorithmId = _derSequence([..._oidEcPublicKey, ..._oidP256]);
  final privOctet = _derOctetString(ecPrivateKey);
  final outer = <int>[
    ..._derInteger([0x00]),
    ...algorithmId,
    ...privOctet,
  ];
  return _derSequence(outer);
}

Pkcs8Parts unwrapPkcs8P256(Uint8List pkcs8) {
  var i = 0;
  i = _expectTag(pkcs8, i, 0x30);
  i = _skipLength(pkcs8, i);
  i = _expectTag(pkcs8, i, 0x02);
  final verLen = _readLength(pkcs8, i);
  i += _lengthByteCount(pkcs8, i) + verLen;
  i = _expectTag(pkcs8, i, 0x30);
  final algLen = _readLength(pkcs8, i);
  i += _lengthByteCount(pkcs8, i) + algLen;
  i = _expectTag(pkcs8, i, 0x04);
  final ecpkLen = _readLength(pkcs8, i);
  final ecpkStart = i + _lengthByteCount(pkcs8, i);
  final ecpk = pkcs8.sublist(ecpkStart, ecpkStart + ecpkLen);
  var j = 0;
  j = _expectTag(ecpk, j, 0x30);
  j = _skipLength(ecpk, j);
  j = _expectTag(ecpk, j, 0x02);
  final vLen = _readLength(ecpk, j);
  j += _lengthByteCount(ecpk, j) + vLen;
  j = _expectTag(ecpk, j, 0x04);
  final dLen = _readLength(ecpk, j);
  final dStart = j + _lengthByteCount(ecpk, j);
  final d = ecpk.sublist(dStart, dStart + dLen);
  j = dStart + dLen;
  while (j < ecpk.length && ecpk[j] != 0xa1) {
    final skipLen = _readLength(ecpk, j + 1);
    j += 1 + _lengthByteCount(ecpk, j + 1) + skipLen;
  }
  if (j >= ecpk.length) {
    throw StateError('PKCS8: missing [1] public key part');
  }
  j = _expectTag(ecpk, j, 0xa1);
  j = _skipLength(ecpk, j);
  j = _expectTag(ecpk, j, 0x03);
  final bitLen = _readLength(ecpk, j);
  final bitStart = j + _lengthByteCount(ecpk, j);
  final pubStart = bitStart + 1;
  final pubEnd = bitStart + bitLen;
  final pub = ecpk.sublist(pubStart, pubEnd);
  final pubRaw = (pub.length == 65 && pub[0] == 0x04)
      ? Uint8List.fromList(pub.sublist(1))
      : Uint8List.fromList(pub);
  Uint8List paddedD = d.length == 32
      ? Uint8List.fromList(d)
      : (() {
          final out = Uint8List(32);
          out.setRange(32 - d.length, 32, d);
          return out;
        })();
  return Pkcs8Parts(privRaw: paddedD, pubRaw: pubRaw);
}

int _expectTag(Uint8List buf, int i, int tag) {
  if (i >= buf.length) {
    throw StateError('DER: EOF at $i expecting tag 0x${tag.toRadixString(16)}');
  }
  if (buf[i] != tag) {
    throw StateError(
      'DER: expected 0x${tag.toRadixString(16)} at $i, got 0x${buf[i].toRadixString(16)}',
    );
  }
  return i + 1;
}

int _skipLength(Uint8List buf, int i) => i + _lengthByteCount(buf, i);

int _readLength(Uint8List buf, int i) {
  final b = buf[i];
  if (b < 0x80) return b;
  final n = b & 0x7f;
  var v = 0;
  for (var k = 0; k < n; k++) {
    v = (v << 8) | buf[i + 1 + k];
  }
  return v;
}

int _lengthByteCount(Uint8List buf, int i) {
  final b = buf[i];
  return b < 0x80 ? 1 : 1 + (b & 0x7f);
}

// -----------------------------------------------------------------------------
// BigInt <-> unsigned big-endian bytes.
// -----------------------------------------------------------------------------

Uint8List _bigIntToUnsignedBytes(BigInt value, int width) {
  if (value.isNegative) {
    throw ArgumentError('Expected non-negative BigInt for key material');
  }
  final out = Uint8List(width);
  var v = value;
  for (var i = width - 1; i >= 0 && v > BigInt.zero; i--) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v = v >> 8;
  }
  if (v > BigInt.zero) {
    throw ArgumentError(
      'BigInt does not fit into $width bytes (would overflow)',
    );
  }
  return out;
}

BigInt _bigIntFromUnsignedBytes(Uint8List bytes) {
  var r = BigInt.zero;
  for (final b in bytes) {
    r = (r << 8) | BigInt.from(b & 0xff);
  }
  return r;
}
