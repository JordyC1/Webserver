<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$user = "admin";
$password = "7008";
$database = "insectosDB";

// Conexion
$conn = new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Conexión fallida: " . $conn->connect_error]);
    exit;
}

// Consulta de trampas distintas
$sql = "SELECT DISTINCT trampa_id FROM capturas ORDER BY trampa_id ASC";
$result = $conn->query($sql);

$trampas = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $trampas[] = $row["trampa_id"];
    }
}

$conn->close();

// Respuesta
echo json_encode($trampas);
?>
