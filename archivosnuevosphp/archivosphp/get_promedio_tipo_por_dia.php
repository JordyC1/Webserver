<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexion a la base de datos"]));
}

$fechaInicio = $_GET['inicio'];
$fechaFin = $_GET['fin'];

$sql = "
SELECT 
    DATE(c.fecha) AS fecha,
    d.tipo,
    SUM(d.cantidad) AS total_insectos,
    COUNT(DISTINCT d.captura_id) AS total_capturas,
    ROUND(SUM(d.cantidad) / COUNT(DISTINCT d.captura_id)) AS promedio
FROM 
    detecciones d
JOIN 
    capturas c ON d.captura_id = c.id
WHERE 
    c.fecha BETWEEN ? AND ?
GROUP BY 
    DATE(c.fecha), d.tipo
ORDER BY 
    fecha ASC;
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $fechaInicio, $fechaFin);
$stmt->execute();
$resultado = $stmt->get_result();

$data = [];
while ($row = $resultado->fetch_assoc()) {
    $data[] = [
        'fecha' => $row['fecha'],
        'tipo' => $row['tipo'],
        'promedio' => (int)$row['promedio']
    ];
}

$conn->close();
echo json_encode($data);
?>
