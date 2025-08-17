<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Error de conexion"]);
    exit();
}

$sql = "
    SELECT d.id, d.captura_id, d.tipo, d.cantidad, c.fecha, t.nombre AS nombre_trampa, t.trampa_id
    FROM detecciones d
    JOIN capturas c ON d.captura_id = c.id
    LEFT JOIN trampas t ON c.trampa_id = t.trampa_id
    ORDER BY c.fecha DESC
";

$result = $conn->query($sql);

$lecturas = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $lecturas[] = $row;
    }
}

echo json_encode($lecturas);
$conn->close();
?>
