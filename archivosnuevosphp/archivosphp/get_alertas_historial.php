<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");
$conexion->set_charset("utf8");

if ($conexion->connect_error) {
    echo json_encode(["error" => "Error de conexion"]);
    exit();
}

$resultado = $conexion->query("SELECT id, tipo, mensaje, fecha, severidad, estado, captura_id, trampa_id, fecha_resolucion, notas_resolucion FROM alertas ORDER BY fecha DESC");
$alertas = [];

while ($fila = $resultado->fetch_assoc()) {
    $alertas[] = $fila;
}

echo json_encode($alertas);
?>
