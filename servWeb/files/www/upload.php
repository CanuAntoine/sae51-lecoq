<?php
session_start();
if(!isset($_SESSION['username'])) { header("Location: login.php"); exit; }
$serviceId = $_GET['service_id'] ?? '';
if(!$serviceId) die("service_id manquant");
?>
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Upload</title></head>
<body>
<h1>Upload pour le service <?php echo htmlspecialchars($serviceId); ?></h1>

<form method="post" action="send_to_servheb.php" enctype="multipart/form-data">
    <input type="hidden" name="service_id" value="<?php echo htmlspecialchars($serviceId); ?>">
    <label>Fichiers (html, php, css, js) :</label><br>
    <input type="file" name="files[]" multiple required><br><br>
    <button type="submit">Uploader & Déployer</button>
</form>

<p><a href="index.php">Retour</a></p>
</body>
</html>
