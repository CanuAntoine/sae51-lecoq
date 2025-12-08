<?php
session_start();
?>

<h2>Connexion</h2>
<form method="post" action="auth.php">
    Nom d'utilisateur: <input type="text" name="username" required><br>
    Mot de passe: <input type="password" name="password" required><br>
    <input type="submit" value="Se connecter">
</form>

<p><a href="register.php">Créer un compte</a></p>
