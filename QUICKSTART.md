# Быстрый запуск GrabCam v2.0

## 1. Подготовка
Нужен PHP 8.0+.

Kali Linux:
```bash
sudo apt update
sudo apt install php-cli
```

Termux:
```bash
pkg install php
```

## 2. Запуск
```bash
git clone https://github.com/ERRORoX/grabcam.git
cd grabcam
git checkout exam-safe-v2
chmod +x grabcam.sh
./grabcam.sh
```

Откройте на том же устройстве: http://127.0.0.1:3333

## 3. Проверка
1. Отметьте оба пункта согласия.
2. Нажмите «Согласиться и включить камеру».
3. Разрешите доступ в системном запросе браузера.
4. Убедитесь, что виден preview и сервер сохраняет тестовые снимки в Photo/.
5. Нажмите «Остановить».

Для камеры на другом устройстве требуется HTTPS. Не используйте обычный HTTP по локальной сети для удалённого доступа к камере. Не публикуйте Photo/ напрямую в интернете.
