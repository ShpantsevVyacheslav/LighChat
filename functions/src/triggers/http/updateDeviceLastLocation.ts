import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Обновляет «последний вход» (`lastLoginAt`/`lastLoginCity`/`lastLoginCountry`/`lastLoginIp`)
 * для устройства пользователя на основе GeoIP-заголовков, которые Google Cloud
 * проставляет автоматически (`X-Appengine-Country`/`-City`).
 *
 * До этого локация писалась только в момент QR-логина (`confirmQrLogin`). Эта
 * функция позволяет освежать её на каждом старте сессии — клиент дёргает
 * callable, сервер берёт IP/гео из своих заголовков и пишет в
 * `users/{uid}/devices/{deviceId}` через merge.
 *
 * SECURITY: location data lives in the PRIVATE `users/{uid}/devices` collection,
 * not in the world-readable `users/{uid}/e2eeDevices`. Public e2eeDevices is
 * required for cross-peer key lookup (each device must publish its public key
 * so others can wrap chat-keys for it); putting IP/city there exposed every
 * user's last-known location to every other signed-in user.
 *
 * Throttle на сервере: если `lastLoginAt` моложе `THROTTLE_MIN_AGE_SEC`, ничего
 * не пишем (экономим запись в Firestore и предотвращаем абуз). Клиенты тоже
 * имеют свой throttle, но серверный — последний рубеж.
 */

export const THROTTLE_MIN_AGE_SEC = 30 * 60;

export type UpdateDeviceLastLocationInput = {
  deviceId?: unknown;
};

export type UpdateDeviceLastLocationContext = {
  ip?: string;
  country?: string;
  city?: string;
};

export type UpdateDeviceLastLocationResult = {
  updated: boolean;
  reason?: "throttled" | "no_geo" | "device_missing";
};

export async function runUpdateDeviceLastLocation(
  db: admin.firestore.Firestore,
  uid: string,
  data: UpdateDeviceLastLocationInput,
  ctx: UpdateDeviceLastLocationContext = {}
): Promise<UpdateDeviceLastLocationResult> {
  const deviceId = typeof data?.deviceId === "string" ? data.deviceId.trim().slice(0, 64) : "";
  if (!deviceId || deviceId.length < 4) {
    throw new HttpsError("invalid-argument", "Bad deviceId.");
  }

  const country = (ctx.country || "").slice(0, 8);
  const city = (ctx.city || "").slice(0, 64);
  const ip = (ctx.ip || "").slice(0, 64);

  // Если у нас вообще нет гео-данных — нет смысла перетирать существующие,
  // лучше вернуть no_geo, чем затереть валидные значения пустотой.
  if (!country && !city && !ip) {
    return { updated: false, reason: "no_geo" };
  }

  // Read throttle metadata from the private devices collection. The doc may
  // not exist yet (first time we're writing geo for this device) — that's OK,
  // we still proceed to write below. Only "device_missing" if the device is
  // not registered at all in either devices/ or e2eeDevices/ (legitimate
  // session marker should exist via device_session_firestore_sync).
  const privateRef = db.doc(`users/${uid}/devices/${deviceId}`);
  const privateSnap = await privateRef.get();
  if (!privateSnap.exists) {
    // Fall back to e2eeDevices presence as a sign that the device has at
    // least announced its public key — we still won't WRITE to e2eeDevices.
    const e2eeSnap = await db.doc(`users/${uid}/e2eeDevices/${deviceId}`).get();
    if (!e2eeSnap.exists) {
      return { updated: false, reason: "device_missing" };
    }
  }

  const existing = privateSnap.data() ?? {};
  const lastIso = typeof existing.lastLoginAt === "string" ? existing.lastLoginAt : "";
  if (lastIso) {
    const lastMs = Date.parse(lastIso);
    if (Number.isFinite(lastMs)) {
      const ageSec = (Date.now() - lastMs) / 1000;
      if (ageSec < THROTTLE_MIN_AGE_SEC) {
        return { updated: false, reason: "throttled" };
      }
    }
  }

  const nowIso = new Date().toISOString();
  await privateRef.set(
    {
      lastLoginAt: nowIso,
      lastLoginCountry: country,
      lastLoginCity: city,
      lastLoginIp: ip,
    },
    { merge: true }
  );
  return { updated: true };
}

export const updateDeviceLastLocation = onCall(
  { region: "us-central1", enforceAppCheck: false, cors: true },
  async (request): Promise<UpdateDeviceLastLocationResult> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }
    const headers = request.rawRequest?.headers ?? {};
    const xff = headers["x-forwarded-for"];
    const ipFromXff = typeof xff === "string" ?
      xff.split(",")[0]?.trim() ?? "" :
      Array.isArray(xff) ? xff[0]?.trim() ?? "" : "";
    const ip = request.rawRequest?.ip || ipFromXff || "";
    const country = typeof headers["x-appengine-country"] === "string" ?
      headers["x-appengine-country"] :
      "";
    const city = typeof headers["x-appengine-city"] === "string" ?
      headers["x-appengine-city"] :
      "";
    try {
      return await runUpdateDeviceLastLocation(
        admin.firestore(),
        uid,
        request.data as UpdateDeviceLastLocationInput,
        { ip, country, city }
      );
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("updateDeviceLastLocation: unexpected failure", e);
      throw new HttpsError("internal", "Could not update device location.");
    }
  }
);
