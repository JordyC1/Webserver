<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Configuracion de la base de datos
$servername = "localhost";
$username   = "admin";
$password   = "7008";
$database   = "insectosDB";

// Conexion
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexion a la base de datos"]));
}

// Consulta agrupada por trampa y fecha
$sql = "
    SELECT 
        trampa_id,
        DATE_FORMAT(fecha, '%Y-%m-%d %H:%i:%s') AS fecha,
        tipo,
        incremento
    FROM historial_incrementos
    ORDER BY fecha DESC
";

$result = $conn->query($sql);

$agrupado = [];

// Agrupar por trampa_id + fecha
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $key = $row["trampa_id"] . "|" . $row["fecha"];

        if (!isset($agrupado[$key])) {
            $agrupado[$key] = [
                "trampa_id" => (int)$row["trampa_id"],
                "fecha"     => $row["fecha"],
                "insectos"  => []
            ];
        }

        $tipo = $row["tipo"];
        $incremento = (int)$row["incremento"];
        $agrupado[$key]["insectos"][] = "$tipo ($incremento)";
    }
}

// Formatear salida
$lecturas = [];
foreach ($agrupado as $item) {
    $lecturas[] = [
        "trampa_id"          => $item["trampa_id"],
        "fecha"              => $item["fecha"],
        "insectos_detectados"=> implode(", ", $item["insectos"])
    ];
}

// Cerrar conexion y retornar JSON
$conn->close();
echo json_encode($lecturas);
?>
