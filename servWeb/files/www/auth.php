<?php
session_start();

require __DIR__ . '/vendor/autoload.php';
use OTPHP\TOTP;

$db = new PDO('sqlite:/opt/myapp/servWeb/files/www/users.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';
$code2fa  = $_POST['totp'] ?? '';

$stmt = $db->prepare("SELECT * FROM users WHERE username = :u");
$stmt->execute([':u' => $username]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user || !password_verify($password, $user['password'])) {
    die("Nom d'utilisateur ou mot de passe incorrect.");
}

$totp = TOTP::create($user['totp_secret']);
if (!$totp->verify($code2fa)) {
    die("Code 2FA invalide.");
}

$_SESSION['username'] = $username;
header("Location: index.php");
exit;
