<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$mysqli = new mysqli("localhost", "admin", "7008", "insectosDB");

if ($mysqli->connect_error) {
    echo json_encode(["success" => false, "message" => "Error de conexión"]);
    exit;
}

$periodo = $_GET['periodo'] ?? 'hoy'; // puede ser: hoy, semana, mes

$stmt = $mysqli->prepare("SELECT tipo_insecto, umbral FROM configuracion_umbral WHERE periodo = ?");
$stmt->bind_param("s", $periodo);
$stmt->execute();
$result = $stmt->get_result();

$umbrales = [];

while ($row = $result->fetch_assoc()) {
    $umbrales[strtolower($row['tipo_insecto'])] = (int)$row['umbral'];
}

$stmt->close();
$mysqli->close();

echo json_encode(["success" => true, "data" => $umbrales]);
