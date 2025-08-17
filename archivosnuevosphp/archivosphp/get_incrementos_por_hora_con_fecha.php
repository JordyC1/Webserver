<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conexion a la base de datos
$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexion"]));
}

$inicio = $_GET['inicio'] ?? date('Y-m-d 00:00:00');
$fin = $_GET['fin'] ?? date('Y-m-d 23:59:59');

$sql = "
  SELECT 
    DATE(fecha) AS fecha,
    HOUR(fecha) AS hora,
    tipo,
    SUM(incremento) AS cantidad
  FROM historial_incrementos
  WHERE fecha BETWEEN ? AND ?
  GROUP BY DATE(fecha), HOUR(fecha), tipo
  ORDER BY fecha ASC, hora ASC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $inicio, $fin);
$stmt->execute();
$result = $stmt->get_result();

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = [
        "fecha" => $row["fecha"], // YYYY-MM-DD
        "hora" => (int)$row["hora"],
        "tipo" => $row["tipo"],
        "cantidad" => (int)$row["cantidad"]
    ];
}

$stmt->close();
$conn->close();

echo json_encode($data);
