<?php
declare(strict_types=1);

/*
 * Ask Claude on lat by voice – called by the ClaudeWatch voice page.
 *
 *   POST <signed JSON body>  header X-Sig            -> {"ok", "reply"}
 *   POST <raw m4a>  headers X-Sig + X-Meta (signed JSON) -> {"ok", "heard", "reply"}
 *
 * Just a pipe: askd on 127.0.0.1:7549 checks the device signature (Secure
 * Enclave key, see askd.py) and runs `claude -p` as nybo.
 */

header('Content-Type: application/json; charset=utf-8');

$raw = (string)file_get_contents('php://input');
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || $raw === '' || strlen($raw) > 3000000) {
    error_log(sprintf('ask.php 400: %s len=%d cl=%s ct=%s te=%s', $_SERVER['REQUEST_METHOD'], strlen($raw),
        $_SERVER['CONTENT_LENGTH'] ?? '-', $_SERVER['CONTENT_TYPE'] ?? '-', $_SERVER['HTTP_TRANSFER_ENCODING'] ?? '-'));
    http_response_code(400);
    exit(json_encode(['ok' => false, 'reply' => 'Ugyldig forespørsel.']));
}

$ch = curl_init('http://127.0.0.1:7549/');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $raw,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/octet-stream',
        'X-Sig: ' . preg_replace('/[^A-Za-z0-9+\/=]/', '', (string)($_SERVER['HTTP_X_SIG'] ?? '')),
        'X-Meta: ' . preg_replace('/[^A-Za-z0-9+\/=]/', '', (string)($_SERVER['HTTP_X_META'] ?? '')),
    ],
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
