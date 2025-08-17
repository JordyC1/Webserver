<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Verificar si viene el ID
if (!isset($_GET['captura_id'])) {
    echo json_encode(["status" => "error", "message" => "ID de captura no especificado"]);
    exit;
}

$capturaId = $_GET['captura_id'];

// Conexin a la base de datos (ajusta tus credenciales)
$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conexion->connect_error) {
    echo json_encode(["status" => "error", "message" => "Error de conexin"]);
    exit;
}

// Buscar la fecha de la captura
$stmt = $conexion->prepare("SELECT fecha FROM capturas WHERE id = ?");
$stmt->bind_param("i", $capturaId);
$stmt->execute();
$stmt->bind_result($fechaOriginal);

if (!$stmt->fetch()) {
    echo json_encode(["status" => "error", "message" => "Captura no encontrada"]);
    exit;
}
$stmt->close();
$conexion->close();

// Convertir a formato de imagen
$dt = DateTime::createFromFormat("Y-m-d H:i:s", $fechaOriginal);
$fecha = $dt->format("Y-m-d");
$hora = $dt->format("H");
$nombreImagen = $dt->format("Y-m-d_H-i-s") . ".jpg";

// Verificar si la imagen existe
$pathImagen = "/mnt/auditoria/$fecha/$hora/$nombreImagen";
if (!file_exists($pathImagen)) {
    echo json_encode(["status" => "not_found", "message" => "Imagen no encontrada"]);
    exit;
}

// Devolver URL
$url = "http://raspberrypi2.local/auditoria/auditoria/$fecha/$hora/$nombreImagen";
echo json_encode(["status" => "found", "url" => $url]);
