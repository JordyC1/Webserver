<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

$data = json_decode(file_get_contents("php://input"), true);
$conn = new mysqli("localhost", "admin", "7008", "insectosDB");

$sql = "DELETE FROM configuracion_plagas WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $data['id']);

$success = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(["success" => $success]);
?>
