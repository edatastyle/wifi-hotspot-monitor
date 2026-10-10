<?php
/*
 * Developed by: Md. Saiful Islam
 * Email: e2getway@gmail.com
 * Website: https://edatastyle.com/
 */

declare(strict_types=1);
session_set_cookie_params(['httponly' => true, 'samesite' => 'Strict']);
session_start();
$CFG = require __DIR__ . '/config.php';
function cfg(string $k) { global $CFG; return $CFG[$k]; }
function authed(): bool { return !empty($_SESSION['u']); }
function csrf(): string { return $_SESSION['csrf'] ??= bin2hex(random_bytes(16)); }
/** Runs the root agent through a sudo rule that allows only this script. Args are never shell-parsed. */
function agent(array $args): array {
    $p = proc_open(array_merge(function_exists('posix_geteuid') && posix_geteuid() === 0 ? [] : ['sudo', '-n'], ['/usr/bin/python3', cfg('agent')], $args),
                   [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes);
    if (!is_resource($p)) return ['ok' => false, 'error' => 'Could not start the agent'];
    $out = stream_get_contents($pipes[1]); $err = stream_get_contents($pipes[2]); proc_close($p);
    $j = json_decode($out, true);
    return is_array($j) ? $j : ['ok' => false, 'error' => trim($err) ?: 'Agent returned no data (check the sudoers rule)'];
}
