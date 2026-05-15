#!/usr/bin/env node
/**
 * Mobile Showreel Stitcher.
 *
 * Берёт 16 клипов из ./clips/<NN_id>.mp4 (после record.sh),
 * паддит/тримит каждый ровно до scene.durationMs, конкатит в один
 * портретный 1080×1920 поток через ffmpeg + накладывает озвучку из
 * scripts/showreel-render/.work/<lang>/voiceover.m4a (если его уже
 * нет — генерим через ElevenLabs так же, как в render.mjs основного
 * web-showreel).
 *
 * Запуск:
 *   node stitch.mjs --lang=ru
 *   node stitch.mjs --lang=en
 *
 * Выход: ../../public/showreel/showreel-mobile-<lang>.mp4
 */

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..', '..');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  }),
);
const LANG = args.lang === 'en' ? 'en' : 'ru';
// Output 9:16 (Stories/Reels/App Preview).
const OUT_W = Number(args.width || 1080);
const OUT_H = Number(args.height || 1920);
const FPS = Number(args.fps || 30);

const CLIPS_DIR = join(__dirname, 'clips');
const WORK_DIR = join(__dirname, '.work', LANG);
const OUT_DIR = join(REPO_ROOT, 'public', 'showreel');
const OUT_MP4 = join(OUT_DIR, `showreel-mobile-${LANG}.mp4`);
const MANIFEST = JSON.parse(readFileSync(join(__dirname, 'scenes.json'), 'utf8'));

mkdirSync(WORK_DIR, { recursive: true });
mkdirSync(OUT_DIR, { recursive: true });

console.log(`▶ Mobile showreel stitcher · lang=${LANG} · ${OUT_W}×${OUT_H} @ ${FPS}fps`);
console.log(`  clips → ${CLIPS_DIR}`);
console.log(`  out   → ${OUT_MP4}`);

// --- Step 1: подтянуть/собрать voiceover ----------------------------------
//
// Если в ../showreel-render/.work/<lang>/voiceover.m4a уже есть — берём.
// Иначе вызываем render.mjs только для TTS-фазы. (По дефолту render.mjs
// чистит .work/ после успешного прогона, поэтому voiceover может
// отсутствовать — это нормально для повторных запусков mobile-stitcher.)

const WEB_VOICEOVER = join(REPO_ROOT, 'scripts', 'showreel-render', '.work', LANG, 'voiceover.m4a');
let voiceover = WEB_VOICEOVER;
if (!existsSync(voiceover)) {
  console.log(`  · voiceover.m4a не найден — извлекаю из готового web-showreel`);
  // Берём звук из уже отрендеренного web-showreel-<lang>.mp4
  const webMp4 = join(OUT_DIR, `showreel-${LANG}.mp4`);
  if (!existsSync(webMp4)) {
    console.error(`✖ Не нашёл ни ${WEB_VOICEOVER}, ни ${webMp4}.`);
    console.error('  Сначала запустите web-рендер: cd scripts/showreel-render && node render.mjs --lang=' + LANG);
    process.exit(1);
  }
  voiceover = join(WORK_DIR, 'voiceover.m4a');
  const ex = spawnSync(
    'ffmpeg',
    ['-y', '-i', webMp4, '-vn', '-acodec', 'copy', voiceover],
    { stdio: 'inherit' },
  );
  if (ex.status !== 0) throw new Error('ffmpeg failed to extract audio from web showreel');
  console.log(`  ✓ voiceover извлечён в ${voiceover}`);
}

// --- Step 2: нормализуем каждый клип в 1080×1920 / FPS / нужная длительность

const scenes = MANIFEST.scenes;
const normClips = [];
let totalMs = 0;

for (const [idx, scene] of scenes.entries()) {
  const idxStr = String(idx).padStart(2, '0');
  const inClip = join(CLIPS_DIR, `${idxStr}_${scene.id}.mp4`);
  if (!existsSync(inClip)) {
    console.error(`✖ Не нашёл clip: ${inClip}`);
    console.error('  Запустите record.sh для этой сцены (или --only ' + idxStr + ').');
    process.exit(1);
  }
  const outClip = join(WORK_DIR, `${idxStr}_${scene.id}_norm.mp4`);
  const durSec = (scene.durationMs / 1000).toFixed(3);

  // Простой подход:
  //  - scale=1080:1920 с force_original_aspect_ratio=increase + crop
  //    делает portrait-fit без чёрных полос (немного обрезается края);
  //  - setpts/atrim - выравниваем длительность ровно по durationMs
  //  - убираем звук из симулятора (нам нужен только voiceover на финале)
  const vfChain = [
    `scale=${OUT_W}:${OUT_H}:force_original_aspect_ratio=increase`,
    `crop=${OUT_W}:${OUT_H}`,
    `setpts=PTS-STARTPTS`,
    `fps=${FPS}`,
  ].join(',');

  console.log(`  · norm ${idxStr}_${scene.id}  (${durSec}s)`);
  const res = spawnSync(
    'ffmpeg',
    [
      '-y',
      '-i', inClip,
      '-an',                   // strip audio (мы наложим свой voiceover)
      '-t', durSec,            // trim до точной длительности
      '-vf', vfChain,
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '20',
      '-pix_fmt', 'yuv420p',
      outClip,
    ],
    { stdio: 'inherit' },
  );
  if (res.status !== 0) throw new Error(`ffmpeg normalize failed for ${idxStr}`);
  normClips.push(outClip);
  totalMs += scene.durationMs;
}

console.log(`  ✓ нормализовано ${normClips.length} клипов, общая длительность ${(totalMs / 1000).toFixed(1)}s`);

// --- Step 3: concat нормализованных клипов через ffmpeg concat demuxer ----

const concatList = join(WORK_DIR, 'concat.txt');
writeFileSync(concatList, normClips.map((f) => `file '${f}'`).join('\n'));
const videoMuxed = join(WORK_DIR, 'video.mp4');
const concatRes = spawnSync(
  'ffmpeg',
  ['-y', '-f', 'concat', '-safe', '0', '-i', concatList, '-c', 'copy', videoMuxed],
  { stdio: 'inherit' },
);
if (concatRes.status !== 0) throw new Error('concat failed');
console.log(`  ✓ video.mp4 собран`);

// --- Step 4: mux video + voiceover -> финальный mp4 -----------------------

const muxRes = spawnSync(
  'ffmpeg',
  [
    '-y',
    '-i', videoMuxed,
    '-i', voiceover,
    '-map', '0:v:0',
    '-map', '1:a:0',
    '-c:v', 'copy',
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
