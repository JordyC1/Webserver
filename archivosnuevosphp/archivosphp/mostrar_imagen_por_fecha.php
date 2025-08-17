<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Verificar si se proporcionó la fecha
if (!isset($_GET['fecha'])) {
    echo json_encode(["status" => "error", "message" => "Fecha no especificada"]);
    exit;
}

$fechaOriginal = $_GET['fecha'];

// Convertir la fecha a formato esperado
$dt = DateTime::createFromFormat("Y-m-d H:i:s", $fechaOriginal);
if (!$dt) {
    echo json_encode(["status" => "error", "message" => "Formato de fecha inválido"]);
    exit;
}

$fecha = $dt->format("Y-m-d");
$hora = $dt->format("H");
$nombreImagen = $dt->format("Y-m-d_H-i-s") . ".jpg";

// Ruta completa al archivo
$pathImagen = "/mnt/auditoria/$fecha/$hora/$nombreImagen";

// Verificar si la imagen existe
if (!file_exists($pathImagen)) {
    echo json_encode(["status" => "not_found", "message" => "Imagen no encontrada"]);
    exit;
}

// Construir la URL pública
$url = "http://raspberrypi2.local/auditoria/auditoria/$fecha/$hora/$nombreImagen";
echo json_encode(["status" => "found", "url" => $url]);
