<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");
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

// Obtener parámetros de filtro
$estado = isset($_GET['estado']) ? trim($_GET['estado']) : 'activa';
$severidad = isset($_GET['severidad']) ? trim($_GET['severidad']) : null;
$limite = isset($_GET['limite']) ? intval($_GET['limite']) : 50;
$desde_fecha = isset($_GET['desde_fecha']) ? trim($_GET['desde_fecha']) : null;

// Validar estado
if (!in_array($estado, ['activa', 'resuelta', 'descartada'])) {
    $estado = 'activa';
}

// Validar severidad
if ($severidad && !in_array($severidad, ['alta', 'media', 'baja'])) {
    $severidad = null;
}

// Validar límite
if ($limite < 1 || $limite > 500) {
    $limite = 50;
}

try {
    // Construir consulta principal con JOINs para obtener información adicional
    $sql = "SELECT 
                a.id,
                a.tipo,
                a.mensaje,
                a.fecha,
                a.severidad,
                a.estado,
                a.captura_id,
                a.trampa_id,
                a.fecha_resolucion,
                a.notas_resolucion,
                c.fecha as fecha_captura,
                TIMESTAMPDIFF(MINUTE, a.fecha, NOW()) as minutos_desde_alerta,
                CASE 
                    WHEN a.captura_id IS NOT NULL THEN (
                        SELECT SUM(d.cantidad) 
                        FROM detecciones d 
                        WHERE d.captura_id = a.captura_id
                    )
                    ELSE NULL
                END as total_insectos
            FROM alertas a
            LEFT JOIN capturas c ON a.captura_id = c.id
            WHERE a.estado = ?";
    
    $params = [$estado];
    $types = "s";
    
    // Agregar filtro de severidad si se especifica
    if ($severidad) {
        $sql .= " AND a.severidad = ?";
        $params[] = $severidad;
        $types .= "s";
    }
    
    // Agregar filtro de fecha si se especifica
    if ($desde_fecha) {
        $sql .= " AND a.fecha >= ?";
        $params[] = $desde_fecha;
        $types .= "s";
    }
    
    $sql .= " ORDER BY a.fecha DESC LIMIT ?";
    $params[] = $limite;
    $types .= "i";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $alertas = [];
    while ($row = $result->fetch_assoc()) {
        $alertas[] = [
            "id" => intval($row["id"]),
            "tipo" => $row["tipo"],
            "mensaje" => $row["mensaje"],
            "fecha" => $row["fecha"],
            "severidad" => $row["severidad"],
            "estado" => $row["estado"],
            "captura_id" => $row["captura_id"] ? intval($row["captura_id"]) : null,
            "trampa_id" => $row["trampa_id"] ? intval($row["trampa_id"]) : null,
            "fecha_resolucion" => $row["fecha_resolucion"],
            "notas_resolucion" => $row["notas_resolucion"],
            "fecha_captura" => $row["fecha_captura"],
            "minutos_desde_alerta" => intval($row["minutos_desde_alerta"]),
            "total_insectos" => $row["total_insectos"] ? intval($row["total_insectos"]) : null
        ];
    }
    $stmt->close();
    
    // Obtener estadísticas de alertas activas
    $stats_sql = "SELECT 
                    severidad,
                    COUNT(*) as cantidad
                  FROM alertas 
                  WHERE estado = 'activa'
                  GROUP BY severidad";
    
    $stats_result = $conn->query($stats_sql);
    $estadisticas = [
        'alta' => 0,
        'media' => 0,
        'baja' => 0,
        'total' => 0
    ];
    
    if ($stats_result) {
        while ($row = $stats_result->fetch_assoc()) {
            $estadisticas[$row['severidad']] = intval($row['cantidad']);
            $estadisticas['total'] += intval($row['cantidad']);
        }
    }
    
    // Contar total de alertas encontradas (sin límite)
    $count_sql = "SELECT COUNT(*) as total FROM alertas WHERE estado = ?";
    $count_params = [$estado];
    $count_types = "s";
    
    if ($severidad) {
        $count_sql .= " AND severidad = ?";
        $count_params[] = $severidad;
        $count_types .= "s";
    }
    
    if ($desde_fecha) {
        $count_sql .= " AND fecha >= ?";
        $count_params[] = $desde_fecha;
        $count_types .= "s";
    }
    
    $count_stmt = $conn->prepare($count_sql);
    $count_stmt->bind_param($count_types, ...$count_params);
    $count_stmt->execute();
    $count_result = $count_stmt->get_result();
    $total_encontradas = $count_result->fetch_assoc()['total'];
    $count_stmt->close();
    
    // Respuesta exitosa
    echo json_encode([
        "success" => true,
        "alertas" => $alertas,
        "total_encontradas" => intval($total_encontradas),
        "total_mostradas" => count($alertas),
        "estadisticas" => $estadisticas,
        "filtros_aplicados" => [
            "estado" => $estado,
            "severidad" => $severidad,
            "limite" => $limite,
            "desde_fecha" => $desde_fecha
        ]
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error interno del servidor: " . $e->getMessage(),
        "alertas" => [],
        "total_encontradas" => 0,
        "estadisticas" => []
    ]);
}

$conn->close();
?> 