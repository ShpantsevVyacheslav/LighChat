#!/usr/bin/env node
/**
 * PNG для PWA / apple-touch: знак масштабируется до ~CONTENT_SCALE стороны квадрата,
 * затем центрируется на белом поле (маяк не упирается в край иконки на «Домой»).
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

/** Доля стороны под маяк; остальное — белая кайма (визуальный «safe area»). */
const CONTENT_SCALE = 0.82;

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
      background: { r: 255, g: 255, b: 255, alpha: 1 },
    })
    .extend({
      top: padT,
      bottom: padB,
      left: padL,
      right: padR,
      background: { r: 255, g: 255, b: 255, alpha: 1 },
    })
    .png()
    .toFile(output);

  console.log("[shrink-pwa-icon]", output, `${sz}×${sz}`, `mark~${inner}px`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
