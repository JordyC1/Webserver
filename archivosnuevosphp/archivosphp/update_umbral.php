<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$tipo = $_POST['tipo'] ?? '';
$periodo = $_POST['periodo'] ?? '';
$umbral = $_POST['umbral'] ?? '';

$conn = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Conexion fallida"]);
    exit;
}

// Validar existencia
$stmt = $conn->prepare("SELECT id FROM configuracion_umbral WHERE tipo_insecto = ? AND periodo = ?");
$stmt->bind_param("ss", $tipo, $periodo);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    $stmt->close();
    // Si existe, actualizar
    $update = $conn->prepare("UPDATE configuracion_umbral SET umbral = ? WHERE tipo_insecto = ? AND periodo = ?");
    $update->bind_param("iss", $umbral, $tipo, $periodo);
    $update->execute();
    $update->close();
} else {
    $stmt->close();
    // Si no existe, insertar
    $insert = $conn->prepare("INSERT INTO configuracion_umbral (tipo_insecto, periodo, umbral) VALUES (?, ?, ?)");
    $insert->bind_param("ssi", $tipo, $periodo, $umbral);
    $insert->execute();
    $insert->close();
}

$conn->close();
echo json_encode(["success" => true, "message" => "Umbral actualizado"]);
