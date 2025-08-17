<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$user = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Conexión fallida"]);
    exit;
}

$trampaId = $_POST['trampa_id'] ?? 0;
$nombre = $_POST['nombre'] ?? '';
$ubicacion = $_POST['ubicacion'] ?? '';

$sql = "UPDATE trampas SET nombre = ?, ubicacion = ? WHERE trampa_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ssi", $nombre, $ubicacion, $trampaId);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    http_response_code(400);
    echo json_encode(["error" => "No se pudo actualizar"]);
}

$stmt->close();
$conn->close();
?>
