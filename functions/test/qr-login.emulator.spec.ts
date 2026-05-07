/**
 * Интеграционный тест QR-login против Firestore-эмулятора.
 *
 * Запускается через `npm run test:emulator` (см. functions/package.json) —
 * скрипт обёрнут в `firebase emulators:exec --only firestore`, что поднимает
 * эмулятор перед запуском vitest и останавливает после.
 *
 * Что покрываем:
 *  1. **Firestore rules** для коллекции `qrLoginSessions`: read публичный,
 *     create/update запрещены клиенту, delete доступен авторизованному.
 *  2. **runRequestQrLogin** — чистое ядро `requestQrLogin`. Проверяем форму
 *     записанного документа и валидацию входа.
 *  3. **runConfirmQrLogin** — чистое ядро `confirmQrLogin`:
 *      - Allow → state='approved' + customToken записан.
 *      - Deny → state='rejected'.
 *      - Bad nonce → permission-denied (без изменения документа).
 *      - Expired session → deadline-exceeded + документ удалён.
 *      - Replay (state != awaiting_scan) → failed-precondition.
 *  4. **End-to-end**: requestQrLogin → confirmQrLogin → новое устройство видит
 *     `customToken` через `getDoc` (rules read public) и удаляет сессию.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
} from 'firebase/firestore';
import * as admin from 'firebase-admin';

import {
  runRequestQrLogin,
  hashNonceForStorage,
  QR_LOGIN_TTL_SEC,
} from '../src/triggers/http/requestQrLogin';
import { runConfirmQrLogin } from '../src/triggers/http/confirmQrLogin';

const PROJECT_ID = 'lighchat-emulator-test';
const FIRESTORE_HOST = '127.0.0.1';
const FIRESTORE_PORT = Number(process.env.FIRESTORE_EMULATOR_PORT ?? 8080);

let testEnv: RulesTestEnvironment;
let adminApp: admin.app.App;
let adminDb: admin.firestore.Firestore;

beforeAll(async () => {
  // rules-unit-testing подключается к уже запущенному эмулятору. Сам эмулятор
  // поднимает `firebase emulators:exec --only firestore` (см. test:emulator).
  const rulesPath = path.resolve(__dirname, '..', '..', 'firestore.rules');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host: FIRESTORE_HOST,
      port: FIRESTORE_PORT,
    },
  });

  // Поднимаем admin SDK против того же эмулятора. emulator-host должен быть
  // выставлен ДО первого вызова admin.firestore(), что мы здесь и делаем.
  process.env.FIRESTORE_EMULATOR_HOST = `${FIRESTORE_HOST}:${FIRESTORE_PORT}`;
  adminApp = admin.initializeApp({ projectId: PROJECT_ID }, 'qr-login-emulator');
  adminDb = admin.firestore(adminApp);
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
  if (adminApp) await adminApp.delete();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('Firestore rules: qrLoginSessions', () => {
  // Готовим документ через withSecurityRulesDisabled — имитирует то, что
  // делает Cloud Function через Admin SDK (минуя rules).
  async function seedSession(sessionId: string, fields: Record<string, unknown> = {}) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'qrLoginSessions', sessionId), {
        sessionId,
        nonceHash: 'hash',
        state: 'awaiting_scan',
        expiresAt: new Date(Date.now() + 60_000).toISOString(),
        ...fields,
      });
    });
  }

  it('allows unauthenticated read of an existing session', async () => {
    await seedSession('public-read-test');
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'qrLoginSessions', 'public-read-test')));
  });

  it('allows authenticated read of an existing session', async () => {
    await seedSession('auth-read-test');
    const ctx = testEnv.authenticatedContext('user-A');
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'qrLoginSessions', 'auth-read-test')));
  });

  it('forbids unauthenticated client from creating a session', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(ctx.firestore(), 'qrLoginSessions', 'forge'), {
        sessionId: 'forge',
        nonceHash: 'whatever',
        state: 'awaiting_scan',
        expiresAt: new Date(Date.now() + 60_000).toISOString(),
      })
    );
  });

  it('forbids authenticated client from creating a session', async () => {
    const ctx = testEnv.authenticatedContext('user-A');
    await assertFails(
      setDoc(doc(ctx.firestore(), 'qrLoginSessions', 'forge2'), {
        sessionId: 'forge2',
        nonceHash: 'whatever',
        state: 'awaiting_scan',
        expiresAt: new Date(Date.now() + 60_000).toISOString(),
      })
    );
  });

  it('forbids client from updating a session (only Admin SDK can)', async () => {
    await seedSession('upd-test');
    const ctx = testEnv.authenticatedContext('user-A');
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'qrLoginSessions', 'upd-test'),
        { state: 'approved', customToken: 'forged' },
        { merge: true }
      )
    );
  });

  it('allows signed-in client to delete a session (cleanup after consume)', async () => {
    await seedSession('del-test');
    const ctx = testEnv.authenticatedContext('user-A');
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), 'qrLoginSessions', 'del-test')));
  });

  it('forbids unauthenticated client from deleting a session', async () => {
    await seedSession('del-anon');
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(deleteDoc(doc(ctx.firestore(), 'qrLoginSessions', 'del-anon')));
  });
});

describe('runRequestQrLogin', () => {
  const validInput = {
    ephemeralPubKeySpki: 'A'.repeat(120), // SPKI base64 typical length
    devicePlatform: 'web',
    deviceLabel: 'Chrome / web',
    deviceId: 'ULID0123456789ABCDEFGHIJK',
  };

  it('writes a valid session document to Firestore', async () => {
    // [audit H-003] ip/userAgent больше не передаются — они не сохраняются в
    // публично-читаемый qrLoginSessions/{sessionId}.
    const result = await runRequestQrLogin(adminDb, validInput, {});
    expect(result.sessionId).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(result.nonce).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(result.ttlSec).toBe(QR_LOGIN_TTL_SEC);

    const snap = await adminDb.doc(`qrLoginSessions/${result.sessionId}`).get();
    expect(snap.exists).toBe(true);
    const data = snap.data() ?? {};
    expect(data.state).toBe('awaiting_scan');
    expect(data.deviceId).toBe(validInput.deviceId);
    expect(data.devicePlatform).toBe('web');
    expect(data.deviceLabel).toBe('Chrome / web');
    expect(data.ephemeralPubKeySpki).toBe(validInput.ephemeralPubKeySpki);
    // Сервер хранит ХЭШ от nonce, а не сам nonce.
    expect(data.nonceHash).toBe(hashNonceForStorage(result.nonce, result.sessionId));
    expect(data.nonceHash).not.toContain(result.nonce);
    // [audit H-003] `ip`/`userAgent` намеренно НЕ хранятся в публично-читаемом
    // `qrLoginSessions/{sessionId}`. Утечка sessionId → утечка PII.
    expect(data.ip).toBeUndefined();
    expect(data.userAgent).toBeUndefined();
  });

  it('falls back to platform=web for unknown devicePlatform', async () => {
    const result = await runRequestQrLogin(adminDb, {
      ...validInput,
      devicePlatform: 'symbian',
    });
    const snap = await adminDb.doc(`qrLoginSessions/${result.sessionId}`).get();
    expect(snap.data()?.devicePlatform).toBe('web');
  });

  it('rejects empty deviceId with invalid-argument', async () => {
    await expect(
      runRequestQrLogin(adminDb, { ...validInput, deviceId: '' })
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects too-short ephemeralPubKeySpki', async () => {
    await expect(
      runRequestQrLogin(adminDb, { ...validInput, ephemeralPubKeySpki: 'short' })
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  // Регрессия: deviceId дальше попадает в Firestore document-path
  // `users/{uid}/e2eeDevices/{newDeviceId}`. Если разрешить там `/`, `.` или
  // control-символы, путь распадётся на лишние сегменты, и admin SDK бросит
  // непрозрачный Internal — на клиенте это и есть «An internal error occurred».
  it('rejects deviceId with slash (would corrupt Firestore path)', async () => {
    await expect(
      runRequestQrLogin(adminDb, { ...validInput, deviceId: 'abc/def' })
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects deviceId with dots (Firestore reserves leading dot)', async () => {
    await expect(
      runRequestQrLogin(adminDb, { ...validInput, deviceId: '../escape' })
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects deviceId with whitespace', async () => {
    await expect(
      runRequestQrLogin(adminDb, { ...validInput, deviceId: 'has space' })
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('accepts ULID-style deviceId (uppercase + digits)', async () => {
    const ulid = '01HQABCDEFGHJKMNPQRSTV0123';
    const res = await runRequestQrLogin(adminDb, {
      ...validInput,
      deviceId: ulid,
    });
    const snap = await adminDb.doc(`qrLoginSessions/${res.sessionId}`).get();
    expect(snap.data()?.deviceId).toBe(ulid);
  });

  it('accepts dashed/underscored ids (mobile + iOS variants)', async () => {
    const id = 'q-uid_with-dashes_and_underscores_12';
    const res = await runRequestQrLogin(adminDb, {
      ...validInput,
      deviceId: id,
    });
    const snap = await adminDb.doc(`qrLoginSessions/${res.sessionId}`).get();
    expect(snap.data()?.deviceId).toBe(id);
  });
});

describe('runConfirmQrLogin', () => {
  const seedInput = {
    ephemeralPubKeySpki: 'A'.repeat(120),
    devicePlatform: 'ios' as const,
    deviceLabel: 'iPhone / iOS',
    deviceId: 'NEW_DEVICE_ID_01234567',
  };

  async function seedActiveSession() {
    return runRequestQrLogin(adminDb, seedInput);
  }

  function fakeTokenIssuer(prefix = 'token'): {
    fn: (uid: string) => Promise<string>;
    calls: string[];
  } {
    const calls: string[] = [];
    return {
      calls,
      fn: async (uid) => {
        calls.push(uid);
        return `${prefix}:${uid}`;
      },
    };
  }

  it('approves an active session and writes customToken (allow=true)', async () => {
    const { sessionId, nonce } = await seedActiveSession();
    const issuer = fakeTokenIssuer('approved');
    const result = await runConfirmQrLogin(
      'scanner-uid',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer.fn }
    );
    expect(result.state).toBe('approved');
    if (result.state !== 'approved') return;
    expect(result.uid).toBe('scanner-uid');
    expect(result.deviceId).toBe(seedInput.deviceId);
    expect(result.devicePlatform).toBe('ios');
    expect(result.deviceLabel).toBe(seedInput.deviceLabel);
    expect(result.ephemeralPubKeySpki).toBe(seedInput.ephemeralPubKeySpki);

    expect(issuer.calls).toEqual(['scanner-uid']);

    const stored = (await adminDb.doc(`qrLoginSessions/${sessionId}`).get()).data() ?? {};
    expect(stored.state).toBe('approved');
    expect(stored.scannerUid).toBe('scanner-uid');
    expect(stored.customToken).toBe('approved:scanner-uid');
    expect(typeof stored.approvedAt).toBe('string');
    expect(typeof stored.tokenExpiresAt).toBe('string');
  });

  it('rejects without minting customToken when allow=false', async () => {
    const { sessionId, nonce } = await seedActiveSession();
    const issuer = fakeTokenIssuer();
    const result = await runConfirmQrLogin(
      'scanner-uid',
      { sessionId, nonce, allow: false },
      { db: adminDb, createCustomToken: issuer.fn }
    );
    expect(result).toEqual({ state: 'rejected' });
    expect(issuer.calls).toEqual([]);

    const stored = (await adminDb.doc(`qrLoginSessions/${sessionId}`).get()).data() ?? {};
    expect(stored.state).toBe('rejected');
    expect(stored.scannerUid).toBe('scanner-uid');
    expect(stored.customToken).toBeUndefined();
  });

  it('refuses a wrong nonce with permission-denied (and does not mutate the doc)', async () => {
    const { sessionId } = await seedActiveSession();
    const issuer = fakeTokenIssuer();
    await expect(
      runConfirmQrLogin(
        'scanner-uid',
        { sessionId, nonce: 'A'.repeat(32), allow: true },
        { db: adminDb, createCustomToken: issuer.fn }
      )
    ).rejects.toMatchObject({ code: 'permission-denied' });
    expect(issuer.calls).toEqual([]);

    const stored = (await adminDb.doc(`qrLoginSessions/${sessionId}`).get()).data() ?? {};
    expect(stored.state).toBe('awaiting_scan');
    expect(stored.customToken).toBeUndefined();
  });

  it('refuses an expired session with deadline-exceeded and removes the doc', async () => {
    const { sessionId, nonce } = await seedActiveSession();
    // Сдвигаем "сейчас" вперёд за пределы expiresAt.
    const future = new Date(Date.now() + (QR_LOGIN_TTL_SEC + 60) * 1000);
    const issuer = fakeTokenIssuer();
    await expect(
      runConfirmQrLogin(
        'scanner-uid',
        { sessionId, nonce, allow: true },
        { db: adminDb, createCustomToken: issuer.fn, now: () => future }
      )
    ).rejects.toMatchObject({ code: 'deadline-exceeded' });

    const stored = await adminDb.doc(`qrLoginSessions/${sessionId}`).get();
    expect(stored.exists).toBe(false);
  });

  it('refuses replay on already-approved session with failed-precondition', async () => {
    const { sessionId, nonce } = await seedActiveSession();
    const issuer = fakeTokenIssuer('first');
    await runConfirmQrLogin(
      'scanner-uid',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer.fn }
    );
    // Второй вызов с тем же sessionId — состояние уже не awaiting_scan.
    const issuer2 = fakeTokenIssuer('second');
    await expect(
      runConfirmQrLogin(
        'attacker-uid',
        { sessionId, nonce, allow: true },
        { db: adminDb, createCustomToken: issuer2.fn }
      )
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(issuer2.calls).toEqual([]);

    // Документ остался approved, не перезаписан.
    const stored = (await adminDb.doc(`qrLoginSessions/${sessionId}`).get()).data() ?? {};
    expect(stored.state).toBe('approved');
    expect(stored.customToken).toBe('first:scanner-uid');
    expect(stored.scannerUid).toBe('scanner-uid');
  });

  it('rejects unknown sessionId with not-found', async () => {
    const issuer = fakeTokenIssuer();
    await expect(
      runConfirmQrLogin(
        'scanner-uid',
        {
          sessionId: 'X'.repeat(32),
          nonce: 'Y'.repeat(32),
          allow: true,
        },
        { db: adminDb, createCustomToken: issuer.fn }
      )
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('refuses confirmation when scanner account is blocked', async () => {
    const { sessionId, nonce } = await seedActiveSession();
    // Сидируем профиль scannerUid с активным accountBlock.
    await adminDb.doc('users/blocked-uid').set({
      accountBlock: { active: true, blockedAt: new Date().toISOString() },
    });
    const issuer = fakeTokenIssuer();
    await expect(
      runConfirmQrLogin(
        'blocked-uid',
        { sessionId, nonce, allow: true },
        { db: adminDb, createCustomToken: issuer.fn }
      )
    ).rejects.toMatchObject({ code: 'permission-denied' });
    expect(issuer.calls).toEqual([]);
  });
});

describe('geo enrichment of e2eeDevices on approve', () => {
  it('saves country/city from session into the new e2eeDevice doc', async () => {
    // 1. requestQrLogin с заголовками, которые имитируют GCP
    //    geo-headers `X-Appengine-Country` / `X-Appengine-City`.
    const { sessionId, nonce } = await runRequestQrLogin(
      adminDb,
      {
        ephemeralPubKeySpki: 'A'.repeat(120),
        devicePlatform: 'ios',
        deviceLabel: 'iPhone',
        deviceId: 'GEO_TEST_NEW_DEVICE_ID01',
      },
      { country: 'PT', city: 'Lisbon' },
    );

    // 2. Cессия в Firestore должна содержать сохранённую гео-инфу.
    const sessSnap = await adminDb.doc(`qrLoginSessions/${sessionId}`).get();
    const sess = sessSnap.data() ?? {};
    expect(sess.country).toBe('PT');
    expect(sess.city).toBe('Lisbon');

    // 3. confirmQrLogin от scanner-uid одобряет вход.
    const issuer = (uid: string): Promise<string> =>
      Promise.resolve(`ct:${uid}`);
    await runConfirmQrLogin(
      'scanner-uid-geo',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer },
    );

    // 4. После approve admin SDK обновил `users/{scannerUid}/devices/{newDeviceId}`
    //    полями lastLoginCountry / lastLoginCity / lastLoginAt. PII (IP/гео)
    //    сейчас живёт в private `devices/`, не в публично-читаемом
    //    `e2eeDevices/` — см. commit a782f395.
    //    [audit H-003] lastLoginIp убран — IP больше не проходит через
    //    публично-читаемый qrLoginSessions/{sessionId}.
    const deviceSnap = await adminDb
      .doc('users/scanner-uid-geo/devices/GEO_TEST_NEW_DEVICE_ID01')
      .get();
    expect(deviceSnap.exists).toBe(true);
    const dev = deviceSnap.data() ?? {};
    expect(dev.lastLoginCountry).toBe('PT');
    expect(dev.lastLoginCity).toBe('Lisbon');
    expect(dev.lastLoginIp).toBeUndefined();
    expect(typeof dev.lastLoginAt).toBe('string');
  });

  it('skips enrichment if session has malformed deviceId (legacy session)', async () => {
    // Если в `qrLoginSessions` остался документ с deviceId, который не
    // удовлетворяет regex (например, после миграции старого формата), то
    // запись `users/{uid}/e2eeDevices/{newDeviceId}` распалась бы по
    // путю и упала бы Internal. Проверяем, что approve НЕ падает —
    // location-enrichment просто пропускается.
    const sessionId = 'a'.repeat(32);
    const nonceRaw = 'b'.repeat(32);
    await adminDb.doc(`qrLoginSessions/${sessionId}`).set({
      sessionId,
      // hashNonceForStorage(nonce, sessionId) — без него confirm не пройдёт.
      nonceHash: hashNonceForStorage(nonceRaw, sessionId),
      ephemeralPubKeySpki: 'A'.repeat(120),
      devicePlatform: 'ios',
      deviceLabel: 'Legacy iPhone',
      deviceId: 'bad/device/id', // ← нелегальный путь
      state: 'awaiting_scan',
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
    });

    const issuer = (uid: string): Promise<string> =>
      Promise.resolve(`ct:${uid}`);
    const res = await runConfirmQrLogin(
      'scanner-malformed',
      { sessionId, nonce: nonceRaw, allow: true },
      { db: adminDb, createCustomToken: issuer },
    );
    // Approve состоялся — это главное.
    expect(res.state).toBe('approved');
    // А в e2eeDevices ничего не записалось (deviceId небезопасный).
    const devSnap = await adminDb
      .collection('users/scanner-malformed/e2eeDevices')
      .get();
    expect(devSnap.size).toBe(0);
  });

  it('omits empty country/city without crashing', async () => {
    // Если GCP не проставил геолокацию (deploy в локальном эмуляторе или
    // локальная сеть), ctx.country и ctx.city — пустые строки. Тест
    // проверяет что approve всё равно проходит.
    const { sessionId, nonce } = await runRequestQrLogin(adminDb, {
      ephemeralPubKeySpki: 'A'.repeat(120),
      devicePlatform: 'web',
      deviceLabel: 'Local dev',
      deviceId: 'NO_GEO_DEV_ID_2222',
    });

    const issuer = (uid: string): Promise<string> =>
      Promise.resolve(`ct:${uid}`);
    const res = await runConfirmQrLogin(
      'scanner-no-geo',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer },
    );
    expect(res.state).toBe('approved');

    const deviceSnap = await adminDb
      .doc('users/scanner-no-geo/devices/NO_GEO_DEV_ID_2222')
      .get();
    // Документ создаётся даже если геолокации нет — это сигнал, что
    // авторизация прошла, а UI просто не покажет строку location.
    expect(deviceSnap.exists).toBe(true);
    const dev = deviceSnap.data() ?? {};
    expect(dev.lastLoginCountry).toBe('');
    expect(dev.lastLoginCity).toBe('');
  });
});

describe('regression: replay confirm with same allow=true', () => {
  it('first call wins, second call rejected with failed-precondition (was the user-reported bug)', async () => {
    // Симуляция бага из репорта:
    // 1) Пользователь на mobile тапнул «Allow» — первый confirm одобрил.
    // 2) UI обновился медленно, тапнули второй раз — второй confirm
    //    видит state='approved' и валится с FAILED_PRECONDITION.
    // На клиенте теперь ловим эту ошибку как «уже подтверждено» и
    // показываем done вместо красного экрана.
    const { sessionId, nonce } = await runRequestQrLogin(adminDb, {
      ephemeralPubKeySpki: 'A'.repeat(120),
      devicePlatform: 'ios',
      deviceLabel: 'iPhone replay-test',
      deviceId: 'REPLAY_TEST_NEW_ID_XX',
    });

    const issuer1 = (uid: string): Promise<string> =>
      Promise.resolve(`first:${uid}`);
    const ok = await runConfirmQrLogin(
      'replay-scanner',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer1 },
    );
    expect(ok.state).toBe('approved');

    // Второй confirm с тем же sessionId — должен бросить
    // failed-precondition; mobile/web клиент сейчас интерпретирует это
    // как success (документ approved, токен уже выдан).
    const issuer2 = (uid: string): Promise<string> =>
      Promise.resolve(`second:${uid}`);
    let captured: { code?: string; message?: string } | null = null;
    try {
      await runConfirmQrLogin(
        'replay-scanner',
        { sessionId, nonce, allow: true },
        { db: adminDb, createCustomToken: issuer2 },
      );
    } catch (e) {
      captured = e as { code?: string; message?: string };
    }
    expect(captured).not.toBeNull();
    expect(captured?.code).toBe('failed-precondition');
    expect(captured?.message ?? '').toMatch(/in state approved/i);

    // customToken от первого вызова не перезаписан вторым.
    const finalSnap = await adminDb.doc(`qrLoginSessions/${sessionId}`).get();
    expect(finalSnap.data()?.customToken).toBe('first:replay-scanner');
  });
});

describe('end-to-end QR-login roundtrip', () => {
  it('new device sees customToken via public read after approve', async () => {
    // 1. Новое устройство (без auth) запрашивает сессию через core.
    const { sessionId, nonce } = await runRequestQrLogin(adminDb, {
      ephemeralPubKeySpki: 'A'.repeat(120),
      devicePlatform: 'web',
      deviceLabel: 'New device',
      deviceId: 'NEW_DEVICE_ULID_AAAA',
    });

    // 2. Старое устройство сканирует QR и подтверждает (allow=true).
    const issuer = (uid: string): Promise<string> =>
      Promise.resolve(`ct:${uid}`);
    await runConfirmQrLogin(
      'old-device-uid',
      { sessionId, nonce, allow: true },
      { db: adminDb, createCustomToken: issuer }
    );

    // 3. Новое устройство (без auth) читает документ — rules позволяют public
    //    read, чтобы оно могло забрать customToken.
    const newDeviceCtx = testEnv.unauthenticatedContext();
    const snap = await getDoc(
      doc(newDeviceCtx.firestore(), 'qrLoginSessions', sessionId)
    );
    expect(snap.exists()).toBe(true);
    const data = snap.data();
    expect(data?.state).toBe('approved');
    expect(data?.customToken).toBe('ct:old-device-uid');

    // 4. Новое устройство удаляет документ (одноразовый customToken).
    //    Rules позволяют delete для signed-in; на практике это вызов после
    //    signInWithCustomToken. Для интеграционной симуляции используем
    //    authenticatedContext (signed-in scanner uid).
    const deleterCtx = testEnv.authenticatedContext('old-device-uid');
    await assertSucceeds(
      deleteDoc(doc(deleterCtx.firestore(), 'qrLoginSessions', sessionId))
    );

    // 5. Документ удалён — следующий confirmQrLogin вернёт not-found.
    const issuer2 = (uid: string): Promise<string> =>
      Promise.resolve(`ct2:${uid}`);
    await expect(
      runConfirmQrLogin(
        'old-device-uid',
        { sessionId, nonce, allow: true },
        { db: adminDb, createCustomToken: issuer2 }
      )
    ).rejects.toMatchObject({ code: 'not-found' });
  });
});
