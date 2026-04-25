import * as http2 from "http2";
import { createHash, createSign } from "crypto";

export type ApnsVoipConfig = {
  keyId: string;
  teamId: string;
  bundleId: string;
  privateKeyPem: string;
  useSandbox: boolean;
};

export type ApnsVoipPayload = {
  callId: string;
  callerId: string;
  callerName: string;
  isVideo: boolean;
};

export type ApnsVoipFailure = {
  token: string;
  status: number;
  reason: string;
};

export type ApnsVoipSendResult = {
  successCount: number;
  failureCount: number;
  failures: ApnsVoipFailure[];
};

function uniqueNonEmpty(values: readonly string[]): string[] {
  return [...new Set(values.map((v) => v.trim()).filter((v) => v.length > 0))];
}

function jsonToBase64Url(value: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(value))
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function createApnsJwt(config: ApnsVoipConfig): string {
  const issuedAt = Math.floor(Date.now() / 1000);
  const header = jsonToBase64Url({
    alg: "ES256",
    kid: config.keyId,
  });
  const payload = jsonToBase64Url({
    iss: config.teamId,
    iat: issuedAt,
  });
  const unsignedToken = `${header}.${payload}`;
  const signer = createSign("SHA256");
  signer.update(unsignedToken);
  signer.end();
  const signature = signer
    .sign(config.privateKeyPem)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  return `${unsignedToken}.${signature}`;
}

function callkitIdFromCallId(callId: string): string {
  const hash = createHash("md5").update(callId).digest("hex");
  return `${hash.slice(0, 8)}-${hash.slice(8, 12)}-${hash.slice(12, 16)}-${hash.slice(16, 20)}-${hash.slice(20, 32)}`;
}

function parseApnsFailureReason(raw: string): string {
  if (!raw.trim()) return "unknown";
  try {
    const parsed = JSON.parse(raw) as { reason?: unknown };
    if (typeof parsed.reason === "string" && parsed.reason.trim().length > 0) {
      return parsed.reason.trim();
    }
  } catch {
    // ignore parse error
  }
  return raw.trim();
}

function apnsEndpoint(config: ApnsVoipConfig): string {
  return config.useSandbox ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
}

function apnsBody(payload: ApnsVoipPayload): string {
  return JSON.stringify({
    aps: {
      "content-available": 1,
      "sound": "default",
    },
    id: callkitIdFromCallId(payload.callId),
    callId: payload.callId,
    callerId: payload.callerId,
    nameCaller: payload.callerName,
    callerName: payload.callerName,
    handle: payload.callerName,
    isVideo: payload.isVideo,
  });
}

async function sendVoipPushToToken({
  client,
  bearerToken,
  config,
  token,
  body,
  collapseId,
}: {
  client: http2.ClientHttp2Session;
  bearerToken: string;
  config: ApnsVoipConfig;
  token: string;
  body: string;
  collapseId: string;
}): Promise<{ ok: boolean; failure?: ApnsVoipFailure }> {
  return new Promise<{ ok: boolean; failure?: ApnsVoipFailure }>((resolve) => {
    let status = 0;
    let responseBody = "";
    let resolved = false;

    const req = client.request({
      [http2.constants.HTTP2_HEADER_METHOD]: "POST",
      [http2.constants.HTTP2_HEADER_PATH]: `/3/device/${token}`,
      "authorization": `bearer ${bearerToken}`,
      "content-type": "application/json",
      "apns-topic": `${config.bundleId}.voip`,
      "apns-push-type": "voip",
      "apns-priority": "10",
      "apns-expiration": "0",
      "apns-collapse-id": collapseId,
    });

    req.setEncoding("utf8");
    req.on("response", (headers) => {
      const rawStatus = headers[http2.constants.HTTP2_HEADER_STATUS];
      if (typeof rawStatus === "number") {
        status = rawStatus;
      } else if (typeof rawStatus === "string") {
        const parsed = Number(rawStatus);
        status = Number.isFinite(parsed) ? parsed : 0;
      }
    });

    req.on("data", (chunk: string) => {
      responseBody += chunk;
    });

    req.on("error", (error) => {
      if (resolved) return;
      resolved = true;
      resolve({
        ok: false,
        failure: {
          token,
          status: status || 0,
          reason: error.message || "request_error",
        },
      });
    });

    req.on("end", () => {
      if (resolved) return;
      resolved = true;
      if (status >= 200 && status < 300) {
        resolve({ ok: true });
        return;
      }
      resolve({
        ok: false,
        failure: {
          token,
          status: status || 0,
          reason: parseApnsFailureReason(responseBody),
        },
      });
    });

    req.end(body);
  });
}

export function isApnsVoipConfigured(config: ApnsVoipConfig): boolean {
  return (
    config.keyId.trim().length > 0 &&
    config.teamId.trim().length > 0 &&
    config.bundleId.trim().length > 0 &&
    config.privateKeyPem.trim().length > 0
  );
}

export async function sendApnsVoipMulticast({
  config,
  tokens,
  payload,
}: {
  config: ApnsVoipConfig;
  tokens: readonly string[];
  payload: ApnsVoipPayload;
}): Promise<ApnsVoipSendResult> {
  const uniqueTokens = uniqueNonEmpty(tokens);
  if (!uniqueTokens.length) {
    return { successCount: 0, failureCount: 0, failures: [] };
  }

  const bearerToken = createApnsJwt(config);
  const body = apnsBody(payload);
  const collapseId = payload.callId;
  const client = http2.connect(apnsEndpoint(config));

  try {
    const settled = await Promise.all(
      uniqueTokens.map((token) =>
        sendVoipPushToToken({
          client,
          bearerToken,
          config,
          token,
          body,
          collapseId,
        })
      )
    );

    const failures = settled
      .filter((item) => !item.ok && item.failure)
      .map((item) => item.failure as ApnsVoipFailure);

    return {
      successCount: settled.length - failures.length,
      failureCount: failures.length,
      failures,
    };
  } finally {
    client.close();
  }
}
