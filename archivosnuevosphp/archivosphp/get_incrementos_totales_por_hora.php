<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Configuracion base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conectar
$conn = new mysqli($servername, $username, $password, $database);

// Validar conexion
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexión a la base de datos"]));
}

// Obtener parametros de tiempo
$inicio = $_GET['inicio'] ?? date('Y-m-d 00:00:00');
$fin = $_GET['fin'] ?? date('Y-m-d 23:59:59');

// Query agrupando por hora
$sql = "
    SELECT 
        HOUR(fecha) AS hora,
        SUM(incremento) AS total
    FROM historial_incrementos
    WHERE fecha BETWEEN ? AND ?
    GROUP BY hora
    ORDER BY hora ASC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $inicio, $fin);
$stmt->execute();
$result = $stmt->get_result();

// Construir respuesta
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = [
        "hora" => (int)$row["hora"],
        "total" => (int)$row["total"]
    ];
}

// Cerrar conexiones
$stmt->close();
$conn->close();

// Respuesta JSON
echo json_encode($data);
?>
