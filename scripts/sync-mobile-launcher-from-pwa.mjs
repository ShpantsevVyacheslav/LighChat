#!/usr/bin/env node
/**
 * Синхронизирует иконку лаунчера Flutter-приложения с PWA:
 * источник — public/pwa/icon-512.png (те же пиксели, что в public/manifest.json).
 * Запись: Android mipmap/ic_launcher.png, iOS AppIcon.appiconset,
 *   mobile/app/web/icons (Flutter Web / установка с экрана «Домой»).
 *
 * Запуск из корня репозитория:
 *   node scripts/sync-mobile-launcher-from-pwa.mjs
 * Вызывается из scripts/generate-pwa-icons.sh после генерации PWA.
 */
import fs from "fs";
import path from "path";
import sharp from "sharp";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");
const SRC = path.join(ROOT, "public/pwa/icon-512.png");
const SRC_MASKABLE = path.join(ROOT, "public/pwa/icon-maskable-512.png");

const ANDROID_LAUNCHERS = [
  ["mobile/app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48],
  ["mobile/app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72],
  ["mobile/app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96],
  ["mobile/app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144],
  ["mobile/app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192],
];

/** Уникальные файлы из AppIcon.appiconset/Contents.json → физический размер в px. */
const IOS_ICONS = [
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png", 20],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png", 40],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png", 60],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png", 29],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png", 58],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png", 87],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png", 40],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png", 80],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png", 120],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png", 120],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png", 180],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png", 76],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png", 152],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png", 167],
  ["mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", 1024],
];

async function writeIcon(outAbs, sizePx, inputPath = SRC) {
  await fs.promises.mkdir(path.dirname(outAbs), { recursive: true });
  await sharp(inputPath)
    .resize(sizePx, sizePx, {
      fit: "cover",
      position: "centre",
    })
    .png()
    .toFile(outAbs);
}

/** Иконки для mobile/app/web/manifest.json — те же файлы, что и в корневом PWA. */
const FLUTTER_WEB_ICONS = [
  ["mobile/app/web/icons/Icon-192.png", 192, SRC],
  ["mobile/app/web/icons/Icon-512.png", 512, SRC],
  ["mobile/app/web/icons/Icon-maskable-192.png", 192, SRC_MASKABLE],
  ["mobile/app/web/icons/Icon-maskable-512.png", 512, SRC_MASKABLE],
];

async function main() {
  if (!fs.existsSync(SRC)) {
    console.error("[sync-mobile-launcher-from-pwa] нет файла:", SRC);
    console.error("Сначала выполните: npm run icons:pwa");
    process.exit(1);
  }
  if (!fs.existsSync(SRC_MASKABLE)) {
    console.error("[sync-mobile-launcher-from-pwa] нет файла:", SRC_MASKABLE);
    console.error("Сначала выполните: npm run icons:pwa");
    process.exit(1);
  }

  const tasks = [
    ...ANDROID_LAUNCHERS.map(([rel, px]) => writeIcon(path.join(ROOT, rel), px)),
    ...IOS_ICONS.map(([rel, px]) => writeIcon(path.join(ROOT, rel), px)),
    ...FLUTTER_WEB_ICONS.map(([rel, px, inp]) => writeIcon(path.join(ROOT, rel), px, inp)),
  ];

  await Promise.all(tasks);
  console.log(
    "[sync-mobile-launcher-from-pwa] OK:",
    ANDROID_LAUNCHERS.length,
    "Android +",
    IOS_ICONS.length,
    "iOS +",
    FLUTTER_WEB_ICONS.length,
    "Flutter Web; источник:",
    SRC,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
