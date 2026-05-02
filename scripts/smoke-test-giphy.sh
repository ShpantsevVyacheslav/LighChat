#!/usr/bin/env bash
# Smoke-test для прокси /api/giphy/search.
#
# Использование:
#   ./scripts/smoke-test-giphy.sh                       # тестит https://lighchat.online
#   ./scripts/smoke-test-giphy.sh http://localhost:9002 # тестит локальный dev
#
# Проверяет:
#   1. Endpoint отвечает 200
#   2. Возвращает items[] (не missing_key)
#   3. Trending (q пусто) и stickers (type=stickers) работают

set -e

BASE="${1:-https://lighchat.online}"

echo "Тестируем $BASE/api/giphy/search"
echo ""

check() {
  local name="$1"
  local url="$2"
  echo "→ $name"
  echo "  URL: $url"
  local body
  body=$(curl -s "$url")
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

  if [ "$code" != "200" ]; then
    echo "  ❌ HTTP $code"
    echo "  Ответ: $body"
    return 1
  fi

  if echo "$body" | grep -q '"missing_key"'; then
    echo "  ❌ missing_key — GIPHY_API_KEY не настроен на сервере"
    echo "  Fix: firebase apphosting:secrets:set GIPHY_API_KEY"
    return 1
  fi

  local count
  count=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  if [ "$count" -lt 1 ]; then
    echo "  ❌ Пустой items[]"
    echo "  Ответ: $(echo "$body" | head -c 200)"
    return 1
  fi

  echo "  ✅ OK (items: $count)"
}

check "Trending GIFs (q empty)"      "$BASE/api/giphy/search"
check "Search GIFs (q=cat)"          "$BASE/api/giphy/search?q=cat"
check "Trending stickers (animated)" "$BASE/api/giphy/search?type=stickers"

echo ""
echo "Все тесты прошли."
