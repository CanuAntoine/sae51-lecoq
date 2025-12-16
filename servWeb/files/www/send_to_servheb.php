<?php
session_start();
if(!isset($_SESSION['username'])) { die("Non autorisé."); }

$user = $_SESSION['username'];
$serviceId = $_POST['service_id'] ?? '';
if(!$serviceId) die("service_id manquant");

$servHebUrl = "http://127.0.0.1/api/create_service";

$db = new PDO('sqlite:services.db'); 
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$stmt = $db->prepare("SELECT type FROM services WHERE service_id = :s");
$stmt->execute([':s'=>$serviceId]);
$type = $stmt->fetchColumn() ?: 'html';

$ch = curl_init();
$post = [
    'userId' => $user,
    'service' => $type,
    'serviceId' => $serviceId
];
foreach($_FILES['files']['tmp_name'] as $i => $tmp){
    $name = $_FILES['files']['name'][$i];
    $post["files[]"] = new CURLFile($tmp, mime_content_type($tmp), $name);
}

curl_setopt($ch, CURLOPT_URL, $servHebUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $post);

$response = curl_exec($ch);
if($response === false){
    $err = curl_error($ch);
    curl_close($ch);
    die("Erreur cURL: $err");
}
curl_close($ch);

$res = json_decode($response, true);
if(!$res || !$res['success']){
    $msg = $res['erreur'] ?? 'Erreur inconnue';
    die("ServHeb error: $msg");
}

$stmt = $db->prepare("UPDATE services SET ip = :ip, port = :port WHERE service_id = :s");
$stmt->execute([':ip'=>$res['ip'], ':port'=>$res['port'], ':s'=>$serviceId]);

echo "<h2>Service déployé</h2>";
echo "URL : <a href='http://{$res['ip']}:{$res['port']}' target='_blank'>{$res['ip']}:{$res['port']}</a><br>";
echo "<p><a href='index.php'>Retour</a></p>";
