<?php
session_start();

// Création / ouverture de la base SQLite
$db = new PDO('sqlite:users.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Création table si elle n'existe pas
$db->exec("CREATE TABLE IF NOT EXISTS users (username TEXT PRIMARY KEY, password TEXT)");

$username = $_POST['username'];
$password = $_POST['password'];

// Vérifier si l'utilisateur existe déjà
$stmt = $db->prepare("SELECT * FROM users WHERE username = :username");
$stmt->execute([':username' => $username]);
if ($stmt->fetch()) {
    echo "Utilisateur déjà existant ! <a href='register.php'>Retour</a>";
    exit;
}

// Hacher le mot de passe et insérer dans la base
$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $db->prepare("INSERT INTO users (username, password) VALUES (:username, :password)");
$stmt->execute([':username' => $username, ':password' => $hash]);

echo "Compte créé avec succès ! <a href='index.php'>Se connecter</a>";
