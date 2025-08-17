<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$conn = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexion"]));
}

// Detectar si los datos vienen en JSON o en POST
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents("php://input");
    $data = json_decode($json, true);
}

if (
    !$data ||
    !isset($data['tipo_insecto']) ||
    !isset($data['umbral_promedio']) ||
    !isset($data['intervalo_minutos']) ||
    !isset($data['aplicar_por_trampa']) ||
    !isset($data['estado']) ||
    !isset($data['descripcion']) ||
    !isset($data['tipo_alerta'])
) {
    echo json_encode(["success" => false, "message" => "Datos incompletos"]);
    exit;
}

// Si no viene el campo 'notas', ponerlo como cadena vacia
if (!isset($data['notas'])) {
    $data['notas'] = "";
}

$sql = "INSERT INTO configuracion_plagas 
        (tipo_insecto, umbral_promedio, intervalo_minutos, aplicar_por_trampa, estado, descripcion, tipo_alerta, notas) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sdiissss", 
    $data['tipo_insecto'], 
    $data['umbral_promedio'], 
    $data['intervalo_minutos'], 
    $data['aplicar_por_trampa'], 
    $data['estado'], 
    $data['descripcion'], 
    $data['tipo_alerta'],
    $data['notas']
);

$success = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(["success" => $success]);
?>
