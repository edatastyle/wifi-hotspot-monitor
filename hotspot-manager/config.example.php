<?php
/*
 * Developed by: Md. Saiful Islam
 * Email: e2getway@gmail.com
 * Website: https://edatastyle.com/
 */
// Copy to config.php. Create a hash:  php -r 'echo password_hash("your-password", PASSWORD_DEFAULT);'

return [
    'username'      => 'admin',
    'password_hash' => 'PASTE_HASH_HERE',
    'agent'         => __DIR__ . '/agent/hsagent.py',
];
