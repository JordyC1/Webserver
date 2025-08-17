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

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexin a la base de datos"]));
}

// Consulta SQL para obtener las lecturas
$sql = "SELECT 
            detecciones.id, 
            detecciones.captura_id, 
            detecciones.tipo, 
            detecciones.cantidad, 
            capturas.fecha 
        FROM detecciones 
        JOIN capturas ON detecciones.captura_id = capturas.id
        ORDER BY capturas.fecha DESC";

$result = $conn->query($sql);

$lecturas = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $lecturas[] = [
            "id" => $row["id"],
            "captura_id" => $row["captura_id"],
            "tipo" => $row["tipo"],
            "cantidad" => $row["cantidad"],
            "fecha" => $row["fecha"],
        ];
    }
}

// Cerrar conexin
$conn->close();

// Devolver datos en formato JSON
echo json_encode($lecturas);
?>
