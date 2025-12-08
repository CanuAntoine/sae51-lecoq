<?php
session_start();

// vérifier authentification
if (!isset($_SESSION['username'])) {
    die("Non autorisé.");
}

$user = $_SESSION['username'];
$service_id = $_POST['service_id'] ?? '';
if (!$service_id) die("service_id manquant");

// connexion DB
$db = new PDO('sqlite:services.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// récupérer info du service pour arrêter container Docker
$stmt = $db->prepare("SELECT * FROM services WHERE service_id = :s AND username = :u");
$stmt->execute([':s'=>$service_id, ':u'=>$user]);
$service = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$service) die("Service non trouvé");

// tenter d’arrêter et supprimer le container Docker
$container_name = "user_{$user}_{$service_id}";
exec("docker rm -f ".escapeshellarg($container_name)." 2>/dev/null");

// supprimer de la DB
$stmt = $db->prepare("DELETE FROM services WHERE service_id = :s AND username = :u");
$stmt->execute([':s'=>$service_id, ':u'=>$user]);

// rediriger vers dashboard
header("Location: index.php");
exit;
