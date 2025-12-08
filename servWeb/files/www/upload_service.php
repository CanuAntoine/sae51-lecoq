<?php
session_start();
if(!isset($_SESSION['username'])){
    header("Location: login.php");
    exit;
}

$serviceId = $_GET['service_id'];
?>

<h1>Uploader les fichiers du service</h1>

<form method="post" action="send_to_servheb.php" enctype="multipart/form-data">
    <input type="hidden" name="service_id" value="<?php echo $serviceId; ?>">
    <input type="file" name="files[]" multiple required>
    <button type="submit">Envoyer & Déployer</button>
</form>

<p><a href="index.php">Annuler</a></p>
