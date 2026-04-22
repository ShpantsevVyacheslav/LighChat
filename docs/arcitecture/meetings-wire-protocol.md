# Meetings wire-protocol (web ↔ mobile)

Этот документ фиксирует контракт многопользовательских митингов LighChat, по которому
совместимы веб-клиент (Next.js + `simple-peer`) и мобильный клиент (Flutter + `flutter_webrtc`).
Любые изменения здесь — breaking-change; при смене протокола обновляйте обе платформы в
одном PR и выставляйте `protocolVersion` в документе митинга (см. §8).

Источники правды в коде:
- web: `src/hooks/use-meeting-webrtc.ts`, `src/components/meetings/*`, `src/app/meetings/[meetingId]/page.tsx`.
- web серверная часть: `functions/src/triggers/http/meetingJoinRequests.ts`,
  `functions/src/triggers/scheduler/checkUserPresence.ts`.
- правила доступа: `firestore.rules` → блок `match /meetings/{meetingId}`.
- mobile (реализуется): `mobile/app/lib/features/meetings/*`.

---

## 1. Firestore-модель

### `meetings/{meetingId}` — документ митинга

Поля (совместимо с `src/lib/types.ts`):

| поле         | тип             | обязательно | описание                                                |
|--------------|-----------------|-------------|---------------------------------------------------------|
| `id`         | string          | да          | совпадает с `meetingId` в пути                          |
| `name`       | string          | да          | название встречи                                        |
| `hostId`     | string          | да          | `auth.uid` создателя; единственный может удалить        |
| `adminIds`   | string[]        | нет         | модераторы (mute/kick, перевод в админы)                |
| `isPrivate`  | boolean         | да          | `true` — waiting-room через `requests`                  |
| `status`     | 'active'/'ended'| да          | клиент сейчас пишет только `'active'`                   |
| `createdAt`  | ISO string      | да          | time of creation                                        |
| `expiresAt`  | ISO string?     | нет         | запланированное окончание                               |
| `isRecording`| boolean         | нет         | host ставит при старте `MediaRecorder`                  |

Права: чтение — любой авторизованный (в т.ч. анонимный гость, открывающий deep-link);
create/update — host/admin (см. `firestore.rules`).

### `meetings/{meetingId}/participants/{uid}` — живое присутствие

Используется и как «член комнаты» в правилах (`isMeetingMember`), и как состояние для UI
(mute/video/hand-raise/reactions). Пишется клиентом при входе, мержится на `toggleMic`/
`toggleVideo`/и т.п. Удаляется при выходе (клиент сам `deleteDoc`) или планировщиком
при stale `lastSeen`.

| поле               | тип              | обязательно | описание                                                      |
|--------------------|------------------|-------------|---------------------------------------------------------------|
| `id`               | string           | да          | равен `uid`                                                   |
| `name`             | string           | да          | имя для отображения (у гостя — то, что он ввёл)               |
| `avatar`           | string           | нет         | URL full-size аватара                                         |
| `avatarThumb`      | string           | нет         | URL превью (используется в тайлах/списке)                     |
| `role`             | string           | нет         | "worker" для обычного, иначе — роль из `users`                |
| `joinedAt`         | serverTimestamp  | да          | момент создания записи                                        |
| `lastSeen`         | ISO string       | да          | heartbeat клиента, обновляется раз в 20 сек и на любом action |
| `isAudioMuted`     | boolean          | да          | локально выключен микрофон                                    |
| `isVideoMuted`     | boolean          | да          | локально выключена камера                                     |
| `isHandRaised`     | boolean          | нет         | поднятая рука                                                 |
| `isScreenSharing`  | boolean          | нет         | демонстрирует экран                                           |
| `reaction`         | string \| null   | нет         | emoji (очищается клиентом через 3с — `null`)                  |
| `backgroundConfig` | `{type,url?}`    | нет         | локальный фон (не расшаривается трансляционно, см. §7)        |
| `facingMode`       | 'user'/'environment' | нет     | только информативно для UI                                    |
| `forceMuteAudio`   | boolean          | нет         | **host-writes** → клиент должен замьютить и сбросить флаг     |
| `forceMuteVideo`   | boolean          | нет         | аналогично                                                    |

Правила: write своего документа — self; update/delete любого — host/admin (для kick и
force-mute). Read — только участникам.

### `meetings/{meetingId}/signals/{autoId}` — сигналинг WebRTC

Каждый документ — одно сообщение сигналинга, адресованное конкретному участнику. Получатель
**удаляет** документ после применения (чтобы коллекция не росла).

