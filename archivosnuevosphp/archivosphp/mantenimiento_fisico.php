<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

// Configuración de la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conexión
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error de conexión a la base de datos"]);
    exit();
}

// Método HTTP
$method = $_SERVER["REQUEST_METHOD"];

if ($method === "GET") {
    $sql = "SELECT m.id, m.trampa_id, m.tipo_mantenimiento, m.notas, m.fecha,
                   COALESCE(t.nombre, CONCAT('Trampa ID ', m.trampa_id)) AS nombre_trampa
            FROM mantenimiento_fisico m
            LEFT JOIN trampas t ON m.trampa_id = t.trampa_id
            ORDER BY m.fecha DESC";

    $result = $conn->query($sql);
    $mantenimientos = [];

    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $mantenimientos[] = $row;
        }
    }

    echo json_encode($mantenimientos);
    $conn->close();
    exit();
}

if ($method === "POST") {
    $action = $_POST["action"] ?? "";

    if ($action === "insertar") {
        $trampa_id = $_POST["trampa_id"] ?? null;
        $tipo = $_POST["tipo_mantenimiento"] ?? null;
        $notas = $_POST["notas"] ?? "";
        $fecha = $_POST["fecha"] ?? date("Y-m-d H:i:s");

        if (!$trampa_id || !$tipo) {
            http_response_code(400);
            echo json_encode(["success" => false, "message" => "Datos incompletos"]);
            exit();
        }

        $stmt = $conn->prepare("INSERT INTO mantenimiento_fisico (trampa_id, tipo_mantenimiento, notas, fecha) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isss", $trampa_id, $tipo, $notas, $fecha);
        $success = $stmt->execute();
        $stmt->close();

        echo json_encode(["success" => $success]);
        $conn->close();
        exit();
    }

    if ($action === "eliminar") {
        $id = $_POST["id"] ?? null;

        if (!$id || !is_numeric($id)) {
            http_response_code(400);
            echo json_encode(["success" => false, "message" => "ID inválido o no proporcionado"]);
            exit();
        }

        $stmt = $conn->prepare("DELETE FROM mantenimiento_fisico WHERE id = ?");
        $stmt->bind_param("i", $id);
        $success = $stmt->execute();
        $stmt->close();

        echo json_encode(["success" => $success]);
        $conn->close();
        exit();
    }

    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Acción no reconocida"]);
    exit();
}

http_response_code(405);
echo json_encode(["success" => false, "message" => "Método no permitido"]);
$conn->close();
exit();
?>
