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
    echo json_encode(["error" => "Conexion fallida"]);
    exit;
}

$nombre = $_POST['nombre'] ?? '';
$ubicacion = $_POST['ubicacion'] ?? '';
$status = 'inactive';
$timestamp = date('Y-m-d H:i:s');

$sql = "INSERT INTO trampas (nombre, ubicacion, status, timestamp) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ssss", $nombre, $ubicacion, $status, $timestamp);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    http_response_code(400);
    echo json_encode(["error" => "No se pudo insertar la trampa"]);
}

$stmt->close();
$conn->close();
?>
