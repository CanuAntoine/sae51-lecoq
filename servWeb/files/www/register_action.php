<?php
session_start();

// Creation/opening of the SQLite database
$db = new PDO('sqlite:/opt/myapp/servWeb/files/www/users.db');  
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Create table if it does not exist
$db->exec("CREATE TABLE IF NOT EXISTS users (username TEXT PRIMARY KEY, password TEXT)");

$username = $_POST['username'];
$password = $_POST['password'];

// Check if the user already exists
$stmt = $db->prepare("SELECT * FROM users WHERE username = :username");
$stmt->execute([':username' => $username]);
if ($stmt->fetch()) {
    echo "Utilisateur déjà existant ! <a href='register.php'>Retour</a>";
    exit;
}

// Hash the password and insert it into the database
$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $db->prepare("INSERT INTO users (username, password) VALUES (:username, :password)");
$stmt->execute([':username' => $username, ':password' => $hash]);

echo "Compte créé avec succès ! <a href='index.php'>Se connecter</a>";
