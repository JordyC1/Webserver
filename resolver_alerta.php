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
$alerta_id = isset($input['alerta_id']) ? intval($input['alerta_id']) : 0;
$estado = isset($input['estado']) ? trim($input['estado']) : '';
$notas = isset($input['notas']) ? trim($input['notas']) : null;

if ($alerta_id <= 0) {
    die(json_encode(["success" => false, "message" => "ID de alerta inválido"]));
}

if (empty($estado)) {
    die(json_encode(["success" => false, "message" => "Estado es requerido"]));
}

// Validar estado
if (!in_array($estado, ['resuelta', 'descartada', 'activa'])) {
    die(json_encode(["success" => false, "message" => "Estado debe ser: resuelta, descartada o activa"]));
}

try {
    // Verificar que la alerta existe
    $check_sql = "SELECT id, estado FROM alertas WHERE id = ?";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("i", $alerta_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows === 0) {
        echo json_encode([
            "success" => false,
            "message" => "Alerta no encontrada"
        ]);
        $check_stmt->close();
        $conn->close();
        exit;
    }
    
    $alerta_actual = $check_result->fetch_assoc();
    $check_stmt->close();
    
    // Actualizar la alerta
    if ($estado === 'activa') {
        // Si se reactiva, limpiar fecha y notas de resolución
        $sql = "UPDATE alertas 
                SET estado = ?, 
                    fecha_resolucion = NULL, 
                    notas_resolucion = NULL 
                WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("si", $estado, $alerta_id);
    } else {
        // Si se resuelve o descarta, establecer fecha y notas
        $sql = "UPDATE alertas 
                SET estado = ?, 
                    fecha_resolucion = NOW(), 
                    notas_resolucion = ? 
                WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssi", $estado, $notas, $alerta_id);
    }
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            echo json_encode([
                "success" => true,
                "message" => "Alerta actualizada exitosamente",
                "alerta_id" => $alerta_id,
                "estado_anterior" => $alerta_actual['estado'],
                "estado_nuevo" => $estado
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "No se realizaron cambios en la alerta"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Error al actualizar alerta: " . $stmt->error
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