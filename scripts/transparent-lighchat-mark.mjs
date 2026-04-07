#!/usr/bin/env node
/**
 * Готовит фирменный маяк для LighChat.
 *
 * Выходы:
 * - `public/brand/lighchat-mark.png` — **прозрачный фон** (авторизация, фавикон, сайдбар).
 * - `public/brand/lighchat-mark-app-icon.png` — тот же знак на **белом квадрате** (PWA / иконка на рабочем столе).
 *
 * Поддержка холста: полоса таба (светлый/серый хром + белый), **или** тёмный/чёрный фон (растр с чёрным).
 *
 * Как использовать:
 *   node scripts/transparent-lighchat-mark.mjs [вход.png] [выход-прозрачный.png]
 *   node scripts/transparent-lighchat-mark.mjs --square-only [вход.png] [выход.png]
 * Исходник по умолчанию: `tmp-mark-src.png`, иначе `public/brand/lighchat-mark-source.png`.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import sharp from "sharp";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const outputAppIconPath = path.join(rootDir, "public/brand/lighchat-mark-app-icon.png");

function resolveDefaultInput() {
  const tmp = path.join(rootDir, "tmp-mark-src.png");
  const canonical = path.join(rootDir, "public/brand/lighchat-mark-source.png");
  if (fs.existsSync(tmp)) return tmp;
  if (fs.existsSync(canonical)) return canonical;
  return tmp;
}

const argv = process.argv.slice(2);
const squareOnly = argv[0] === "--square-only";
const pathArgs = squareOnly ? argv.slice(1) : argv;

/**
 * @param {Buffer} pngBuffer
 * @param {string} outPath
 * @returns {Promise<{ side: number }>}
 */
