<?php
/*
 * Developed by: Md. Saiful Islam
 * Email: e2getway@gmail.com
 * Website: https://edatastyle.com/
 */

require __DIR__ . '/../lib.php';
header('Content-Type: application/json'); header('Cache-Control: no-store');
$tok = csrf(); $ok = authed(); session_write_close(); // release the session lock so polling stays fast
if (!$ok) { http_response_code(401); exit('{"ok":false,"error":"Please sign in again"}'); }
$A = ['overview' => [], 'state' => [], 'logs' => ['ip', 'domain', 'limit'], 'apply' => [], 'restart-hotspot' => [], 'diagnose' => [],
      'block-domain' => ['domain'], 'unblock-domain' => ['domain'], 'redirect' => ['domain', 'target'], 'unredirect' => ['domain'],
      'block-mac' => ['mac'], 'unblock-mac' => ['mac'], 'allow-mac' => ['mac'], 'disallow-mac' => ['mac'], 'kick' => ['mac'],
      'rename' => ['mac', 'name'], 'preset' => ['name', 'on'], 'mode' => ['mode']];
$a = $_REQUEST['a'] ?? '';
if (!isset($A[$a])) { http_response_code(400); exit('{"ok":false,"error":"Unknown action"}'); }
if (!in_array($a, ['overview', 'state', 'logs'], true) &&
    ($_SERVER['REQUEST_METHOD'] !== 'POST' || !hash_equals($tok, $_SERVER['HTTP_X_CSRF'] ?? ''))) {
    http_response_code(403); exit('{"ok":false,"error":"Invalid request token"}');
}
$args = [$a];
foreach ($A[$a] as $k) $args[] = (string)($_REQUEST[$k] ?? '');
echo json_encode(agent($args));
