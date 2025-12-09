<?php
session_start();

$db = new PDO('sqlite:/opt/myapp/servWeb/files/www/users.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Check if the user table exists
$count = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
if ($count == 0) {
    http_response_code(400);
    echo "Aucun utilisateur enregistré. <a href='register.php'>Créer un compte</a>";
    exit;
}

$username = $_POST['username'];
$password = $_POST['password'];

// Check if the user exists
$stmt = $db->prepare("SELECT * FROM users WHERE username = :username");
$stmt->execute([':username' => $username]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if ($user && password_verify($password, $user['password'])) {
    $_SESSION['username'] = $username;
    header("Location: index.php");
    exit;
} else {
    echo "Nom d'utilisateur ou mot de passe incorrect. <a href='index.php'>Retour</a>";
}
?>
