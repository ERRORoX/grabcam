<?php
declare(strict_types=1);
http_response_code(410);
header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');
echo "Этот устаревший endpoint отключён в GrabCam v2.0. Используйте страницу согласованной демонстрации.";
