import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { randomUUID } from "crypto";
import ffmpegInstaller from "@ffmpeg-installer/ffmpeg";
import ffmpeg from "fluent-ffmpeg";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import {
  assertSafeUrl,
  FIREBASE_MEDIA_HOSTS_EXACT,
  FIREBASE_MEDIA_HOST_SUFFIXES,
  SsrfGuardError,
} from "./ssrf-guard";

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

/** Лимит входного файла (байт); сверх — пропуск с логом. */
const MAX_INPUT_BYTES = 220 * 1024 * 1024;

export type ChatMediaNormStatus = "pending" | "done" | "failed";

export type ChatMediaNorm = {
  status: ChatMediaNormStatus;
  failedIndexes?: number[];
  updatedAt: string;
};

type TranscodeTarget = {
  index: number;
  kind: "video" | "audio";
  url: string;
  inputType: string;
};

type TranscodeOptions = {
  forcePendingWrite?: boolean;
};

export function needsTranscodeKind(contentType: string | undefined): "video" | "audio" | null {
  const ct = (contentType || "").toLowerCase();
  if (ct.startsWith("video/")) {
    if (ct === "video/mp4") return null;
    return "video";
  }
  if (ct.startsWith("audio/")) {
    if (ct === "audio/mp4" || ct === "audio/mpeg" || ct === "audio/mp3") return null;
    return "audio";
  }
  return null;
}

function mediaNormPatch(
  status: ChatMediaNormStatus,
  failedIndexes: number[] = []
): { mediaNorm: ChatMediaNorm } {
  const patch: ChatMediaNorm = {
    status,
    updatedAt: new Date().toISOString(),
  };
  if (failedIndexes.length > 0) {
    patch.failedIndexes = [...new Set(failedIndexes)].sort((a, b) => a - b);
  }
  return { mediaNorm: patch };
}

function runFfmpegVideo(inputPath: string, outputPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .outputOptions([
        "-map", "0:v:0",
        "-map", "0:a?",
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "23",
        "-c:a", "aac",
        "-b:a", "128k",
        "-movflags", "+faststart",
      ])
      .output(outputPath)
      .on("end", () => resolve())
      .on("error", (err) => reject(err))
      .run();
  });
}

function runFfmpegAudio(inputPath: string, outputPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .outputOptions(["-vn", "-c:a", "aac", "-b:a", "96k"])
      .output(outputPath)
      .on("end", () => resolve())
      .on("error", (err) => reject(err))
      .run();
  });
}

async function downloadToFile(url: string, dest: string): Promise<number> {
  // SECURITY: `url` ultimately came from a chat participant via
  // attachments[].url — SSRF surface. Restrict
  // to Firebase Storage / signed-URL hosts and block resolution to private
  // IPs (cloud metadata, LAN, link-local). `redirect: 'error'` ensures a
  // 302 to a private host can't bypass the pre-flight check.
  let safe: URL;
  try {
    safe = await assertSafeUrl(url, {
      allowedSchemes: ["https:"],
      allowedHostsExact: FIREBASE_MEDIA_HOSTS_EXACT,
      allowedHostSuffixes: FIREBASE_MEDIA_HOST_SUFFIXES,
    });
  } catch (e) {
    if (e instanceof SsrfGuardError) {
      throw new Error(`url rejected: ${e.code}`);
    }
    throw e;
  }
  const res = await fetch(safe.toString(), { redirect: "error" });
  if (!res.ok) {
    throw new Error(`download failed: ${res.status}`);
  }
  const cl = res.headers.get("content-length");
  if (cl) {
    const n = parseInt(cl, 10);
    if (!Number.isNaN(n) && n > MAX_INPUT_BYTES) {
      throw new Error("content-length exceeds cap");
    }
  }
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length > MAX_INPUT_BYTES) {
    throw new Error("file exceeds cap");
  }
  await fs.promises.writeFile(dest, buf);
  return buf.length;
}

