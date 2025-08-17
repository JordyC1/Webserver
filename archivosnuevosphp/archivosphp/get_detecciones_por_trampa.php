<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexion a la base de datos"]));
}

$periodo = $_GET['periodo'] ?? 'hoy';

switch ($periodo) {
    case 'semana':
        $inicio = date('Y-m-d', strtotime('-7 days'));
        break;
    case 'mes':
        $inicio = date('Y-m-d', strtotime('-30 days'));
        break;
    default:
        $inicio = date('Y-m-d');
        break;
}

$fin = date('Y-m-d');

$sql = "
SELECT 
    c.trampa_id,
    d.tipo AS tipo_insecto,
    SUM(d.cantidad) AS cantidad
FROM 
    detecciones d
JOIN 
    capturas c ON d.captura_id = c.id
WHERE 
    DATE(c.fecha) BETWEEN ? AND ?
GROUP BY 
    c.trampa_id, d.tipo
ORDER BY 
    c.trampa_id ASC, d.tipo ASC;
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $inicio, $fin);
$stmt->execute();
$resultado = $stmt->get_result();

$data = [];
while ($row = $resultado->fetch_assoc()) {
    $data[] = [
        'trampa_id' => $row['trampa_id'],
        'tipo_insecto' => $row['tipo_insecto'],
        'cantidad' => (int)$row['cantidad']
    ];
}

$stmt->close();
$conn->close();

echo json_encode($data);
?>
