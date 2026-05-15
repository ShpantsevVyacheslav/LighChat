#!/usr/bin/env node
/**
 * LighChat Showreel Renderer — собирает MP4 с озвучкой.
 *
 * Pipeline:
 *  1. Парсит `voiceover.json` (тексты сцен + длительности).
 *  2. ElevenLabs TTS API генерирует .mp3 для каждой сцены (модель
 *     `eleven_multilingual_v2`, голоса Rachel/Bella). Паддим silence'ом
 *     до целевой длительности.
 *  3. Конкатим все сегменты в один `voiceover.m4a`.
 *  4. Playwright Chromium открывает `showreel-standalone.html?lang=ru` в headless,
 *     записывает .webm через page.video() ровно столько, сколько играется showreel.
 *  5. ffmpeg склеивает video.webm + voiceover.m4a → showreel-<lang>.mp4
 *     (h264 + AAC).
 *
 * Запуск:
 *   ELEVENLABS_API_KEY=sk_... node render.mjs --lang=ru
 *   (или положите ключ в `.env.local` — он подхватится автоматически).
 *
 *   node render.mjs --lang=en  --width=1920 --height=1080
 */

import { spawnSync, spawn } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, statSync, renameSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// --- .env.local loader (mini-dotenv) ---------------------------------------
// Не тянем зависимостей: читаем `KEY=VALUE` построчно из .env.local,
// если файл есть. Уже выставленные переменные не перезаписываются.
function loadEnvLocal(scriptDir) {
  const file = join(scriptDir, '.env.local');
  if (!existsSync(file)) return;
  for (const raw of readFileSync(file, 'utf8').split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq < 0) continue;
    const key = line.slice(0, eq).trim();
    let val = line.slice(eq + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = val;
  }
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..', '..');

loadEnvLocal(__dirname);

const ELEVEN_API_KEY = process.env.ELEVENLABS_API_KEY;
if (!ELEVEN_API_KEY) {
  console.error('✖ ELEVENLABS_API_KEY не задан.');
  console.error('  Создайте scripts/showreel-render/.env.local со строкой:');
  console.error('    ELEVENLABS_API_KEY=sk_...');
  console.error('  Или экспортируйте переменную перед запуском.');
  process.exit(1);
}

// --- CLI args ---------------------------------------------------------------

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  }),
);
const LANG = args.lang === 'en' ? 'en' : 'ru';
const WIDTH = Number(args.width || 1920);
const HEIGHT = Number(args.height || 1080);

// --- Paths ------------------------------------------------------------------

const VO_JSON = join(__dirname, 'voiceover.json');
const HTML_FILE = join(__dirname, 'showreel-standalone.html');
const OUT_DIR = join(REPO_ROOT, 'public', 'showreel');
const WORK_DIR = join(__dirname, '.work', LANG);
const VO_DIR = join(WORK_DIR, 'vo');
const VIDEO_DIR = join(WORK_DIR, 'video');
const OUT_MP4 = join(OUT_DIR, `showreel-${LANG}.mp4`);

mkdirSync(OUT_DIR, { recursive: true });
mkdirSync(VO_DIR, { recursive: true });
mkdirSync(VIDEO_DIR, { recursive: true });

console.log(`▶ LighChat showreel renderer · lang=${LANG} · ${WIDTH}×${HEIGHT}`);
console.log(`  out → ${OUT_MP4}`);

// --- Step 1: voiceover via ElevenLabs API + ffmpeg padding -----------------

const vo = JSON.parse(readFileSync(VO_JSON, 'utf8'))[LANG];
if (!vo) throw new Error(`No voiceover for lang=${LANG}`);
if (!vo.elevenlabs) throw new Error(`voiceover.json: no .elevenlabs config for ${LANG}`);

const el = vo.elevenlabs;
console.log(`  · TTS engine: ElevenLabs · voice=${el.voiceName} (${el.voiceId}) · model=${el.modelId}`);

