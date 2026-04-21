# E2EE v2 — Multi‑device + Media — Protocol RFC

- Статус: **DRAFT**, на ревью (Phase 1 из плана «E2EE v2 — Multi‑device + Media, Path C»).
- Версия протокола: `v2-p256-aesgcm-multi`.
- Владелец: LighChat Core.
- Связанные документы: [`03-firestore-model.md`](./03-firestore-model.md), [`04-runtime-flows.md`](./04-runtime-flows.md), [`05-integrations.md`](./05-integrations.md).

> Файл `06-*.md` занят agent‑policy, поэтому этот RFC получил номер `07-`. При следующем ревью нумерации можно будет переименовать.

## 0. TL;DR

- Переходим с одного ключа на пользователя (v1) к **одному ключу на устройство** (v2). Добавляем **multi‑recipient wrapping**: session‑doc содержит `wraps[userId][deviceId]`, и отправитель обёртывает chat‑key отдельно под каждое активное устройство каждого участника.
- Протокол остаётся на **ECDH P‑256 + AES‑256‑GCM** (WebCrypto‑совместимо, Dart реализуется через `cryptography`). Новые кирпичики: **HKDF‑SHA‑256** для derivation контекста session/media, **Argon2id** для password‑backup.
- Медиа шифруются клиентом, кроме стикеров и GIF. Cloud Functions на E2EE‑чатах отключаются от декодирования/превью.
- Recovery: **QR‑pairing** (device‑to‑device) и **password‑based backup** (обёрнутый приватник на Firestore).
- Миграция: dual‑read (клиенты читают и v1, и v2), dual‑write под feature‑flag; ручной «перевключить E2EE в этом чате» триггерит v2‑сессию.

## 1. Scope / Non‑goals

### In scope

1. Текстовые сообщения, правки, реакции‑шифрования ключом чата.
2. Вложения: изображения, видео, видеокружки, голосовые, общие файлы.
3. Multi‑device для одного аккаунта (до N активных устройств, N ≤ 10 по умолчанию).
4. Management‑UI: список устройств, отзыв устройства, отпечаток (fingerprint) собеседника.
5. Recovery: QR pairing и password‑backup.
6. Миграция с v1.

### Non‑scope (пока)

- Signal Protocol / Double Ratchet (forward secrecy per‑message). v2 остаётся «per‑epoch key»: эпоха ротируется на событиях (add/remove member, revoke device, manual re‑key), в пределах эпохи используется один симметричный ключ чата.
- Server‑side search по зашифрованному тексту (клиентский поиск — см. §10).
- Полноценный federated keyserver / PKI. Доверие к user+device public key = доверие к Firebase Auth + защищённый клиент.
- Post‑quantum криптография.
- GIF и стикеры (живут на CDN без шифрования — см. §7.5).

## 2. Threat Model

### Доверенные стороны

- Владелец аккаунта на собственном устройстве (после прохождения Auth).
- WebCrypto / Keychain / Keystore на устройстве (secure storage).

### Недоверенные стороны

- Firebase (Firestore, Storage, Cloud Functions) — видит метаданные (участники, timestamps, размеры), но **не видит plaintext**.
- Атакующий с read‑only доступом к Firestore.
- Атакующий, получивший устройство собеседника после отзыва (revoke) — не должен читать сообщения, пришедшие после момента отзыва.

### Вне модели (acceptable risk)

- Атакующий с live‑root/jailbreak/admin доступом к чужому устройству до отзыва.
- Атакующий, знающий одновременно и пароль учётки, и password‑backup фразу.
- MiTM против начального «знакомства» ключей (mitigated via fingerprint UI — §9.3).

## 3. Криптографические примитивы

