import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { randomUUID } from "crypto";
import ffmpegInstaller from "@ffmpeg-installer/ffmpeg";
import ffmpeg from "fluent-ffmpeg";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

/** Лимит входного файла (байт); сверх — пропуск с логом. */
const MAX_INPUT_BYTES = 220 * 1024 * 1024;

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
  const res = await fetch(url);
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
  conversationId: string
): Promise<void> {
  const attachments = messageData.attachments;
  if (!Array.isArray(attachments) || attachments.length === 0) {
    return;
  }

  const bucket = admin.storage().bucket();
  const msgId = messageRef.id;
  const next = [...attachments];
  let anyChange = false;
  /** После смены URL в Firestore — удалить исходные файлы (один экземпляр в Storage). */
  const originalPathsToDelete: string[] = [];

  for (let i = 0; i < next.length; i++) {
    const raw = next[i];
    if (!raw || typeof raw !== "object") continue;
    const att = raw as Record<string, unknown>;
    const url = typeof att.url === "string" ? att.url : "";
    const type = typeof att.type === "string" ? att.type : undefined;
    const kind = needsTranscodeKind(type);
    if (!kind || !url) continue;

    const tmpIn = path.join(os.tmpdir(), `lc-in-${randomUUID()}`);
    const extOut = kind === "video" ? "mp4" : "m4a";
    const tmpOut = path.join(os.tmpdir(), `lc-out-${randomUUID()}.${extOut}`);

    try {
      const bytes = await downloadToFile(url, tmpIn);
      logger.info("chat transcode start", { conversationId, msgId, index: i, kind, bytes });

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
      logger.info("chat transcode done", { conversationId, msgId, index: i });
    } catch (e) {
      logger.error("chat transcode failed", {
        conversationId,
        msgId,
        index: i,
        err: e instanceof Error ? e.message : String(e),
      });
    } finally {
      await fs.promises.rm(tmpIn, { force: true }).catch(() => undefined);
      await fs.promises.rm(tmpOut, { force: true }).catch(() => undefined);
    }
  }

  if (anyChange) {
    await messageRef.update({ attachments: next });
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
