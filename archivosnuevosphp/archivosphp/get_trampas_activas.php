<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Conectar a la base de datos
$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");

if ($conexion->connect_error) {
    die("Error de conexin: " . $conexion->connect_error);
}

// Contar trampas activas en la ultima hora
$sql = "SELECT COUNT(*) AS trampas_activas FROM trampas WHERE status = 'active' AND timestamp >= NOW() - INTERVAL 45 MINUTE";
$resultado = $conexion->query($sql);

if ($resultado->num_rows > 0) {
    $fila = $resultado->fetch_assoc();
    echo json_encode(["trampas_activas" => $fila["trampas_activas"]]);
} else {
    echo json_encode(["trampas_activas" => 0]);
}

$conexion->close();
?>
