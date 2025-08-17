<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$conn = new mysqli("localhost", "admin", "7008", "insectosDB");

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexión"]));
}

$sql = "SELECT * FROM configuracion_plagas ORDER BY id DESC";
$result = $conn->query($sql);
$configuraciones = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $configuraciones[] = $row;
    }
}

$conn->close();
echo json_encode($configuraciones);
?>
