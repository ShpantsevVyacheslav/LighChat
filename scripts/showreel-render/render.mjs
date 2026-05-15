#!/usr/bin/env node
/**
 * LighChat Showreel Renderer — собирает MP4 с озвучкой.
 *
 * Pipeline:
 *  1. Парсит `voiceover.json` (тексты сцен + длительности).
 *  2. `say` генерирует .aiff для каждой сцены, мы паддим silence'ом до целевой длительности.
 *  3. Конкатим все сегменты в один `voiceover.m4a`.
 *  4. Playwright Chromium открывает `showreel-standalone.html?lang=ru` в headless,
 *     записывает .webm через page.video() ровно столько, сколько играется showreel.
 *  5. ffmpeg склеивает video.webm + voiceover.m4a → showreel-<lang>.mp4
 *     (h264 + AAC).
 *
 * Запуск:
 *   node render.mjs --lang=ru
 *   node render.mjs --lang=en  --width=1920 --height=1080
 */

import { spawnSync, spawn } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, statSync, renameSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..', '..');

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

// --- Step 1: voiceover via say + ffmpeg padding ----------------------------

const vo = JSON.parse(readFileSync(VO_JSON, 'utf8'))[LANG];
if (!vo) throw new Error(`No voiceover for lang=${LANG}`);

const segmentFiles = [];
let totalMs = 0;

for (const [idx, scene] of vo.scenes.entries()) {
  const seg = String(idx).padStart(2, '0') + '_' + scene.id;
  const aiff = join(VO_DIR, `${seg}.aiff`);
  const m4a = join(VO_DIR, `${seg}.m4a`);
  console.log(`  · vo ${seg} (${scene.durationMs}ms)`);

  // 1.1. Сначала генерим речь
  const sayRes = spawnSync(
    'say',
    ['-v', vo.voice, '-r', String(vo.rate), '-o', aiff, scene.text],
    { stdio: 'inherit' },
  );
  if (sayRes.status !== 0) throw new Error(`say failed for scene ${scene.id}`);

  // 1.2. Узнаём реальную длительность speech (sec)
  const probe = spawnSync(
    'ffprobe',
    ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', aiff],
    { encoding: 'utf8' },
  );
  const speechSec = Number(String(probe.stdout).trim()) || 0;
  const speechMs = Math.round(speechSec * 1000);
  const targetMs = scene.durationMs;
  // Делаем audio ровно `targetMs` миллисекунд: speech + silence padding
  const padMs = Math.max(0, targetMs - speechMs);

  // 1.3. Конвертим в AAC c паддингом silence через apad+atrim.
  // Формула:
  //   apad=pad_dur=PAD_SEC   — добавить тишины в конец
  //   atrim=end=TARGET_SEC   — обрезать ровно по целевой длительности
  //   aresample=async=1      — выравнивание клока
  const targetSec = (targetMs / 1000).toFixed(3);
  const padSec = (padMs / 1000).toFixed(3);
  const filter = `apad=pad_dur=${padSec},atrim=end=${targetSec},aresample=async=1`;

  const ffRes = spawnSync(
    'ffmpeg',
    [
      '-y',
      '-i', aiff,
      '-af', filter,
      '-ac', '2',
      '-ar', '44100',
      '-c:a', 'aac',
      '-b:a', '128k',
      m4a,
    ],
    { stdio: 'inherit' },
  );
  if (ffRes.status !== 0) throw new Error(`ffmpeg failed for ${seg}`);

  segmentFiles.push(m4a);
  totalMs += targetMs;
}

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
