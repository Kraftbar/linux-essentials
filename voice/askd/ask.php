<?php
declare(strict_types=1);

/*
 * Ask Claude on lat by voice – called by the "Spør Claude" Siri Shortcut.
 *
 *   POST {"text": "...", "new": false}  header X-Token  -> {"ok", "reply"}
 *
 * LAN only, plus a token from watch_data/ask_token.php (which exits before
 * printing anything). Forwards to askd on 127.0.0.1:7549.
 */

header('Content-Type: application/json; charset=utf-8');

$ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
$lan = strpos($ip, '192.168.1.') === 0 || $ip === '127.0.0.1';
$token = include __DIR__ . '/watch_data/ask_token.php';
if (!$lan || $_SERVER['REQUEST_METHOD'] !== 'POST' || !is_string($token)
        || !hash_equals($token, (string)($_SERVER['HTTP_X_TOKEN'] ?? ''))) {
    http_response_code(403);
    exit(json_encode(['ok' => false, 'reply' => 'Ingen tilgang.']));
}

$body = json_decode((string)file_get_contents('php://input'), true);
$text = trim((string)($body['text'] ?? ''));
if ($text === '' || mb_strlen($text) > 4000) {
    http_response_code(400);
    exit(json_encode(['ok' => false, 'reply' => 'Jeg hørte ingenting.']));
}

$ch = curl_init('http://127.0.0.1:7549/');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode(['text' => $text, 'new' => !empty($body['new'])]),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 130,
]);
$out = curl_exec($ch);
$code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($out === false || $code === 0) {
    http_response_code(502);
    exit(json_encode(['ok' => false, 'reply' => 'Claude på lat svarer ikke.']));
}
http_response_code($code);
echo $out;
