#!/usr/bin/env bash
# Готовит build/icon-mac.png (≥512×512) для electron-builder на macOS — из него будет .icns в DMG/Dock.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/public/icon.png"
OUT="${ROOT}/build/icon-mac.png"
if [[ ! -f "$SRC" ]]; then
  echo "[generate-mac-icon] Нет файла: $SRC" >&2
  exit 1
fi
mkdir -p "${ROOT}/build"
# electron-builder для Mac ожидает PNG минимум 512×512; исходник часто 256 — масштабируем.
sips -z 1024 1024 "$SRC" --out "$OUT" >/dev/null
echo "[generate-mac-icon] OK → $OUT (1024×1024)"
