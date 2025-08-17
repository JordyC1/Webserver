<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Configuracin de la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conectar a la base de datos
$conn = new mysqli($servername, $username, $password, $database);

// Verificar conexin
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexin a la base de datos"]));
}

// Obtener parmetros GET
$inicio = isset($_GET['inicio']) ? $_GET['inicio'] : date('Y-m-d', strtotime('-6 days'));
$fin = isset($_GET['fin']) ? $_GET['fin'] : date('Y-m-d 23:59:59');

// Consulta SQL: sumar incrementos por da y tipo
$sql = "
    SELECT 
        DATE(fecha) AS fecha, 
        tipo, 
        SUM(incremento) AS cantidad
    FROM historial_incrementos
    WHERE fecha BETWEEN ? AND ?
    GROUP BY DATE(fecha), tipo
    ORDER BY fecha ASC
";

// Preparar y ejecutar la consulta
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $inicio, $fin);
$stmt->execute();
$result = $stmt->get_result();

// Arreglo para almacenar resultados
$datos = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $datos[] = [
            "fecha" => $row["fecha"],
            "tipo" => $row["tipo"],
            "cantidad" => (int)$row["cantidad"]
        ];
    }
}

// Cerrar conexin
$stmt->close();
$conn->close();

// Devolver respuesta en formato JSON
echo json_encode($datos);
?>
