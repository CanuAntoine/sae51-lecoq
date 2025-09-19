<?php
session_start();

$db = new PDO('sqlite:users.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$username = $_POST['username'];
$password = $_POST['password'];

// Vérifier si l'utilisateur existe
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
