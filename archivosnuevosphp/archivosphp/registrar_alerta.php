<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuracin DB
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(["success" => false, "message" => "Error de conexin a la base de datos"]));
}

// Validar mtodo
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(["success" => false, "message" => "Mtodo no permitido"]));
}

// Leer datos JSON
$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    die(json_encode(["success" => false, "message" => "Datos JSON invlidos"]));
}

// Campos requeridos
$tipo = isset($input['tipo']) ? trim($input['tipo']) : '';
$mensaje = isset($input['mensaje']) ? trim($input['mensaje']) : '';
$severidad = isset($input['severidad']) ? trim($input['severidad']) : '';

// Validacin bsica
if (empty($tipo)  empty($mensaje)  empty($severidad)) {
    http_response_code(400);
    die(json_encode(["success" => false, "message" => "Campos requeridos: tipo, mensaje y severidad"]));
}

if (!in_array($severidad, ['alta', 'media', 'baja'])) {
    http_response_code(400);
    die(json_encode(["success" => false, "message" => "Severidad invlida. Usa: alta, media o baja."]));
}

// Campos opcionales
$captura_id = isset($input['captura_id']) && is_numeric($input['captura_id']) ? intval($input['captura_id']) : null;
$trampa_id = isset($input['trampa_id']) && is_numeric($input['trampa_id']) ? intval($input['trampa_id']) : null;

try {
    // Verificar duplicado reciente
    $check_sql = "SELECT id FROM alertas 
                  WHERE tipo = ? AND mensaje = ? AND estado = 'activa'
                  AND fecha >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("ss", $tipo, $mensaje);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows > 0) {
        echo json_encode([
            "success" => true,
            "message" => "Alerta similar ya registrada recientemente",
            "duplicate" => true
        ]);
        $check_stmt->close();
        $conn->close();
        exit;
    }
    $check_stmt->close();

    // Insertar alerta
    $insert_sql = "INSERT INTO alertas (tipo, mensaje, severidad, captura_id, trampa_id, fecha, estado)
                   VALUES (?, ?, ?, ?, ?, NOW(), 'activa')";
    $stmt = $conn->prepare($insert_sql);
    $stmt->bind_param("sssii", $tipo, $mensaje, $severidad, $captura_id, $trampa_id);
    
    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Alerta registrada correctamente",
            "alerta_id" => $stmt->insert_id
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Error al registrar la alerta: " . $stmt->error
        ]);
    }

    $stmt->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Error interno: " . $e->getMessage()
    ]);
}

$conn->close();
?>
