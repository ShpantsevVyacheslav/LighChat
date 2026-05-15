#!/usr/bin/env bash
#
# Mobile Showreel Recorder — гибрид: 10 manual-сцен + 6 mock-сцен.
#
# Каждая сцена пишется в отдельный .mp4 через `xcrun simctl io recordVideo`.
# Скрипт можно прерывать в любой момент и запускать повторно — пропускает
# уже снятые сцены (по наличию clips/<NN_id>.mp4).
#
# Использование:
#   ./record.sh              # пройти все 16 сцен
#   ./record.sh --only 03    # снять только сцену #03
#   ./record.sh --retake 05  # перезаснять сцену #05 (удалит старый clip)
#
# Перед запуском:
#   1. Запустить iPhone 16 Pro simulator (Xcode → Simulator → Device → iPhone 16 Pro)
#   2. Установить и залогинить LighChat в simulator
#   3. Подготовить тестовые чаты (seed)

set -eo pipefail

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
CLIPS_DIR="$SCRIPT_DIR/clips"
MANIFEST="$SCRIPT_DIR/scenes.json"

mkdir -p "$CLIPS_DIR"

# --- args ------------------------------------------------------------------

ONLY=""
RETAKE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only) ONLY="$2"; shift 2;;
    --retake) RETAKE="$2"; shift 2;;
    -h|--help)
      sed -n '2,16p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# --- check simulator -------------------------------------------------------

BOOTED_UDID="$(xcrun simctl list devices booted -j | /usr/bin/python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data['devices'].items():
    for d in devs:
        if d.get('state') == 'Booted':
            print(d['udid']); sys.exit(0)
")"

if [[ -z "$BOOTED_UDID" ]]; then
  echo "✖ Нет запущенного simulator. Откройте Xcode → Simulator → iPhone 16 Pro."
  echo "  Или: xcrun simctl boot 'iPhone 16 Pro'"
  exit 1
fi

DEVICE_NAME="$(xcrun simctl list devices booted -j | /usr/bin/python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data['devices'].items():
    for d in devs:
        if d.get('state') == 'Booted':
            print(d['name']); sys.exit(0)
")"

echo "▶ Simulator: $DEVICE_NAME ($BOOTED_UDID)"
echo "▶ Manifest:  $MANIFEST"
echo "▶ Clips dir: $CLIPS_DIR"
echo ""

# --- iterate scenes --------------------------------------------------------

SCENE_COUNT="$(/usr/bin/python3 -c "import json; print(len(json.load(open('$MANIFEST'))['scenes']))")"

for ((i=0; i<SCENE_COUNT; i++)); do
  IDX="$(printf '%02d' "$i")"

  read SCENE_ID DURATION_MS KIND <<< "$(
    /usr/bin/python3 -c "
import json
s = json.load(open('$MANIFEST'))['scenes'][$i]
print(s['id'], s['durationMs'], s['kind'])
"
  )"

  HINT="$(
    /usr/bin/python3 -c "
import json
print(json.load(open('$MANIFEST'))['scenes'][$i]['hint'])
"
  )"

  CLIP_PATH="$CLIPS_DIR/${IDX}_${SCENE_ID}.mp4"
  DURATION_SEC="$(/usr/bin/python3 -c "print($DURATION_MS / 1000)")"

  # фильтр --only / --retake
  if [[ -n "$ONLY" && "$ONLY" != "$IDX" && "$ONLY" != "$SCENE_ID" ]]; then continue; fi
  if [[ -n "$RETAKE" && ("$RETAKE" == "$IDX" || "$RETAKE" == "$SCENE_ID") ]]; then
    echo "  · retake → удаляю старый $CLIP_PATH"
    rm -f "$CLIP_PATH"
  fi

  # уже снято — skip
  if [[ -f "$CLIP_PATH" && -z "$ONLY" ]]; then
    echo "  ✓ ${IDX}_${SCENE_ID}  (уже снято — skip; --retake $IDX чтобы перезаснять)"
    continue
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Сцена $IDX/$((SCENE_COUNT - 1))  ·  $SCENE_ID  ·  ${DURATION_SEC}s  ·  kind=$KIND"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Что показать:"
  printf '  %s\n' "$HINT" | fold -s -w 76 | sed 's/^/  /'
  echo ""

  case "$KIND" in
    auto)
      echo "Это «auto»-сцена. Подготовьте экран как описано выше."
      ;;
    manual)
      echo "Это «manual»-сцена. Подготовьте симулятор, прежде чем нажмёте старт."
      ;;
    mock)
      echo "Это «mock»-сцена. Откройте в приложении путь:"
      echo "    /features/showreel  (там найдите сегмент '$SCENE_ID')"
      echo "  Запись начнётся сразу — постарайтесь попасть на нужный кадр."
      ;;
  esac

  echo ""
  read -p "  ↩ Нажмите ENTER чтобы СТАРТОВАТЬ запись (${DURATION_SEC}s) или 's' чтобы пропустить: " ans
  if [[ "$ans" == "s" ]]; then
    echo "  → skip"
    continue
  fi

  echo "  ● recording…"
  xcrun simctl io "$BOOTED_UDID" recordVideo --codec=h264 --force "$CLIP_PATH" &
  REC_PID=$!

  # Прогресс-бар простой
  for ((s=1; s<=DURATION_SEC; s++)); do
    sleep 1
    printf "\r  ● recording  %3d/%-3ds" "$s" "$DURATION_SEC"
  done
  echo ""

  kill -SIGINT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true

  if [[ ! -f "$CLIP_PATH" ]]; then
    echo "  ✖ Файл не создан. Возможно, запись прервалась."
    exit 1
  fi
  SIZE_KB="$(du -k "$CLIP_PATH" | cut -f1)"
  echo "  ✓ ${IDX}_${SCENE_ID}.mp4 = ${SIZE_KB} KB"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Все сцены сняты. Дальше: node stitch.mjs --lang=ru"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
