<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: text/plain; charset=UTF-8");

// Configuración base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conexión
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo "Error de conexión";
    exit;
}

// Obtener fecha de hoy y hace 6 días
$hoy = date('Y-m-d');
$inicio = date('Y-m-d', strtotime('-6 days'));

// Consulta: suma de incrementos por día
$sql = "
    SELECT DATE(fecha) AS dia, SUM(incremento) AS total
    FROM historial_incrementos
    WHERE fecha BETWEEN ? AND ?
    GROUP BY dia
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $inicio, $hoy);
$stmt->execute();
$result = $stmt->get_result();

$valores = array_fill(0, 7, 0); // [0, 0, 0, 0, 0, 0, 0]
$mapa = [];

while ($row = $result->fetch_assoc()) {
    $dia = $row['dia'];
    $total = (int)$row['total'];
    $mapa[$dia] = $total;
}

// Rellenar arreglo con días en orden cronológico
for ($i = 0; $i < 7; $i++) {
    $fecha = date('Y-m-d', strtotime("-" . (6 - $i) . " days"));
    $valores[$i] = $mapa[$fecha] ?? 0;
}

echo implode(",", $valores); // Formato: 5,3,0,7,2,0,9

$stmt->close();
$conn->close();
?>