| Операция | Алгоритм | Параметры | WebCrypto name | Dart `cryptography` |
|---|---|---|---|---|
| Device identity | ECDH on P‑256 | SEC1/SPKI публичная, PKCS#8 приватная | `ECDH` / `P-256` | `Ecdh.p256(...)` |
| Symmetric chat key | AES‑256‑GCM | 256‑бит ключ, 12‑байт IV, 16‑байт tag | `AES-GCM` / 256 | `AesGcm.with256bits()` |
| Wrap chat‑key для получателя | ECDH → HKDF → AES‑GCM | wrap‑key derived из `ECDH(ephPriv, recipientDevicePub)` через HKDF‑SHA‑256 с `info = 'lighchat/v2/wrap'` | Сейчас v1 деривирует напрямую AES‑GCM через `deriveKey`; v2 переходит на `deriveBits → HKDF` | `Hkdf(Hmac.sha256(), ...)` |
| Message AEAD | AES‑256‑GCM | 12‑байт IV, 16‑байт tag, `aad = protocolVersion‖conversationId‖messageId‖epoch` | `AES-GCM` | `AesGcm.with256bits()` |
| Media file AEAD | AES‑256‑GCM streaming | 4 МиБ chunks, per‑chunk IV = `nonce_prefix‖chunkIndex_BE32`, `aad = fileId‖chunkIndex‖chunkKind` | `AES-GCM` по чанкам | `AesGcm.with256bits(nonceLength: 12)` |
| Media key wrap | AES‑KW поверх chat‑key эпохи (`rfc3394`) | 32‑байт ключ → 40‑байт обёртка | Нет в WebCrypto, используем AES‑GCM‑wrap (см. §7.4) | Аналогично |
| Password backup KDF | Argon2id | memory=64 MiB, iterations=3, parallelism=1, salt=16 B, output=32 B | — | `Argon2id` (через `argon2_ffi`) |
| Password backup AEAD | AES‑256‑GCM | ключ из Argon2id, AAD включает `backupVersion` и `createdAt` | `AES-GCM` | `AesGcm.with256bits()` |

