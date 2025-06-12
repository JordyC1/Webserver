<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Manejar petición OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuración de la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conectar a la base de datos
$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexión a la base de datos"]));
}

// Verificar que sea una petición POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die(json_encode(["success" => false, "message" => "Método no permitido"]));
}

// Obtener datos JSON del cuerpo de la petición
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    die(json_encode(["success" => false, "message" => "Datos JSON inválidos"]));
}

// Validar campos requeridos
$tipo = isset($input['tipo']) ? trim($input['tipo']) : '';
$mensaje = isset($input['mensaje']) ? trim($input['mensaje']) : '';
$severidad = isset($input['severidad']) ? trim($input['severidad']) : '';

if (empty($tipo) || empty($mensaje) || empty($severidad)) {
    die(json_encode(["success" => false, "message" => "Campos requeridos: tipo, mensaje, severidad"]));
}

// Validar severidad
if (!in_array($severidad, ['alta', 'media', 'baja'])) {
    die(json_encode(["success" => false, "message" => "Severidad debe ser: alta, media o baja"]));
}

// Campos opcionales
$captura_id = isset($input['captura_id']) ? intval($input['captura_id']) : null;
$trampa_id = isset($input['trampa_id']) ? intval($input['trampa_id']) : null;

try {
    // Verificar si ya existe una alerta similar activa (evitar duplicados)
    $check_sql = "SELECT id FROM alertas 
                  WHERE tipo = ? 
                  AND mensaje = ? 
                  AND estado = 'activa' 
                  AND fecha >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)";
    
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("ss", $tipo, $mensaje);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows > 0) {
        // Ya existe una alerta similar reciente
        echo json_encode([
            "success" => true, 
            "message" => "Alerta similar ya existe",
            "duplicate" => true
        ]);
        $check_stmt->close();
        $conn->close();
        exit;
    }
    $check_stmt->close();

    // Insertar nueva alerta
    $sql = "INSERT INTO alertas (tipo, mensaje, severidad, captura_id, trampa_id, fecha, estado) 
            VALUES (?, ?, ?, ?, ?, NOW(), 'activa')";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssii", $tipo, $mensaje, $severidad, $captura_id, $trampa_id);
    
    if ($stmt->execute()) {
        $alerta_id = $conn->insert_id;
        
        echo json_encode([
            "success" => true,
            "message" => "Alerta registrada exitosamente",
            "alerta_id" => $alerta_id
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Error al insertar alerta: " . $stmt->error
        ]);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error interno del servidor: " . $e->getMessage()
    ]);
}

$conn->close();
?> 