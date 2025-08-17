<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

$host = "localhost";
$user = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Conexion fallida"]);
    exit;
}

$deteccionId = $_POST['id'] ?? 0;

// Obtener el captura_id de la deteccion
$sql = "SELECT captura_id FROM detecciones WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $deteccionId);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();

if (!$row) {
    echo json_encode(["error" => "Deteccion no encontrada"]);
    $conn->close();
    exit;
}

$capturaId = $row['captura_id'];

// Eliminar la deteccion
$stmt = $conn->prepare("DELETE FROM detecciones WHERE id = ?");
$stmt->bind_param("i", $deteccionId);
$stmt->execute();

// Verificar si ya no quedan detecciones para esa captura
$check = $conn->query("SELECT COUNT(*) as total FROM detecciones WHERE captura_id = $capturaId")->fetch_assoc();

if ($check['total'] == 0) {
    // Eliminar tambien la captura
    $conn->query("DELETE FROM capturas WHERE id = $capturaId");
}

echo json_encode(["success" => true]);
$conn->close();
?>
