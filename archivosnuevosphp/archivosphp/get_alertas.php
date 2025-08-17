<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Configuracin de la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conectar a la base de datos
$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexin a la base de datos"]));
}

// Obtener parmetros de consulta
$estado = isset($_GET['estado']) ? $_GET['estado'] : 'activa';
$severidad = isset($_GET['severidad']) ? $_GET['severidad'] : null;
$limite = isset($_GET['limite']) ? intval($_GET['limite']) : 50;
$desde_fecha = isset($_GET['desde_fecha']) ? $_GET['desde_fecha'] : null;

// Construir consulta SQL
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
            c.total_insectos,
            c.fecha as fecha_captura,
            t.status as estado_trampa,
            TIMESTAMPDIFF(MINUTE, a.fecha, NOW()) as minutos_desde_alerta
        FROM alertas a
        LEFT JOIN capturas c ON a.captura_id = c.id
        LEFT JOIN trampas t ON a.trampa_id = t.trampa_id
        WHERE 1=1";

$params = [];
$types = "";

// Filtrar por estado
if ($estado && in_array($estado, ['activa', 'resuelta', 'descartada'])) {
    $sql .= " AND a.estado = ?";
    $params[] = $estado;
    $types .= "s";
}

// Filtrar por severidad
if ($severidad && in_array($severidad, ['alta', 'media', 'baja'])) {
    $sql .= " AND a.severidad = ?";
    $params[] = $severidad;
    $types .= "s";
}

// Filtrar por fecha
if ($desde_fecha) {
    $sql .= " AND a.fecha >= ?";
    $params[] = $desde_fecha;
    $types .= "s";
}

// Ordenar por severidad y fecha
$sql .= " ORDER BY 
            CASE a.severidad 
                WHEN 'alta' THEN 1 
                WHEN 'media' THEN 2 
                WHEN 'baja' THEN 3 
            END,
            a.fecha DESC";

// Aplicar limite
if ($limite > 0) {
    $sql .= " LIMIT ?";
    $params[] = $limite;
    $types .= "i";
}

try {
    $stmt = $conn->prepare($sql);
    
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $alertas = [];
    
    if ($result->num_rows > 0) {
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
                "total_insectos" => $row["total_insectos"] ? intval($row["total_insectos"]) : null,
                "fecha_captura" => $row["fecha_captura"],
                "estado_trampa" => $row["estado_trampa"],
                "minutos_desde_alerta" => intval($row["minutos_desde_alerta"])
            ];
        }
    }
    
    // Obtener estadsticas adicionales
    $stats_sql = "SELECT 
                    severidad,
                    COUNT(*) as total
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
    
    while ($stat_row = $stats_result->fetch_assoc()) {
        $estadisticas[$stat_row['severidad']] = intval($stat_row['total']);
        $estadisticas['total'] += intval($stat_row['total']);
    }
    
    echo json_encode([
        "success" => true,
        "alertas" => $alertas,
        "total_encontradas" => count($alertas),
        "estadisticas" => $estadisticas,
        "filtros_aplicados" => [
            "estado" => $estado,
            "severidad" => $severidad,
            "limite" => $limite,
            "desde_fecha" => $desde_fecha
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Error al consultar alertas: " . $e->getMessage()
    ]);
}

// Cerrar conexin
$conn->close();
?>
