<?php
session_start();

// redirect to login if not authenticated
if (!isset($_SESSION['username'])) {
    header("Location: login.php");
    exit;
}

$user = $_SESSION['username'];

// DB services
$db = new PDO('sqlite:services.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$db->exec("CREATE TABLE IF NOT EXISTS services (
    service_id TEXT PRIMARY KEY,
    username TEXT,
    type TEXT,
    ip TEXT,
    port TEXT,
    created_at TEXT
)");
?>

<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>CanuWebHost</title>
</head>
<body>
<h1>Bienvenue, <?php echo htmlspecialchars($user); ?></h1>
<a href="logout.php">Déconnexion</a>

<hr>

<h2>Créer un service</h2>
<p>Tu peux créer un service en mettant ton code html ou php dans la page suivante. Tu obtiendras un lien vers ton site par la suite</p>
<form method="post" action="create_service.php">
    <label>Type :
        <select name="service_name" required>
            <option value="html">Site HTML</option>
            <option value="php">Site PHP</option>
        </select>
    </label>
    <button type="submit">Créer (passe à l'upload)</button>
</form>

<hr>

<h2>Uploader / Déployer</h2>
<p>Si tu as déjà créé un service tu peux le voir en cliquand sur "Voir le site" ou le supprimer en cliquand sur "Supprimer".</p>

<ul>
<?php
$stmt = $db->prepare("SELECT * FROM services WHERE username = :u ORDER BY created_at DESC");
$stmt->execute([':u'=>$user]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
if(!$rows) echo "<li>Aucun service</li>";

foreach($rows as $r){
    echo "<li>[$r[type]] ".htmlspecialchars($r['service_id'])." - ";
    if($r['ip'] && $r['port']){
        $link = "http://{$r['ip']}:{$r['port']}";
        echo "<a href='$link' target='_blank'>Voir le site</a>";
    } else {
        echo "Non déployé";
    }

    // Delete Form
    echo " - <form style='display:inline' method='post' action='delete_service.php' onsubmit='return confirm(\"Confirmer la suppression ?\")'>
            <input type='hidden' name='service_id' value='".htmlspecialchars($r['service_id'])."'>
            <button type='submit'>Supprimer</button>
          </form>";

    echo "</li>";
}
?>
</ul>

</body>
</html>
