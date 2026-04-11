const { app, ipcMain, net } = require('electron');
const path = require('path');
const fs = require('fs');
const fsp = require('fs/promises');
const crypto = require('crypto');

const CHANNEL_GET_CACHED_MEDIA_URL = 'media-cache:getCachedMediaUrl';
const MEDIA_PROTOCOL_SCHEME = 'lighchat-media';
const inFlightCache = new Map();

function sha256Hex(input) {
  return crypto.createHash('sha256').update(String(input)).digest('hex');
}

function guessExtensionFromContentType(contentType) {
  const ct = String(contentType || '').split(';')[0].trim().toLowerCase();
  if (ct === 'image/jpeg') return 'jpg';
  if (ct === 'image/png') return 'png';
  if (ct === 'image/webp') return 'webp';
  if (ct === 'image/gif') return 'gif';
  if (ct === 'video/mp4') return 'mp4';
  if (ct === 'video/webm') return 'webm';
  return null;
}

function toMediaProtocolUrl(filePath) {
  const normalized = path.resolve(filePath);
  return `${MEDIA_PROTOCOL_SCHEME}://local/${encodeURIComponent(normalized)}`;
}

async function ensureDir(dirPath) {
  await fsp.mkdir(dirPath, { recursive: true });
}

async function statIfExists(filePath) {
  try {
    return await fsp.stat(filePath);
  } catch {
    return null;
  }
}

async function downloadToFile(url, targetPath) {
  await ensureDir(path.dirname(targetPath));

  return new Promise((resolve, reject) => {
    const request = net.request({ url, method: 'GET' });
    request.on('response', async (response) => {
      if ((response.statusCode || 0) >= 400) {
        reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }

      const tmpPath = `${targetPath}.tmp.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}`;
      const fileStream = fs.createWriteStream(tmpPath);
      const rejectAndCleanup = (error) => {
        void fsp.unlink(tmpPath).catch(() => {});
        reject(error);
      };
      response.on('error', rejectAndCleanup);
      fileStream.on('error', rejectAndCleanup);

      response.pipe(fileStream);
      fileStream.on('finish', async () => {
        try {
          await fsp.rename(tmpPath, targetPath);
          resolve({
            contentType: response.headers['content-type'],
          });
        } catch (e) {
          reject(e);
        }
      });
    });
    request.on('error', reject);
    request.end();
  });
}

async function getCachePaths(remoteUrl) {
  const baseDir = path.join(app.getPath('userData'), 'media-cache');
  const key = sha256Hex(remoteUrl);
  const metaPath = path.join(baseDir, `${key}.json`);
  const defaultPath = path.join(baseDir, `${key}.bin`);
  return { baseDir, key, metaPath, defaultPath };
}

async function readMeta(metaPath) {
  try {
    const raw = await fsp.readFile(metaPath, 'utf8');
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function writeMeta(metaPath, meta) {
  await ensureDir(path.dirname(metaPath));
  await fsp.writeFile(metaPath, JSON.stringify(meta), 'utf8');
}

async function cacheRemoteUrl(remoteUrl, metaPath, defaultPath) {
  const result = await downloadToFile(remoteUrl, defaultPath);
  const ext = guessExtensionFromContentType(result?.contentType);
  const finalPath = ext ? defaultPath.replace(/\.bin$/, `.${ext}`) : defaultPath;

  if (finalPath !== defaultPath) {
    try {
      await fsp.rename(defaultPath, finalPath);
    } catch {
      // keep .bin if rename fails
    }
  }

  await writeMeta(metaPath, {
    remoteUrl,
    filePath: finalPath,
    cachedAt: Date.now(),
    contentType: result?.contentType || null,
  });

  return finalPath;
}

ipcMain.handle(CHANNEL_GET_CACHED_MEDIA_URL, async (_event, remoteUrl) => {
  if (!remoteUrl || typeof remoteUrl !== 'string') return null;
  if (!/^https?:\/\//i.test(remoteUrl)) return null;

  const { metaPath, defaultPath } = await getCachePaths(remoteUrl);

  const existingMeta = await readMeta(metaPath);
  if (existingMeta?.filePath) {
    const s = await statIfExists(existingMeta.filePath);
    if (s?.isFile()) return toMediaProtocolUrl(existingMeta.filePath);
  }

  // If meta is missing, still try the default path.
  const defaultStat = await statIfExists(defaultPath);
  if (defaultStat?.isFile()) return toMediaProtocolUrl(defaultPath);

  let inFlight = inFlightCache.get(remoteUrl);
  if (!inFlight) {
    inFlight = cacheRemoteUrl(remoteUrl, metaPath, defaultPath);
    inFlightCache.set(remoteUrl, inFlight);
  }

  try {
    const finalPath = await inFlight;
    return toMediaProtocolUrl(finalPath);
  } finally {
    if (inFlightCache.get(remoteUrl) === inFlight) {
      inFlightCache.delete(remoteUrl);
    }
  }
});

module.exports = {
  CHANNEL_GET_CACHED_MEDIA_URL,
  MEDIA_PROTOCOL_SCHEME,
};