| поле        | тип              | описание                                             |
|-------------|------------------|------------------------------------------------------|
| `from`      | string           | `auth.uid` отправителя                               |
| `to`        | string           | `auth.uid` адресата                                  |
| `type`      | 'offer'/'answer'/'candidate' | тип сигнала                              |
| `data`      | any (JSON)       | payload (см. §3)                                     |
| `createdAt` | serverTimestamp  | время создания                                       |

Правила: read/delete — member (и `from==auth.uid` или `to==auth.uid`); create — member и
`from==auth.uid`.

### `meetings/{meetingId}/requests/{uid}` — waiting room приватной встречи

| поле        | тип                             | описание                                  |
|-------------|---------------------------------|-------------------------------------------|
| `userId`    | string                          | `auth.uid`                                |
| `name`      | string                          | как представился гость                    |
| `avatar`    | string                          | URL (или DiceBear-сгенерированный)        |
| `status`    | 'pending'/'approved'/'denied'   | host изменяет через callable              |
| `requestId` | string?                         | клиентский id для отсечения старых заявок |
| `createdAt` | serverTimestamp                 | момент создания                           |
| `lastSeen`  | ISO string                      | heartbeat клиента (раз в 20 сек)          |

Правила: create/update/delete — self или host/admin; read — self или host/admin.

Заявку создаёт **callable `requestMeetingAccess`** (Admin SDK), см. §6.

### `meetings/{meetingId}/messages/{autoId}` — чат митинга

| поле           | тип                   | описание                                   |
|----------------|-----------------------|--------------------------------------------|
| `senderId`     | string                | `auth.uid` (обязательно)                   |
| `senderName`   | string                | для офлайн-отображения без участника       |
| `text`         | string?               | текст сообщения                            |
| `attachments`  | ChatAttachment[]      | вложения (как в обычном чате)              |
| `createdAt`    | serverTimestamp       |                                            |

Правила: read/create — member; update/delete — автор или host/admin.

### `meetings/{meetingId}/polls/{pollId}` — голосования внутри митинга

См. `src/components/meetings/MeetingPolls.tsx`. Схема отличается от чат-опросов;
сервер не проверяет целостность — доверяем клиенту под read/write для members.

---

## 2. Индексы пользователя

- `userMeetings/{uid}` (`{ meetingIds: string[] }`) — индекс собственных/активных митингов,
  заполняется триггером `onMeetingParticipantCreated`.

---

## 3. WebRTC-сигналинг: формат `signals.data`

Все три клиента (web, mobile) генерируют эти типы из своих WebRTC-стэков. Веб использует
`simple-peer`, мобильный — `flutter_webrtc` напрямую; формат на проводе **один и тот же**.

### 3.1 `type: 'offer'`
```json
{ "type": "offer", "sdp": "v=0\r\n..." }
```

### 3.2 `type: 'answer'`
```json
{ "type": "answer", "sdp": "v=0\r\n..." }
```

### 3.3 `type: 'candidate'` (trickle ICE)
```json
{
  "candidate": "candidate:842163049 ...",
  "sdpMid": "0",
  "sdpMLineIndex": 0,
  "usernameFragment": "optional"
}
```

`simple-peer` шлёт offer/answer внутри `data` с полем `type`, а ICE-кандидаты как объект
без `type` — в таком случае веб кладёт `type: 'candidate'` в Firestore (см. строку в
`setupPeer` → `type: data.type || 'candidate'`). Мобильный клиент должен:
- для исходящих offer/answer сериализовать `RTCSessionDescription.toMap()` в
  `{ type, sdp }`;
- для ICE-кандидатов — `RTCIceCandidate.toMap()` (или ручной JSON с теми же ключами).
- при получении — в зависимости от `type` создавать `RTCSessionDescription` или
  `RTCIceCandidate` и применять.

### 3.4 Правило инициатора

Инициатором в паре является **лексикографически меньший `uid`**:
```
if (selfUid < remoteUid) -> мы создаём offer, шлём через signals;
else -> ждём offer от другой стороны.
```
Это правило **стабильно** между клиентами разных платформ — важно, чтобы не возникало
двух встречных offer.

---

## 4. Жизненный цикл соединения

1. Пользователь отображает `JoinMeeting` (читает `meetings/{id}`).
2. При клике Join, если митинг приватный и пользователь не host/admin — callable
   `requestMeetingAccess` создаёт `requests/{uid}` со `status='pending'`; клиент подписан на
   свой документ и ждёт `approved`.
