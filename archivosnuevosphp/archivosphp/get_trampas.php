<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

$host = "localhost";
$user = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($host, $user, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Conexión fallida: " . $conn->connect_error]);
    exit;
}

$sql = "SELECT trampa_id, nombre, ubicacion, status, timestamp, trampa_adhesiva FROM trampas ORDER BY trampa_id ASC";
$result = $conn->query($sql);

$trampas = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $trampas[] = $row;
    }
}

$conn->close();

echo json_encode($trampas);
?>
