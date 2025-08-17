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
    echo json_encode(["error" => "Conexion fallida"]);
    exit;
}

$trampaId = $_GET['trampa_id'] ?? 0;
$sql = "SELECT COUNT(*) as total FROM capturas WHERE trampa_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $trampaId);
$stmt->execute();
$result = $stmt->get_result()->fetch_assoc();

echo json_encode(["total" => $result["total"]]);
$conn->close();
?>