async function elevenLabsTts(text, outMp3Path, { retries = 3 } = {}) {
  const url = `https://api.elevenlabs.io/v1/text-to-speech/${el.voiceId}?output_format=mp3_44100_128`;
  const body = JSON.stringify({
    text,
    model_id: el.modelId,
    voice_settings: {
      stability: el.stability ?? 0.5,
      similarity_boost: el.similarityBoost ?? 0.75,
      style: el.style ?? 0,
      use_speaker_boost: el.speakerBoost ?? true,
    },
  });
  // Ретраим только сетевые ошибки и 5xx. 4xx (например 402 paid_plan_required)
  // повторять бессмысленно — это конфигурационная проблема, не транзиентная.
  let lastErr;
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'xi-api-key': ELEVEN_API_KEY,
          'Content-Type': 'application/json',
          accept: 'audio/mpeg',
        },
        body,
      });
      if (res.ok) {
        const buf = Buffer.from(await res.arrayBuffer());
        writeFileSync(outMp3Path, buf);
        return buf.length;
      }
      const errText = await res.text().catch(() => '');
      if (res.status < 500) {
        // 4xx — не ретраим
        throw new Error(`ElevenLabs HTTP ${res.status}: ${errText.slice(0, 400)}`);
      }
      lastErr = new Error(`ElevenLabs HTTP ${res.status}: ${errText.slice(0, 400)}`);
    } catch (e) {
      lastErr = e;
      // network errors (UND_ERR_SOCKET, ECONNRESET, fetch failed) — ретраим
      if (!/fetch failed|SocketError|ECONN|ENETUNREACH|HTTP 5\d\d/.test(String(e.message || e))) {
        throw e;
      }
    }
    const delay = 1000 * attempt; // 1s, 2s, 3s
    console.warn(`    ⚠ TTS attempt ${attempt}/${retries} failed (${lastErr.message}); retrying in ${delay}ms…`);
    await new Promise((r) => setTimeout(r, delay));
  }
  throw lastErr;
}

const segmentFiles = [];
let totalMs = 0;
let totalChars = 0;

for (const [idx, scene] of vo.scenes.entries()) {
  const seg = String(idx).padStart(2, '0') + '_' + scene.id;
  const mp3 = join(VO_DIR, `${seg}.mp3`);
  const m4a = join(VO_DIR, `${seg}.m4a`);
  console.log(`  · vo ${seg} (${scene.durationMs}ms · ${scene.text.length} chars)`);
  totalChars += scene.text.length;

  // 1.1. Генерим речь через ElevenLabs (возвращает mp3 44.1kHz 128kbps)
  const audioBytes = await elevenLabsTts(scene.text, mp3);
  if (audioBytes < 1000) throw new Error(`tts produced suspiciously small audio for ${seg}: ${audioBytes}B`);

  // 1.2. Узнаём реальную длительность speech (sec)
  const probe = spawnSync(
    'ffprobe',
    ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', mp3],
    { encoding: 'utf8' },
  );
  const speechSec = Number(String(probe.stdout).trim()) || 0;
  const speechMs = Math.round(speechSec * 1000);
  const targetMs = scene.durationMs;
  // Делаем audio ровно `targetMs` миллисекунд: speech + silence padding.
  // Если речь длиннее сцены — atrim обрежет конец (не должно случаться при
  // нормальных тайминигах, но страхует).
  const padMs = Math.max(0, targetMs - speechMs);

  // 1.3. Конвертим в AAC c паддингом silence через apad+atrim.
  const targetSec = (targetMs / 1000).toFixed(3);
  const padSec = (padMs / 1000).toFixed(3);
  const filter = `apad=pad_dur=${padSec},atrim=end=${targetSec},aresample=async=1`;

  const ffRes = spawnSync(
    'ffmpeg',
    [
      '-y',
      '-i', mp3,
      '-af', filter,
      '-ac', '2',
      '-ar', '44100',
      '-c:a', 'aac',
      '-b:a', '160k',
      m4a,
    ],
    { stdio: 'inherit' },
  );
  if (ffRes.status !== 0) throw new Error(`ffmpeg failed for ${seg}`);

  segmentFiles.push(m4a);
  totalMs += targetMs;
}

