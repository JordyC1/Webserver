<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Conexion a la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error de conexión"]);
    exit();
}

// Validar entrada
$id = $_POST['id'] ?? null;
$tipo = $_POST['tipo'] ?? null;
$cantidad = $_POST['cantidad'] ?? null;

if (!$id || !$tipo || !is_numeric($cantidad)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Datos incompletos o inválidos"]);
    exit();
}

// Actualizar deteccion
$stmt = $conn->prepare("UPDATE detecciones SET tipo = ?, cantidad = ? WHERE id = ?");
$stmt->bind_param("sii", $tipo, $cantidad, $id);
$success = $stmt->execute();
$stmt->close();

// Actualizar total_insectos de la captura asociada
$conn->query("
    UPDATE capturas 
    SET total_insectos = (
        SELECT COALESCE(SUM(cantidad), 0) 
        FROM detecciones 
        WHERE captura_id = (
            SELECT captura_id FROM detecciones WHERE id = $id
        )
    )
    WHERE id = (
        SELECT captura_id FROM detecciones WHERE id = $id
    )
");

echo json_encode(["success" => $success]);
$conn->close();
exit();
?>
