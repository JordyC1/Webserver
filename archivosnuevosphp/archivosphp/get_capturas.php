<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Conexin a la base de datos
$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conexion->connect_error) {
    die(json_encode(["error" => "Conexin fallida: " . $conexion->connect_error]));
}

// Obtener capturas
$queryCapturas = "SELECT id, fecha, trampa_id, total_insectos FROM capturas ORDER BY fecha DESC";
$resultCapturas = $conexion->query($queryCapturas);

$capturas = [];

while ($row = $resultCapturas->fetch_assoc()) {
    $capturaId = $row['id'];

    // Obtener detecciones relacionadas
    $queryDetecciones = "SELECT tipo, cantidad FROM detecciones WHERE captura_id = $capturaId";
    $resultDetecciones = $conexion->query($queryDetecciones);

    $insectos = [];
    while ($det = $resultDetecciones->fetch_assoc()) {
        $insectos[] = [
            "tipo" => $det["tipo"],
            "cantidad" => (int)$det["cantidad"]
        ];
    }

    $capturas[] = [
        "id" => (int)$row["id"],
        "fecha" => $row["fecha"],
        "trampa_id" => (int)$row["trampa_id"],
        "total_insectos" => (int)$row["total_insectos"],
        "insectos" => $insectos
    ];
}

echo json_encode($capturas);
$conexion->close();
?>