function firebaseStyleDownloadUrl(bucketName: string, objectPath: string, token: string): string {
  const encoded = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encoded}?alt=media&token=${token}`;
}

/**
 * Путь объекта в бакете из публичного download URL Firebase Storage.
 * Удаляем только объекты `chat-attachments/{conversationId}/...` без `norm/`.
 */
function tryOriginalObjectPathToDelete(
  downloadUrl: string,
  conversationId: string
): string | null {
  try {
    const u = new URL(downloadUrl);
    if (!u.hostname.includes("firebasestorage.googleapis.com")) {
      return null;
    }
    const segs = u.pathname.split("/").filter(Boolean);
    const oIdx = segs.indexOf("o");
    if (oIdx < 0 || oIdx >= segs.length - 1) {
      return null;
    }
    const encoded = segs.slice(oIdx + 1).join("/");
    const objectPath = decodeURIComponent(encoded);
    const prefix = `chat-attachments/${conversationId}/`;
    if (!objectPath.startsWith(prefix)) {
      return null;
    }
    if (objectPath.includes("/norm/")) {
      return null;
    }
    return objectPath;
  } catch {
    return null;
  }
}

async function uploadTranscodedLocalFile(
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  destPath: string,
  localPath: string,
  contentType: string
): Promise<{ url: string; size: number }> {
  const token = randomUUID();
  await bucket.upload(localPath, {
    destination: destPath,
    metadata: {
      contentType,
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  const stat = await fs.promises.stat(localPath);
  return {
    url: firebaseStyleDownloadUrl(bucket.name, destPath, token),
    size: stat.size,
  };
}

/**
 * После создания сообщения: перекодирует видео в MP4 (H.264+AAC) и аудио в M4A (AAC),
 * обновляет массив attachments тем же индексом (URL + type + size).
 */
export async function transcodeChatMessageAttachments(
  messageRef: admin.firestore.DocumentReference,
  messageData: admin.firestore.DocumentData,
  conversationId: string,
  opts: TranscodeOptions = {}
): Promise<void> {
  // Phase 7: E2EE v2 — зашифрованные медиа лежат в `chat-attachments-enc/...`,
  // метаданные и ключи хранит клиент. Серверный transcode на таких сообщениях
  // ничего не сможет сделать (нет plaintext), поэтому честно пропускаем.
  const e2ee = messageData.e2ee;
  if (e2ee && typeof e2ee === "object") {
    const version = (e2ee as Record<string, unknown>).protocolVersion;
    if (typeof version === "string" && version.startsWith("v2-")) {
      logger.info("chat transcode skipped: e2ee v2 message", {
        conversationId,
        messageId: messageRef.id,
      });
      if (opts.forcePendingWrite) {
        await messageRef.update(mediaNormPatch("done"));
      }
      return;
    }
  }

  const attachments = messageData.attachments;
  if (!Array.isArray(attachments) || attachments.length === 0) {
    if (opts.forcePendingWrite) {
      await messageRef.update(mediaNormPatch("done"));
    }
    return;
  }

  const bucket = admin.storage().bucket();
  const msgId = messageRef.id;
  const next = [...attachments];
  let anyChange = false;
  const failedIndexes: number[] = [];
  /** После смены URL в Firestore — удалить исходные файлы (один экземпляр в Storage). */
  const originalPathsToDelete: string[] = [];

  const targets: TranscodeTarget[] = [];
  for (let i = 0; i < next.length; i++) {
    const raw = next[i];
    if (!raw || typeof raw !== "object") continue;
    const att = raw as Record<string, unknown>;
    const type = typeof att.type === "string" ? att.type : "";
    const kind = needsTranscodeKind(type);
    const url = typeof att.url === "string" ? att.url : "";
    if (!kind || !url) continue;
    targets.push({
      index: i,
      kind,
      url,
      inputType: type || "unknown",
    });
  }

  if (targets.length === 0) {
    if (opts.forcePendingWrite) {
      await messageRef.update(mediaNormPatch("done"));
    }
    return;
  }

  await messageRef.update(mediaNormPatch("pending"));

  for (const target of targets) {
    const i = target.index;
    const raw = next[i];
    if (!raw || typeof raw !== "object") {
      failedIndexes.push(i);
      continue;
    }
    const att = raw as Record<string, unknown>;
    const { url, kind, inputType } = target;

    const tmpIn = path.join(os.tmpdir(), `lc-in-${randomUUID()}`);
    const extOut = kind === "video" ? "mp4" : "m4a";
    const tmpOut = path.join(os.tmpdir(), `lc-out-${randomUUID()}.${extOut}`);
    const startedAt = Date.now();

    try {
      const bytes = await downloadToFile(url, tmpIn);
      logger.info("chat transcode start", {
        conversationId,
        messageId: msgId,
        attachmentIndex: i,
        kind,
        inputType,
        bytes,
      });

      if (kind === "video") {
        await runFfmpegVideo(tmpIn, tmpOut);
      } else {
        await runFfmpegAudio(tmpIn, tmpOut);
      }

      const destPath =
        `chat-attachments/${conversationId}/norm/${msgId}/a${i}_${Date.now()}_lcnorm.${extOut}`;
      const outMime = kind === "video" ? "video/mp4" : "audio/mp4";
      const uploaded = await uploadTranscodedLocalFile(bucket, destPath, tmpOut, outMime);

      next[i] = {
        ...att,
        url: uploaded.url,
        type: outMime,
        size: uploaded.size,
      };
      anyChange = true;
      const delPath = tryOriginalObjectPathToDelete(url, conversationId);
      if (delPath) {
        originalPathsToDelete.push(delPath);
      }
      logger.info("chat transcode done", {
        conversationId,
        messageId: msgId,
        attachmentIndex: i,
        inputType,
        outputType: outMime,
        durationMs: Date.now() - startedAt,
      });
    } catch (e) {
      failedIndexes.push(i);
      const errMessage = e instanceof Error ? e.message : String(e);
      const lowered = errMessage.toLowerCase();
      let errorCode = "unknown";
      if (lowered.includes("content-length exceeds cap") || lowered.includes("file exceeds cap")) {
        errorCode = "too_large";
      } else if (lowered.includes("download failed")) {
        errorCode = "download_failed";
      } else if (lowered.includes("ffmpeg")) {
        errorCode = "ffmpeg_failed";
      }
      logger.error("chat transcode failed", {
        conversationId,
        messageId: msgId,
        attachmentIndex: i,
        inputType,
        durationMs: Date.now() - startedAt,
        errorCode,
        err: errMessage,
      });
    } finally {
      await fs.promises.rm(tmpIn, { force: true }).catch(() => undefined);
      await fs.promises.rm(tmpOut, { force: true }).catch(() => undefined);
    }
  }

  if (anyChange || failedIndexes.length > 0) {
    const patch: Record<string, unknown> = {
      ...mediaNormPatch(failedIndexes.length > 0 ? "failed" : "done", failedIndexes),
    };
    if (anyChange) {
      patch.attachments = next;
    }
    await messageRef.update(patch);
  } else {
    await messageRef.update(mediaNormPatch("done"));
  }

  for (const p of originalPathsToDelete) {
    try {
      await bucket.file(p).delete({ ignoreNotFound: true });
      logger.info("chat transcode removed original object", { path: p });
    } catch (e) {
      logger.warn("chat transcode could not delete original", {
        path: p,
        err: e instanceof Error ? e.message : String(e),
      });
    }
  }
}