console.log(`  ✓ ElevenLabs spent: ${totalChars} chars (free tier = 10 000/mo)`);

console.log(`  ✓ voiceover: ${segmentFiles.length} segments, total ${(totalMs / 1000).toFixed(1)}s`);

// 1.4. Конкатим все сегменты в один файл через ffmpeg concat-demuxer.
const concatList = join(VO_DIR, 'concat.txt');
writeFileSync(concatList, segmentFiles.map((f) => `file '${f}'`).join('\n'));
const fullAudio = join(WORK_DIR, 'voiceover.m4a');
const concatRes = spawnSync(
  'ffmpeg',
  ['-y', '-f', 'concat', '-safe', '0', '-i', concatList, '-c', 'copy', fullAudio],
  { stdio: 'inherit' },
);
if (concatRes.status !== 0) throw new Error('voiceover concat failed');
console.log(`  ✓ voiceover.m4a built`);

// --- Step 2: Playwright screen recording -----------------------------------

console.log('▶ Playwright screencast…');
const { chromium } = await import('playwright');
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: WIDTH, height: HEIGHT },
  recordVideo: { dir: VIDEO_DIR, size: { width: WIDTH, height: HEIGHT } },
  deviceScaleFactor: 1,
});
const page = await context.newPage();

const fileUrl = pathToFileURL(HTML_FILE).toString() + `?lang=${LANG}`;
await page.goto(fileUrl);
await page.waitForFunction(() => window.__SHOWREEL_READY__ === true);

// Стартуем плеер.
const startedAt = Date.now();
await page.evaluate(() => window.__START_PLAYBACK__());

// Ждём пока шоурил отыграет всю timeline (со страховкой +1.5s)
const TIMELINE_MS = totalMs + 1500;
await page.waitForFunction(
  () => window.__SHOWREEL_DONE__ === true,
  null,
  { timeout: TIMELINE_MS + 5000 },
);
const playedMs = Date.now() - startedAt;
console.log(`  ✓ playback finished in ${(playedMs / 1000).toFixed(1)}s`);

await page.close();
await context.close();
await browser.close();

// Playwright сохранил .webm со случайным именем — найдём его
const fs = await import('node:fs/promises');
const files = (await fs.readdir(VIDEO_DIR)).filter((f) => f.endsWith('.webm'));
if (files.length === 0) throw new Error('no .webm produced');
const rawVideo = join(VIDEO_DIR, files[0]);
const videoSize = statSync(rawVideo).size;
console.log(`  ✓ video.webm = ${(videoSize / 1024 / 1024).toFixed(1)} MB`);

// --- Step 3: mux video + audio → MP4 (h264 + AAC) --------------------------

console.log('▶ ffmpeg mux → mp4 (h264 + AAC)…');
const muxRes = spawnSync(
  'ffmpeg',
  [
    '-y',
    '-i', rawVideo,
    '-i', fullAudio,
    '-map', '0:v:0',
    '-map', '1:a:0',
    '-c:v', 'libx264',
    '-preset', 'medium',
    '-crf', '22',
    '-pix_fmt', 'yuv420p',
    '-c:a', 'aac',
    '-b:a', '160k',
    '-movflags', '+faststart',
    '-shortest',
    OUT_MP4,
  ],
  { stdio: 'inherit' },
);
if (muxRes.status !== 0) throw new Error('mux failed');

const outSize = statSync(OUT_MP4).size;
console.log(`\n✅ Done · ${OUT_MP4} · ${(outSize / 1024 / 1024).toFixed(1)} MB`);

// Аккуратно чистим временные файлы — оставляем только итоговый mp4
try {
  rmSync(WORK_DIR, { recursive: true, force: true });
} catch (e) {
  console.warn(`  ⚠ could not clean ${WORK_DIR}: ${e.message}`);
}