3. После `approved` (или сразу для публичного митинга) клиент:
   - создаёт `participants/{uid}` с первичными полями (`lastSeen`, mic/video флаги);
   - подписывается на коллекцию `participants` и на `signals where to==self`;
   - для каждого добавленного участника: если `self.uid < remote.uid` — создаёт peer в
     `initiator: true` и шлёт offer; иначе — ждёт offer.
4. Trickle ICE: каждая сторона шлёт кандидаты по мере появления.
5. Heartbeat: клиент раз в 20 сек обновляет `participants/{self}.lastSeen`. Scheduler
   удаляет documenta с `lastSeen < now - 90s` (см. §5).
6. Выход: клиент `deleteDoc(participants/{self})` в cleanup `useEffect`. Соседи видят
   `removed` и закрывают соответствующий peer.
7. Kick: host/admin удаляет чужой `participants/{uid}`; изгоняемый клиент видит, что его
   собственный документ исчез — выходит из комнаты (`stopAllMedia` + redirect).
8. Force mute: host/admin ставит `forceMuteAudio=true` на чужом `participants/{uid}`;
   клиент замьютчивает микрофон и сбрасывает флаг.

### 4.1 Устойчивость (ICE restart)

Обе стороны следят за `iceConnectionState` своего peer. При `disconnected` запускается
дебаунс 4 сек; если не восстановилось — **инициатор** (меньший uid) вызывает `restartIce()`
и повторный `negotiate()`. При `failed` — полный destroy+recreate с бэкоффом 1 сек,
не более 3 попыток в окне 60 сек (web-реализация в `src/hooks/use-meeting-webrtc.ts`).

Мобильный клиент должен следовать той же логике.

---

## 5. Серверные триггеры

- `onMeetingParticipantCreated` (Firestore trigger) — при появлении `participants/{uid}`
  обновляет `userMeetings/{uid}`.
- `checkUserPresence` (scheduler, 1 минута):
  - marks stale `users.online=false` (порог 60 сек);
  - удаляет `meetings/*/participants/*` с `lastSeen < now - 90 сек`;
  - удаляет `meetings/*/requests/*` со статусом `pending` и `lastSeen < now - 90 сек`.

Выбор порога 90 сек: heartbeat раз в 20 сек, буфер ×4.5 — нужен для мобильных клиентов,
у которых OS может на 30-60 сек задерживать фоновую работу.

---

## 6. Callable-функции

- `requestMeetingAccess({ meetingId, name, avatar, requestId })` — создаёт/обновляет
  `requests/{auth.uid}` в `pending`. Вызывается **клиентом** (гостем или зарегистрированным)
  при попытке войти в приватный митинг.
- `respondToMeetingRequest({ meetingId, userId, approve })` — ставит `status='approved'`
  или `'denied'`. Вызывает только host (проверка внутри функции). На клиентской стороне
  host ничего не пишет в `requests` напрямую (хотя правила позволяют) — чтобы атомарность
  approvalа зависела от одного источника.

---

## 7. Виртуальный фон — локальный эффект, не передаётся на провод

`participants.backgroundConfig` несёт собственный фон **отправителя** — это чисто UI-подсказка
для самого́ отправителя (чтобы кнопка в `MeetingRoomHeader` на другом устройстве отобразила
актуальный выбор). Для удалённых участников фон уже применён к отправляемым кадрам (canvas
segmentation в вебе / native GPU-шейдер на mobile) — ничего дополнительно на их стороне
делать не нужно.

**Последствие для совместимости**: клиент без поддержки эффекта (например, mobile v1 без
установки ML-модели) просто не применяет локальный фон — отправляет обычную камеру. Это
корректно, встречные клиенты видят его «как есть».

---

## 8. Версионирование

Поле `meetings/{id}.protocolVersion` пока не вводится (legacy митинги имеют `undefined`).
Введение — при первом breaking-change сигналинга, вместе с фоллбеком на «совместимый»
путь.

---

## 9. Чек-лист совместимости при изменениях

Любой PR, который трогает:
- поля `participants.*`, `signals.*`, `requests.*`,
- правила инициатора (`self < remote`),
- частоту heartbeat / порог планировщика,
- формат `signals.data` для offer/answer/candidate,

— обязан:
1. Обновить web-клиент (`src/hooks/use-meeting-webrtc.ts` + `src/components/meetings/*`).
2. Обновить mobile-клиент (`mobile/app/lib/features/meetings/*`).
3. Обновить этот документ.
4. Обновить `firestore.rules` если меняется схема доступа.
5. Добавить entry в [docs/arcitecture/04-runtime-flows.md](04-runtime-flows.md).
