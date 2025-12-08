<?php
session_start();
if(!isset($_SESSION['username'])) { header("Location: login.php"); exit; }

$service = $_POST['service_name'];
$user = $_SESSION['username'];

$allowed = ['html','php','wordpress'];
if(!in_array($service, $allowed)) die("Service non autorisé.");

$serviceId = uniqid("srv_");

$db = new PDO('sqlite:services.db'); $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$db->exec("CREATE TABLE IF NOT EXISTS services (service_id TEXT PRIMARY KEY, username TEXT, type TEXT, ip TEXT, port TEXT, created_at TEXT)");
$stmt = $db->prepare("INSERT INTO services (service_id, username, type, created_at) VALUES (:s,:u,:t,datetime('now'))");
$stmt->execute([':s'=>$serviceId,':u'=>$user,':t'=>$service]);

header("Location: upload_service.php?service_id=$serviceId");
exit;
