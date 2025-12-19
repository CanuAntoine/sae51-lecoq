<?php
session_start();

if (!isset($_SESSION['username'])) {
    die("Non autorisé.");
}

$service = $_POST['service_name'];
$user = $_SESSION['username'];

$allowed = ['html','php'];
if (!in_array($service, $allowed)) {
    die("Service non autorisé.");
}

$html_content = "<h1>Site de $user ($service)</h1>";

$uploadDir = __DIR__ . "/uploads/$user/";
if (is_dir($uploadDir)) {
    $files = scandir($uploadDir);
    foreach ($files as $file) {
        if ($file === '.' || $file === '..') continue;
        $html_content .= "<p><a href='uploads/$user/$file'>$file</a></p>";
    }
}

// ServHeb API call
$data = json_encode([
    "userId" => $user,
    "service" => $service,
    "html" => $html_content
]);

$ch = curl_init("http://localhost/api/create_service");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);

if ($result['success']) {
    echo "<h2>Service créé !</h2>";
    echo "Accès : <a href='http://{$result['ip']}:{$result['port']}' target='_blank'>{$result['ip']}:{$result['port']}</a>";
} else {
    echo "<h2>Erreur :</h2>";
    echo $result['erreur'] ?? 'Erreur inconnue';
}

echo "<p><a href='index.php'>Retour</a></p>";
?>
