<?php
session_start();

if (isset($_SESSION['username'])) {
    echo "<h1>Bienvenue, ".$_SESSION['username']."</h1>";
    echo "<p><a href='logout.php'>Déconnexion</a></p>";
    exit;
}
?>

<h2>Connexion</h2>
<form method="post" action="auth.php">
    Nom d'utilisateur: <input type="text" name="username" required><br>
    Mot de passe: <input type="password" name="password" required><br>
    <input type="submit" value="Se connecter">
</form>

<p>Pas encore de compte ? <a href="register.php">Créer un compte</a></p>
