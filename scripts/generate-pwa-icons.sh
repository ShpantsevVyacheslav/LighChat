#!/usr/bin/env bash
# PWA / рабочий стол: иконки с белым фоном из public/brand/lighchat-mark-app-icon.png
# Вкладка браузера (фавикон): прозрачный знак из public/brand/lighchat-mark.png
# Сборка знаков: scripts/transparent-lighchat-mark.mjs → npm run brand:mark
set -euo pipefail
cd "$(dirname "$0")/.."
SRC_WHITE="public/brand/lighchat-mark-app-icon.png"
SRC_TRANS="public/brand/lighchat-mark.png"
SRC_SVG="public/brand/lighchat-mark.svg"

if [[ -f "$SRC_WHITE" ]]; then
  SRC_PWA="$SRC_WHITE"
elif [[ -f "$SRC_TRANS" ]]; then
  echo "[generate-pwa-icons] нет $SRC_WHITE — PWA из прозрачного знака (лучше: npm run brand:mark)." >&2
  SRC_PWA="$SRC_TRANS"
elif [[ -f "$SRC_SVG" ]]; then
  SRC_PWA="$SRC_SVG"
else
  echo "Нет $SRC_WHITE, $SRC_TRANS или $SRC_SVG." >&2
  exit 1
fi

if [[ ! -f "$SRC_TRANS" ]]; then
  echo "Нет $SRC_TRANS для фавикона." >&2
  exit 1
fi

# Иконки на экране «Домой» / манифест — белый фон; знак ~82% стороны (поля у края), см. shrink-pwa-icon.mjs
shrink_pwa() {
  local out="$1"
  local sz="$2"
  node scripts/shrink-pwa-icon.mjs "$SRC_PWA" "$out" "$sz"
}

# Фавикон вкладки — без фона
shrink_fav() {
  local out="$1"
  local sz="$2"
  npx sharp-cli -i "$SRC_TRANS" -o "$out" resize "$sz" "$sz" --fit cover --position centre -f png
}

shrink_pwa public/pwa/icon-192.png 192
shrink_pwa public/pwa/icon-512.png 512
shrink_pwa public/pwa/icon-maskable-512.png 512
shrink_pwa public/apple-touch-icon.png 180
shrink_pwa public/icon.png 256

mkdir -p public/pwa
shrink_fav public/pwa/favicon-192.png 192
shrink_fav public/pwa/favicon-512.png 512

cp -f public/pwa/icon-192.png public/icon-192x192.png
cp -f public/pwa/icon-512.png public/icon-512x512.png
mkdir -p public/icons
cp -f public/pwa/icon-192.png public/icons/icon-192x192.png
cp -f public/pwa/icon-512.png public/icons/icon-512x512.png
cp -f public/pwa/icon-maskable-512.png public/icons/icon-maskable-512x512.png
cp -f public/pwa/icon-192.png public/icons/icon-maskable-192x192.png
mkdir -p src/app
cp -f public/pwa/favicon-512.png src/app/icon.png
echo "OK: PWA из $(basename "$SRC_PWA"), favicon из $(basename "$SRC_TRANS") → favicon-*.png, src/app/icon.png"
