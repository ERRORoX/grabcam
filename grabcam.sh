#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-3333}"
HOST="${HOST:-127.0.0.1}"

if ! command -v php >/dev/null 2>&1; then
  echo "PHP не найден. Установите PHP и повторите запуск."
  exit 1
fi

if [[ ! -f "grabcam.html" || ! -f "post.php" ]]; then
  echo "Запустите скрипт из корневой папки GrabCam."
  exit 1
fi

echo "GrabCam v2.0 запускается: http://${HOST}:${PORT}"
echo "Остановка сервера: Ctrl+C"
echo "Для доступа с телефона используйте HTTPS-хостинг или localhost на самом устройстве."
exec php -S "${HOST}:${PORT}"
