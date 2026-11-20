<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

function respond(int $status, array $data): void {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    respond(405, ['ok' => false, 'error' => 'Method not allowed']);
}
if (!isset($_FILES['photo']) || !is_uploaded_file($_FILES['photo']['tmp_name'])) {
    respond(400, ['ok' => false, 'error' => 'Photo is required']);
}
$file = $_FILES['photo'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    respond(400, ['ok' => false, 'error' => 'Upload failed']);
}
if ($file['size'] < 1 || $file['size'] > 5 * 1024 * 1024) {
    respond(413, ['ok' => false, 'error' => 'Image must be under 5 MB']);
}
$info = @getimagesize($file['tmp_name']);
if ($info === false || $info['mime'] !== 'image/jpeg') {
    respond(415, ['ok' => false, 'error' => 'Only JPEG images are accepted']);
}

$directory = __DIR__ . DIRECTORY_SEPARATOR . 'Photo';
if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
    respond(500, ['ok' => false, 'error' => 'Cannot create storage directory']);
}
$filename = gmdate('Ymd-His') . '-' . bin2hex(random_bytes(8)) . '.jpg';
$destination = $directory . DIRECTORY_SEPARATOR . $filename;
if (!move_uploaded_file($file['tmp_name'], $destination)) {
    respond(500, ['ok' => false, 'error' => 'Cannot save image']);
}
@chmod($destination, 0600);
respond(201, ['ok' => true, 'filename' => $filename]);
