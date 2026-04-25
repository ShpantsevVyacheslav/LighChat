#!/usr/bin/env node
/**
 * PNG для PWA / apple-touch: знак масштабируется до ~CONTENT_SCALE стороны квадрата,
 * затем центрируется на синем фоне приложения (без белой рамки по краям).
 *
 * Использование: node scripts/shrink-pwa-icon.mjs <вход.png> <выход.png> <размер>
 * Вызывается из scripts/generate-pwa-icons.sh после `cd` в корень репозитория.
 */
import fs from "fs";
import path from "path";
import sharp from "sharp";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const [, , input, output, szStr] = process.argv;
if (!input || !output || !szStr) {
  console.error("Usage: shrink-pwa-icon.mjs <input> <output> <size>");
  process.exit(1);
}

const sz = parseInt(szStr, 10);
if (!Number.isFinite(sz) || sz < 16) {
  console.error("shrink-pwa-icon: invalid size");
  process.exit(1);
}

/** Доля стороны под иконку; 1.0 = без внешней каймы. */
const CONTENT_SCALE = 1.0;
const APP_BG = { r: 21, g: 64, b: 96, alpha: 1 };

async function main() {
  if (!fs.existsSync(input)) {
    console.error("shrink-pwa-icon: missing input:", input);
    process.exit(1);
  }

  const inner = Math.max(1, Math.round(sz * CONTENT_SCALE));
  const padT = Math.floor((sz - inner) / 2);
  const padL = Math.floor((sz - inner) / 2);
  const padB = sz - inner - padT;
  const padR = sz - inner - padL;

  await fs.promises.mkdir(path.dirname(path.resolve(output)), { recursive: true });

  await sharp(input)
    .resize(inner, inner, {
      fit: "contain",
      background: APP_BG,
    })
    // Убираем альфу: края всегда на фирменном синем фоне, без светлой окантовки.
    .flatten({ background: APP_BG })
    .extend({
      top: padT,
      bottom: padB,
      left: padL,
      right: padR,
      background: APP_BG,
    })
    .png()
    .toFile(output);

  console.log("[shrink-pwa-icon]", output, `${sz}×${sz}`, `mark~${inner}px`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