async function trimAndSquareTransparentPad(pngBuffer, outPath) {
  const trimmed = await sharp(pngBuffer).trim({ threshold: 3 }).toBuffer({ resolveWithObject: true });
  const tw = trimmed.info.width ?? 1;
  const th = trimmed.info.height ?? 1;
  const side = Math.max(tw, th);
  const padL = Math.floor((side - tw) / 2);
  const padT = Math.floor((side - th) / 2);
  const padR = side - tw - padL;
  const padB = side - th - padT;

  await fs.promises.mkdir(path.dirname(outPath), { recursive: true });
  await sharp(trimmed.data)
    .extend({
      left: padL,
      right: padR,
      top: padT,
      bottom: padB,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toFile(outPath);

  return { side };
}

/**
 * @param {string} squareTransparentPath
 */
async function writeAppIconOnWhite(squareTransparentPath) {
  const buf = await fs.promises.readFile(squareTransparentPath);
  const meta = await sharp(buf).metadata();
  const side = meta.width ?? 1;
  const h = meta.height ?? 1;
  await fs.promises.mkdir(path.dirname(outputAppIconPath), { recursive: true });
  await sharp({
    create: {
      width: side,
      height: h,
      channels: 3,
      background: "#ffffff",
    },
  })
    .composite([{ input: buf, left: 0, top: 0 }])
    .png()
    .toFile(outputAppIconPath);
  console.log("[transparent-lighchat-mark] белый фон (PWA):", outputAppIconPath, `${side}×${h}`);
}

/**
 * @param {Buffer} rgba
 * @param {number} w
 * @param {number} h
 */
function isDarkBackgroundCanvas(rgba, w, h) {
  const patch = Math.min(8, w, h);
  let sumMax = 0;
  let count = 0;
  const samplePatch = (x0, y0) => {
    for (let y = y0; y < Math.min(h, y0 + patch); y++) {
      for (let x = x0; x < Math.min(w, x0 + patch); x++) {
        const i = (y * w + x) * 4;
        sumMax += Math.max(rgba[i], rgba[i + 1], rgba[i + 2]);
        count++;
      }
    }
  };
  samplePatch(0, 0);
  samplePatch(Math.max(0, w - patch), 0);
  samplePatch(0, Math.max(0, h - patch));
  samplePatch(Math.max(0, w - patch), Math.max(0, h - patch));
  return count > 0 && sumMax / count < 52;
}

/**
 * @param {Buffer} rgba
 * @param {number} width
 * @param {number} height
 */
function keyNearBlackBackground(rgba, width, height) {
  const B_HARD = 42;
  const B_SOFT = 68;
  const minMaxForColor = 52;
  const minSatColor = 0.12;

  for (let i = 0; i < rgba.length; i += 4) {
    const r = rgba[i];
    const g = rgba[i + 1];
    const b = rgba[i + 2];
    const maxc = Math.max(r, g, b);
    const minc = Math.min(r, g, b);
    const sat = maxc < 1 ? 0 : (maxc - minc) / maxc;
    if (maxc > minMaxForColor && sat > minSatColor) continue;

    const distB = Math.sqrt(r * r + g * g + b * b);
    let a = rgba[i + 3];
    if (distB <= B_HARD) {
      a = 0;
    } else if (distB < B_SOFT) {
      const t = (distB - B_HARD) / (B_SOFT - B_HARD);
      a = Math.round(a * t);
    }
    rgba[i + 3] = a;
  }
}

if (squareOnly) {
  const inputSq = path.resolve(pathArgs[0] ?? path.join(rootDir, "public/brand/lighchat-mark.png"));
  const outputSq = path.resolve(pathArgs[1] ?? inputSq);
  if (!fs.existsSync(inputSq)) {
    console.error("[transparent-lighchat-mark] --square-only: нет файла:", inputSq);
    process.exit(1);
  }
  const buf = await fs.promises.readFile(inputSq);
  const { side } = await trimAndSquareTransparentPad(buf, outputSq);
  await writeAppIconOnWhite(outputSq);
  console.log("[transparent-lighchat-mark] square-only OK:", outputSq, `${side}×${side}`);
  process.exit(0);
}

const input = path.resolve(pathArgs[0] ?? resolveDefaultInput());
const output = path.resolve(pathArgs[1] ?? path.join(rootDir, "public/brand/lighchat-mark.png"));

if (!fs.existsSync(input)) {
  console.error("[transparent-lighchat-mark] нет файла:", input);
  process.exit(1);
}

const HARD = 40;
const SOFT = 72;
const MAX_SAT_BG = 0.22;
const STRIP_ASPECT = 1.35;

/**
 * @param {Buffer} rgba
 * @param {number} w
 * @param {number} h
 * @returns {{ left: number; top: number; width: number; height: number } | null}
 */
function leftMarkBBox(rgba, w, h) {
  const sx = Math.min(8, w);
  const sy = Math.min(8, h);
  let br = 0;
  let bg = 0;
  let bb = 0;
  let n = 0;
  for (let y = 0; y < sy; y++) {
    for (let x = 0; x < sx; x++) {
      const i = (y * w + x) * 4;
      br += rgba[i];
      bg += rgba[i + 1];
      bb += rgba[i + 2];
      n++;
    }
  }
  br /= n;
  bg /= n;
  bb /= n;

  const scanEndX = Math.min(w, h + 10);
  const thresh = 18;
  let minX = w;
  let minY = h;
  let maxX = 0;
  let maxY = 0;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < scanEndX; x++) {
      const i = (y * w + x) * 4;
      const dr = rgba[i] - br;
      const dg = rgba[i + 1] - bg;
      const db = rgba[i + 2] - bb;
      if (Math.sqrt(dr * dr + dg * dg + db * db) > thresh) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) return null;
  const pad = 1;
  const left = Math.max(0, minX - pad);
  const top = Math.max(0, minY - pad);
  const right = Math.min(w - 1, maxX + pad);
  const bottom = Math.min(h - 1, maxY + pad);
  return { left, top, width: right - left + 1, height: bottom - top + 1 };
}

let pipeline = sharp(input).ensureAlpha();
const meta = await sharp(input).metadata();
const fw = meta.width ?? 0;
const fh = meta.height ?? 0;

if (fw > 0 && fh > 0 && fw / fh > STRIP_ASPECT) {
  const full = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const box = leftMarkBBox(full.data, full.info.width, full.info.height);
  if (box && box.width > 8 && box.height > 8) {
    pipeline = pipeline.extract(box);
    console.log("[transparent-lighchat-mark] crop strip →", box);
  }
}

const { data, info } = await pipeline.raw().toBuffer({ resolveWithObject: true });
const w = info.width;
const h = info.height;
const buf = Buffer.from(data);

const darkCanvas = isDarkBackgroundCanvas(buf, w, h);
console.log("[transparent-lighchat-mark] холст:", darkCanvas ? "тёмный (чёрный фон)" : "светлый/таб");

function stripChromeBar(rgba, width, height) {
  const rs = [];
  const gs = [];
  const bs = [];
  const push = (x, y) => {
    const j = (y * width + x) * 4;
    rs.push(rgba[j]);
    gs.push(rgba[j + 1]);
    bs.push(rgba[j + 2]);
  };
  for (let x = 0; x < width; x++) {
    push(x, 0);
    push(x, height - 1);
  }
  for (let y = 0; y < height; y++) {
    push(0, y);
    push(width - 1, y);
  }
  rs.sort((a, b) => a - b);
  gs.sort((a, b) => a - b);
  bs.sort((a, b) => a - b);
  const mid = Math.floor(rs.length / 2);
  const br = rs[mid];
  const bg = gs[mid];
  const bb = bs[mid];

  const chromeHard = 38;
  const chromeSoft = 58;
  const maxSatChrome = 0.12;
  const maxLumChrome = 0.42;

  for (let i = 0; i < rgba.length; i += 4) {
    const r = rgba[i];
    const g = rgba[i + 1];
    const b = rgba[i + 2];
    const rN = r / 255;
    const gN = g / 255;
    const bN = b / 255;
    const maxC = Math.max(rN, gN, bN);
    const minC = Math.min(rN, gN, bN);
    const sat = maxC < 1e-6 ? 0 : (maxC - minC) / maxC;
    const lum = 0.2126 * rN + 0.7152 * gN + 0.0722 * bN;
    if (sat > maxSatChrome || lum > maxLumChrome) continue;

    const dr = r - br;
    const dg = g - bg;
    const db = b - bb;
    const distChrome = Math.sqrt(dr * dr + dg * dg + db * db);

    let a = rgba[i + 3];
    if (distChrome <= chromeHard) {
      a = 0;
    } else if (distChrome < chromeSoft) {
      const t = (distChrome - chromeHard) / (chromeSoft - chromeHard);
      a = Math.round(a * t);
    }
    rgba[i + 3] = a;
  }
}

if (!darkCanvas) {
  stripChromeBar(buf, w, h);
}

if (darkCanvas) {
  keyNearBlackBackground(buf, w, h);
} else {
  for (let i = 0; i < buf.length; i += 4) {
    const r = buf[i];
    const g = buf[i + 1];
    const b = buf[i + 2];
    const rN = r / 255;
    const gN = g / 255;
    const bN = b / 255;
    const max = Math.max(rN, gN, bN);
    const min = Math.min(rN, gN, bN);
    const sat = max < 1e-6 ? 0 : (max - min) / max;

    const dr = 255 - r;
    const dg = 255 - g;
    const db = 255 - b;
    const distW = Math.sqrt(dr * dr + dg * dg + db * db);

    let a = buf[i + 3];
    if (sat > MAX_SAT_BG) continue;

    if (distW <= HARD) {
      a = 0;
    } else if (distW < SOFT) {
      const t = (distW - HARD) / (SOFT - HARD);
      a = Math.round(a * t);
    }
    buf[i + 3] = a;
  }
}

const keyedPng = await sharp(buf, { raw: { width: w, height: h, channels: 4 } }).png().toBuffer();
const { side } = await trimAndSquareTransparentPad(keyedPng, output);

await writeAppIconOnWhite(output);

console.log("[transparent-lighchat-mark] OK:", output, `${side}×${side}`);
