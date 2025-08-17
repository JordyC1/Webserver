<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

$data = json_decode(file_get_contents("php://input"), true);

// Conexion a la base de datos
$conn = new mysqli("localhost", "admin", "7008", "insectosDB");

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexión"]));
}

// Validar que se envie el ID
if (!isset($data['id'])) {
    echo json_encode(["success" => false, "message" => "ID no especificado"]);
    exit;
}

$id = $data['id'];

// Caso 1: solo cambiar el estado
if (isset($data['estado']) && count($data) == 2) {
    $estado = $data['estado'];
    $stmt = $conn->prepare("UPDATE configuracion_plagas SET estado = ? WHERE id = ?");
    $stmt->bind_param("si", $estado, $id);
    $success = $stmt->execute();
    $stmt->close();
    $conn->close();
    echo json_encode(["success" => $success]);
    exit;
}

// Caso 2: actualizar toda la configuracion
$camposRequeridos = ['tipo_insecto', 'umbral_promedio', 'intervalo_minutos', 'aplicar_por_trampa', 'estado', 'descripcion', 'tipo_alerta'];
$faltantes = array_diff($camposRequeridos, array_keys($data));

if (!empty($faltantes)) {
    echo json_encode(["success" => false, "message" => "Faltan campos: " . implode(", ", $faltantes)]);
    exit;
}

$stmt = $conn->prepare("UPDATE configuracion_plagas SET 
    tipo_insecto = ?, 
    umbral_promedio = ?, 
    intervalo_minutos = ?, 
    aplicar_por_trampa = ?, 
    estado = ?, 
    descripcion = ?, 
    tipo_alerta = ? 
    WHERE id = ?");

$stmt->bind_param("sdiisssi",
    $data['tipo_insecto'],
    $data['umbral_promedio'],
    $data['intervalo_minutos'],
    $data['aplicar_por_trampa'],
    $data['estado'],
    $data['descripcion'],
    $data['tipo_alerta'],
    $id
);

$success = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(["success" => $success]);