`v1-p256-aesgcm` остаётся совместимым: AAD в v1 не использовался и не используется (для совместимости ciphertext'ов). В v2 все новые ciphertext'ы содержат AAD; читатель v2 распознаёт версию по `protocolVersion` в Firestore.

## 4. Ключевая иерархия

```
DeviceIdentity (per user, per device)
├── ECDH P-256 keypair (непереносимый между устройствами, кроме QR-pairing)
│     ├── Публичный — опубликован в Firestore users/{uid}/e2eeDevices/{deviceId}
│     └── Приватный — хранится в SecureStorage (IndexedDB / Keychain / Keystore)
│
└── PasswordBackup (опционально, создаётся пользователем)
      └── AES-GCM-encrypted PKCS#8 приватника, лежит в
          users/{uid}/e2eeBackups/{backupId}

ConversationEpoch (per conversation, per epoch)
└── ChatKey_epoch (32 байта, AES-256-GCM)
      ├── Wraps: { userId: { deviceId: { ephPub, iv, ct } } } → живут в
      │   conversations/{cid}/e2eeSessions/{epoch}
      ├── Используется для шифрования текста/HTML сообщений в этой эпохе
      └── Используется для обёртывания MediaFileKey через HKDF-context

MediaFileKey (per-attachment)
└── 32 байта, AES-256-GCM
      ├── Генерируется клиентом при загрузке
      ├── Обёртывается ChatKey_epoch → хранится в message.e2ee.attachments[i].wrap
      └── Нигде больше не сохраняется
```

Отличия от v1:

- v1: `users/{uid}/e2ee/device` — один слот на пользователя; v2: `users/{uid}/e2eeDevices/{deviceId}` — коллекция, ничего не удаляется автоматически.
- v1: `wraps[userId]` — один wrap на пользователя; v2: `wraps[userId][deviceId]` — вложенная мапа.
- v1: нет media, нет backup, нет pairing.

## 5. Firestore schema (v2)

### 5.1. `users/{uid}/e2eeDevices/{deviceId}`

```ts
interface E2eeDeviceDocV2 {
  deviceId: string;               // stable ULID, генерируется клиентом
  publicKeySpki: string;          // base64 SPKI P-256
  platform: 'web' | 'ios' | 'android';
  label: string;                  // человекочитаемое ("MacBook Pro — Chrome")
  createdAt: string;              // ISO
  lastSeenAt: string;             // обновляется при каждом входе
  revoked?: boolean;              // если true — не используется при wrap
  revokedAt?: string;
  revokedByDeviceId?: string;
  keyBundleVersion: 1;            // для будущих ключевых форматов
}
```

Правила доступа (см. §13):

- Читать: любой аутентифицированный пользователь (нужно, чтобы слать wrap каждому).
- Писать: только владелец `uid`.

### 5.2. `users/{uid}/e2eeBackups/{backupId}` (опционально)

```ts
interface E2eeBackupDocV2 {
  backupId: string;               // обычно 'primary'
  backupVersion: 1;
  createdAt: string;
  kdf: {
    algorithm: 'argon2id';
    memKiB: number;               // 65536
    iterations: number;           // 3
    parallelism: number;          // 1
    saltB64: string;              // 16 байт
  };
  aead: {
    algorithm: 'AES-GCM';
    ivB64: string;                // 12 байт
    ciphertextB64: string;        // enc(pkcs8 приватника)
  };
  /** Список устройств, из которых можно восстанавливаться этим backup (для UI). */
  allowedDeviceLabels?: string[];
}
```

Доступ: читает и пишет только владелец `uid`.

### 5.3. `users/{uid}/e2eePairingSessions/{sessionId}` (TTL)

```ts
interface E2eePairingSessionDocV2 {
  sessionId: string;              // ULID
  createdAt: string;
  expiresAt: string;              // createdAt + 5 min
  state: 'awaiting_scan' | 'awaiting_accept' | 'completed' | 'expired' | 'rejected';
  /** Одноразовый публичник эфемерной ECDH от инициатора (нового устройства). */
  initiatorEphPubSpkiB64: string;
  /** После скана донор публикует ephPub + зашифрованный приватник + метаданные нового устройства. */
  donorPayload?: {
    donorEphPubSpkiB64: string;
    ivB64: string;
    ciphertextB64: string;        // AEAD(pkcs8 приватника + контекст)
    deviceDraft: { deviceId: string; platform: string; label: string; publicKeySpki: string };
  };
}
```

Scheduled CF вычищает `expired`/`completed` старше 10 минут. Ни одна сторона, кроме владельца `uid`, не может прочесть сессию.

### 5.4. `conversations/{cid}/e2eeSessions/{epoch}` (v2 формат)

```ts
interface E2eeSessionDocV2 {
  protocolVersion: 'v2-p256-aesgcm-multi';
  epoch: number;
  createdAt: string;
  createdByUserId: string;
  createdByDeviceId: string;      // важно для аудита и фин‑состояния
  /** Участники на момент создания эпохи — совпадает с conv.participantIds. */
  participantIds: string[];
  /** Для каждого участника — список (deviceId → wrap) активных устройств. */
  wraps: Record<string, Record<string, { ephPub: string; iv: string; ct: string }>>;
  /** HKDF info‑string для derivation media‑wrap ключа: гарантирует доменное разделение. */
  wrapContext: string;            // 'lighchat/v2/session'
}
```

### 5.5. `conversations/{cid}/messages/{mid}.e2ee` (v2)

```ts
interface ChatMessageE2eePayloadV2 {
  protocolVersion: 'v2-p256-aesgcm-multi';
  epoch: number;
  ivB64: string;
  ciphertextB64: string;
  /** AAD, в который включены conversationId, messageId, epoch — хранится не в ДБ, вычисляется клиентом. */
  aadContext: 'msg/v2';
  senderDeviceId: string;         // ← новое: отправитель идентифицирует устройство‑источник
  /** Для вложений — массив «media envelopes» в порядке attachments[]. */
  attachments?: Array<MediaEnvelopeV2 | null>;
}

interface MediaEnvelopeV2 {
  fileId: string;                 // ULID, он же storage path leaf
  kind: 'image' | 'video' | 'voice' | 'videoCircle' | 'file';
  mime: string;
  size: number;
  wrap: { ephPub: string; iv: string; ct: string }; // обёртка per-file AES-GCM ключа
  chunking: { chunkSizeBytes: 4194304; chunkCount: number };
  iv: { prefixB64: string };      // 8 байт; полный IV = prefix||chunkIndex_BE32
  /** Для изображений/видео — thumbnail тоже шифруется. */
  thumb?: { path: string; ivB64: string; ciphertextB64: string; mime: string };
  /** Для видео/кружков/аудио — длительность/размеры уже не в открытом виде. */
  metadataEnc?: { ivB64: string; ciphertextB64: string };
}
```

Видно, что ни `text`, ни `attachments[].downloadURL`, ни длительность/размеры медиа **не хранятся в открытом виде** на сервере для E2EE‑чатов.

## 6. Wire algorithms

### 6.1. Wrap chat‑key для устройства (v2)

Вход: `chatKeyRaw` (32 B), `recipientDevicePubSpki` (байты).
Шаги:

1. `(ephPriv, ephPub) = ECDH_generate(P‑256)`.
2. `Z = ECDH_deriveBits(ephPriv, recipientDevicePub)` — 32 байта.
3. `wrapKey = HKDF‑SHA‑256(Z, salt = epochId || deviceId, info = 'lighchat/v2/wrap', len = 32)`.
   (v1 использовал `deriveKey`; v2 явно выводит через HKDF — это делает деривацию воспроизводимой и убирает неявную зависимость от WebCrypto‑специфики.)
4. `iv = random(12)`.
5. `ct = AES‑GCM‑Enc(wrapKey, iv, chatKeyRaw, aad = 'lighchat/v2/wrap‖epoch‖deviceId')`.
6. Выход: `{ ephPub: SPKI(ephPub), iv, ct }`.

### 6.2. Encrypt message (v2)

Вход: `plaintextHtml`, `conversationId`, `messageId`, `epoch`, `chatKey`.
Шаги:

1. `iv = random(12)`.
2. `aad = 'msg/v2'‖conversationId‖messageId‖epoch` (UTF‑8, concatenated с 0x1F разделителем).
3. `ct = AES‑GCM‑Enc(chatKey, iv, UTF8(plaintextHtml), aad)`.
4. Сохранить в Firestore `message.e2ee = { protocolVersion: 'v2-...', epoch, ivB64: b64(iv), ciphertextB64: b64(ct), aadContext: 'msg/v2', senderDeviceId }`.

### 6.3. Decrypt message (v2)

Клиент:

1. По `message.e2ee.epoch` загружает session‑doc, находит `wraps[myUid][myDeviceId]`.
2. Unwrap chat‑key (см. §6.1 обратно).
3. Собирает `aad` детерминированно из `conversationId`, `messageId`, `epoch`.
4. `plaintext = AES‑GCM‑Dec(chatKey, iv, ct, aad)`.
5. Рендерит как HTML после sanitizer (тот же pipeline, что и для незашифрованного).

### 6.4. Encrypt media (v2)

Для каждого файла клиент:

1. Генерирует `fileKey = random(32)`.
2. Выбирает `nonce_prefix = random(8)`. Полный IV для chunk `i`: `nonce_prefix || i_BE32` (итого 12 байт).
3. Разбивает поток на chunks по 4 МиБ. Для каждого chunk:
   `ctChunk = AES‑GCM‑Enc(fileKey, iv_i, chunk, aad = fileId‖i‖kind)`.
4. Загружает ct‑chunks в Storage по пути `chat-attachments-enc/{cid}/{messageId}/{fileId}/chunk_{i}` (см. §7).
5. Отдельно шифрует thumbnail: `thumbCt = AES‑GCM‑Enc(fileKey, ivThumb, thumbBytes, aad = fileId‖thumb)`. Хранит `thumbCt` inline в `MediaEnvelopeV2.thumb.ciphertextB64` (thumb ≤ 64 КБ).
6. Обёртывает `fileKey` под эпоху:
   `wrapKey = HKDF‑SHA‑256(chatKey, salt = fileId, info = 'lighchat/v2/media‑wrap', len = 32)`;
   `wrap.iv = random(12)`;
   `wrap.ct = AES‑GCM‑Enc(wrapKey, wrap.iv, fileKey)`.
   (То есть media‑wrap — это не ECDH, а симметричная обёртка поверх chat‑key эпохи; получателям она доступна только если они смогли unwrap chat‑key.)
7. Шифрует небольшие метаданные (длительность, размеры, waveform) в `metadataEnc` тем же fileKey.
8. Формирует `MediaEnvelopeV2` и кладёт в `message.e2ee.attachments[i]`.

### 6.5. Decrypt media (v2)

1. Берём `MediaEnvelopeV2`, unwrap `fileKey` через chat‑key.
2. Для thumbnail — сразу расшифровываем inline.
3. Для полного файла — streaming decrypt: читаем chunks из Storage, decrypt по одному chunk'у. Для video/audio используем `MediaSource` / `ExoPlayer` с custom data source, не пишем plaintext на диск (см. §7.4).

### 6.6. Enable E2EE / add member / remove member / revoke device

Все триггерят **новую эпоху** с новым chat‑key и свежими wraps для активных устройств каждого участника.

Псевдо:

```
nextEpoch = conv.e2eeKeyEpoch + 1
chatKey = random(32)
wraps = {}
for uid in participantIds:
  devices = listActiveDevices(uid)
  if devices.isEmpty():
    abort: E2EE_NO_DEVICE(uid)
  wraps[uid] = {}
  for dev in devices:
    wraps[uid][dev.id] = wrap(chatKey, dev.publicKeySpki)
createSessionDoc(cid, nextEpoch, wraps, ...)
updateConversation({ e2eeEnabled: true, e2eeKeyEpoch: nextEpoch })
```

Порядок (session → conv update) такой же, как в Phase 0 group‑removal fix.

### 6.7. QR pairing (новое устройство <- донор)

```
New device (initiator):
  - Генерит ephPriv_I / ephPub_I
  - Опубликовал pairingSession: { state: awaiting_scan, initiatorEphPubSpki }
  - Показал QR: { uid, sessionId, initiatorEphPubFP (первые 8 байт SHA-256 для визуальной проверки) }

Donor device (owner logged in):
  - Сканирует QR, вытаскивает sessionId и publicKey отпечаток
  - Загружает pairingSession, проверяет initiatorEphPubFP
  - Генерит ephPriv_D / ephPub_D
  - Z = ECDH(ephPriv_D, initiatorEphPub)
  - k = HKDF(Z, salt=sessionId, info='lighchat/v2/pair', len=32)
  - Шифрует pkcs8 своего приватника + deviceDraft для нового устройства
  - Пишет donorPayload в pairingSession, state = awaiting_accept

New device:
  - Слушает pairingSession, видит donorPayload
  - Z = ECDH(ephPriv_I, donorEphPub)
  - k = HKDF(...)  [то же, что у донора]
  - Расшифровывает pkcs8 приватника
  - Сохраняет приватник в SecureStorage под deviceId (новый, для этого устройства)
  - Публикует users/{uid}/e2eeDevices/{newDeviceId}  (свой SPKI)
  - state = completed
  - Scheduler через 10 мин снесёт pairingSession
```

Безопасность:

- PairingSession доступен только `uid` (Firestore rules).
- `initiatorEphPubFP` на QR гарантирует, что донор шифрует именно под тот же публичник, что увидит новое устройство → MiTM внутри своего же аккаунта исключён.
- Ephemeral keys после session уничтожаются (в памяти JS — GC, в Dart — scrub byte‑buffers).

**Важно:** сам ECDH‑приватник у исходного устройства **переносится** на новое (это и есть «pairing»). Это даёт новому устройству возможность читать старые сообщения (до pairing), что желательно UX‑wise. Альтернатива — device‑isolated identity, но тогда старые сообщения останутся нечитаемыми на новом устройстве. Мы сознательно выбираем перенос.

### 6.8. Password‑backup

Создание:

1. Пользователь задаёт пароль `P`. `salt = random(16)`.
2. `k = Argon2id(P, salt, mem=64MiB, iter=3, par=1, 32 B)`.
3. `iv = random(12)`; `aad = backupId‖'backup/v1'‖createdAt`.
4. `ct = AES‑GCM‑Enc(k, iv, pkcs8(приватник), aad)`.
5. Пишем `E2eeBackupDocV2` в Firestore.

Восстановление:

1. Пользователь вводит `P`. Клиент загружает backup‑doc, берёт `salt`.
2. `k = Argon2id(P, salt, ...)`.
3. Decrypt pkcs8 приватника.
4. Импортирует в WebCrypto / Dart, сохраняет в SecureStorage.
5. Регистрирует новое устройство (новый `deviceId`, свой SPKI) в `e2eeDevices`.

Пароль **никогда** не пересылается на сервер. Firebase видит только salt+ciphertext.

## 7. Хранилище медиа

### 7.1. Storage layout

- Незашифрованные: `chat-attachments/{cid}/{messageId}/{fileName}` (как сейчас).
- E2EE: `chat-attachments-enc/{cid}/{messageId}/{fileId}/chunk_{i}` + `chat-attachments-enc/{cid}/{messageId}/{fileId}/meta.json` (если нужно).

### 7.2. Rules

- Writer: любой участник чата с `isE2eeParticipant`. Проверка, что нельзя загружать в чужие `cid`.
- Reader: участник чата.
- Transcode CFs (`chat-media-transcode`, `retryChatMediaTranscode`) **пропускают** пути `chat-attachments-enc/**` → метрикой `e2ee_media_skipped`.

### 7.3. Лимиты

- chunkSize = 4 МиБ.
- Максимум файла — текущий лимит для чата (обсудить; текущий ≈ 100 МиБ). Для E2EE лимит совпадает (клиент‑сайд).
- thumbnail inline ≤ 64 КБ.

### 7.4. Streaming decryption на клиенте

- Web: `ReadableStream` + `AES‑GCM‑Dec` per chunk. Для видео — `MediaSource` API, подавая decrypted chunks.
- Mobile: `AesGcm` по чанкам, pipe в `FileStream` temp; для `VideoPlayer` используем custom `DataSource` с AES‑GCM‑decrypt в памяти, без записи plaintext на диск (если платформа не даёт — пишем в приватный каталог и удаляем после закрытия).

### 7.5. Исключения

- **Стикеры и GIF** не шифруются. Причины:
  - Стикеры лежат на CDN как единый ресурс шаринга между пользователями, их приватность ≈ 0.
  - GIF — это hotlink URL; шифровать не имеет смысла.
  - Сохраняем текущую статическую CDN‑логику и размер payload.
- Отправляются как обычные `ChatAttachment` с типом `sticker` / `gif`, вне `MediaEnvelopeV2`.

## 8. Миграция с v1

### 8.1. Dual‑read

- Клиент v2 умеет читать и v1 (`v1-p256-aesgcm`), и v2 сообщения по полю `message.e2ee.protocolVersion`.
- v1‑сессии читаются через старый `unwrapConversationChatKey` (single‑wrap per user). v2‑сессии читаются новым кодом.

### 8.2. Dual‑write под feature‑flag

- Добавляем `platformSettings.main.e2eeProtocolVersion: 'v1' | 'v2' | 'auto'`.
  - `v1` — по‑старому. Новых wraps v2 не делаем.
  - `v2` — все новые enable / add‑member / remove‑member / revoke создают v2‑сессии.
  - `auto` — если в чате уже есть v2‑сессия — пишем v2, иначе v1.
- В UI «Безопасность чата» добавляем пункт «Перейти на E2EE v2» (только для групп с включённым E2EE v1). Кнопка триггерит новую эпоху в формате v2, старые сообщения остаются читаемыми через v1.

### 8.3. Users с одним устройством (v1)

Когда такой пользователь впервые заходит в v2‑клиенте: регистрируется как `e2eeDevices/{deviceId}` с тем же публичником, что был в `users/{uid}/e2ee/device`. Новые v2‑session создают wrap только под это устройство → совместимо.

### 8.4. Deprecation plan

- 3 месяца параллельной работы v1 + v2.
- После: Web/Mobile начинают писать **только** v2 (auto → v2 forced). v1 остаётся только на чтение.
- Через 6 мес — убираем write‑путь v1 полностью, оставляем read.
- Через 12 мес — ревизия и, при необходимости, migration task для остатков.

## 9. Безопасность и UX

### 9.1. Epoch rotation triggers

- Include member: +1 epoch, новые wraps для всех.
- Remove member: +1 epoch, без исключённого.
- Revoke device: +1 epoch, без revoked device'а в wraps этого `uid`. Само устройство остаётся в `e2eeDevices` с `revoked: true`.
- Manual «re‑key chat» в UI: +1 epoch.
- Re‑enable E2EE (disabled → enabled): +1 epoch как и сейчас.

### 9.2. Ограничение устройств на пользователя

- Soft cap = 10, hard cap = 20. При превышении UI предлагает отозвать старые.

### 9.3. Fingerprint UI

Для каждого собеседника в DM — отпечаток = SHA‑256(отсортированный JSON всех публичников активных устройств собеседника), показываем в Settings как 64‑символьный hex с разбивкой по 4. Собеседники могут сверить отпечатки лично или по альтернативному каналу (QR / голос). Изменение отпечатка (добавление/отзыв устройства) показывается в timeline как system‑message.

### 9.4. Timeline markers

Вводим system‑message types (не шифруются):

- `e2ee.v2.enabled` — «E2EE включено»
- `e2ee.v2.epoch.rotated` — «ключ обновлён»
- `e2ee.v2.device.added` — «{имя} добавил устройство {label}»
- `e2ee.v2.device.revoked` — «{имя} отозвал устройство {label}»
- `e2ee.v2.fingerprint.changed` — «отпечаток безопасности у {имя} изменился»

### 9.5. Forwards

- Forward → читается отправителем (нужен plaintext), затем перекодируется под ключ нового чата. Mobile поддерживает forward только если отправитель смог расшифровать сам.

### 9.6. Push notifications

- Для E2EE‑сообщений push остаётся с placeholder‑текстом. Если у мобайла появятся ключи (Phase 4), можно на клиенте после получения push сделать «show real content» через notification extension (iOS) / Firebase Notification Extension (Android). Пока — не планируем.

## 10. Поиск

- Серверный поиск (Firestore `where text`) по E2EE‑сообщениям невозможен — ciphertext.
- Клиентский поиск: индексируем plaintext локально после decrypt (в памяти / в защищённом кэше). Не выкладываем в Firestore.
- UI в search‑сцене: предупреждаем пользователя, что поиск по E2EE‑чатам работает только по загруженной истории.

## 11. Errors / error codes (v2)

| Код | Когда | Поведение клиента |
|---|---|---|
| `E2EE_NO_DEVICE(uid)` | У участника нет активных устройств | Блокируем включение E2EE / ротацию, показываем TOAST |
| `E2EE_NO_WRAP_FOR_DEVICE` | session‑doc не содержит wrap под моё устройство | Показываем «войдите заново с другого устройства / восстановите backup» |
| `E2EE_EPOCH_MISMATCH` | message.e2ee.epoch ≠ conv.e2eeKeyEpoch | Логгируем, пытаемся загрузить нужную эпоху; если не получается — показываем placeholder |
| `E2EE_AAD_MISMATCH` | Decrypt упал (tag невалиден) | Вероятно подмена; плейсхолдер «сообщение повреждено» |
| `E2EE_MEDIA_DECRYPT_FAILED` | chunk decrypt упал | Показываем «файл повреждён» и кнопку «повторить загрузку» |
| `E2EE_PAIRING_EXPIRED` | session истёк | UI предлагает начать pairing заново |
| `E2EE_BACKUP_WRONG_PASSWORD` | Argon2id+GCM decrypt упал | UI: неверный пароль |

## 12. Тест‑план (кратко)

Детальный план — в Phase'ах 2–9 основного roadmap. Здесь фиксируем инварианты, которые должны проверяться test‑suite'ами:

1. Web v2 шифрует → Web v2 дешифрует (единственное устройство).
2. Web v2 шифрует → Web v2 с **двумя устройствами одного юзера** дешифрует на обоих.
3. Web v2 ↔ Mobile v2 (Phase 4) в DM.
4. v1 → v2 миграция: старые сообщения остаются читаемыми, новые — v2.
5. Revoke device: отозванное устройство не расшифровывает сообщения, созданные после revoke.
6. Pairing: новое устройство получает приватник и видит весь старый history.
7. Password backup: восстановление на «чистом» устройстве даёт доступ к history.
8. Media: encrypt → upload → download → decrypt идентично оригиналу (byte‑level).
9. Test vectors (§Приложение) проходят на обеих платформах.

## 13. Firestore / Storage rules diff

Добавляются разрешения (см. `firestore.rules`, `storage.rules`, phase 2/7):

- `users/{uid}/e2eeDevices/{deviceId}` — read: auth, write: owner.
- `users/{uid}/e2eeBackups/{backupId}` — read/write: owner.
- `users/{uid}/e2eePairingSessions/{sid}` — read/write: owner; TTL через scheduled CF.
- `conversations/{cid}/e2eeSessions/{epoch}` — write: любой текущий participant; read: участник. (Как и сейчас для v1.)
- Storage `chat-attachments-enc/{cid}/**` — read: участник; write: отправитель.

## Приложение A. Test vectors

Сторона‑агностические входы/выходы (KAT). Хранятся в [`e2ee-v2-test-vectors.json`](./e2ee-v2-test-vectors.json). Категории:

- `message.encrypt.v1` — регрессия, что v2‑ридер всё ещё понимает v1.
- `message.encrypt.v2` — encrypt/decrypt с фиксированными `chatKey`/`iv`/`aad`.
- `wrap.v2` — wrap/unwrap с фиксированными `ephPriv`/`recipientPub`.
- `hkdf.wrap.v2` — деривация wrap‑ключа.
- `media.chunk.v2` — AEAD по одному chunk'у.
- `argon2id.backup.v1` — одна пара `(password, salt) → key`.

Обе реализации (TS и Dart) **обязаны** пройти эти векторы перед merge фазы.

## Приложение B. Отличия от v1 (сводно)

| Аспект | v1 | v2 |
|---|---|---|
| identity key | per‑user | per‑device |
| session wrap | per‑user | per‑user → per‑device |
| wrap KDF | WebCrypto `deriveKey` неявно | HKDF‑SHA‑256 явно |
| AEAD AAD | отсутствует | `conversationId‖messageId‖epoch` |
| media | не шифруется | шифруется chunk'ами 4 МиБ |
| recovery | отсутствует | QR pairing + password backup |
| mobile send | — (нет) | есть (Phase 4) |
| mobile read | — (placeholder) | есть (Phase 4) |
| protocolVersion | `v1-p256-aesgcm` | `v2-p256-aesgcm-multi` |

## Приложение C. Open questions (на финализацию в review)

1. Хранить ли `keyBundleVersion: 1` в device‑doc, или достаточно `protocolVersion` у session? — **предлагаю хранить**, чтобы в будущем сменить формат device identity без ломания session‑логики.
2. Использовать ли Signature (Ed25519) поверх device identity для anti‑spoof на paging? — **пока нет**, QR‑fingerprint достаточно.
3. Хранить ли thumbnail отдельным файлом в Storage при size > 64 КБ? — **да**, если thumbnail ≥ 64 КБ (редкий кейс), пишем отдельный encrypted chunk и помещаем путь в `MediaEnvelopeV2.thumb.path`.

---

*Документ является proposal‑версией. После approval → phase 2 (web v2 core).*
