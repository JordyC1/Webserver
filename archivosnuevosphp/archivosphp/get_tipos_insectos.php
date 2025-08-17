<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Conexion a la base de datos
$host = "localhost";
$user = "admin";
$password = "7008";
$database = "insectosDB";

$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Conexión fallida"]);
    exit();
}

// Consulta para obtener tipos unicos de insectos
$sql = "SELECT DISTINCT tipo FROM detecciones ORDER BY tipo ASC";
$result = $conn->query($sql);

$tipos = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $tipos[] = $row["tipo"];
    }
}

echo json_encode(["status" => "ok", "tipos" => $tipos]);

$conn->close();
?>
