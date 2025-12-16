<?php   
session_start();

require __DIR__ . '/vendor/autoload.php';
use OTPHP\TOTP;

$db = new PDO('sqlite:/opt/myapp/servWeb/files/www/users.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$db->exec("
CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    password TEXT,
    totp_secret TEXT
)
");

$username = $_POST['username'];
$password = $_POST['password'];

$stmt = $db->prepare("SELECT 1 FROM users WHERE username = :u");
$stmt->execute([':u' => $username]);
if ($stmt->fetch()) {
    die("Utilisateur déjà existant ! <a href='register.php'>Retour</a>");
}

$totp = TOTP::create();
$secret = $totp->getSecret();
$totp->setLabel($username);
$qr = $totp->getProvisioningUri();

$hash = password_hash($password, PASSWORD_DEFAULT);

$stmt = $db->prepare("
INSERT INTO users (username, password, totp_secret)
VALUES (:u, :p, :t)
");
$stmt->execute([
    ':u' => $username,
    ':p' => $hash,
    ':t' => $secret
]);
?>

<h2>Compte créé</h2>
<p>Scanne ce QR code dans Google Authenticator :</p>

<img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=<?php echo urlencode($qr); ?>">

<p><a href="index.php">Se connecter</a></p>
