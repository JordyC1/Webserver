<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["id"])) {
    $id = $_POST["id"];

    $conn = new mysqli("localhost", "admin", "7008", "insectosDB");
    if ($conn->connect_error) {
        echo json_encode(["success" => false, "message" => "Error de conexin"]);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM usuarios WHERE id = ?");
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Usuario eliminado"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error al eliminar usuario"]);
    }

    $stmt->close();
    $conn->close();
} else {
    echo json_encode(["success" => false, "message" => "Datos incompletos"]);
}
?>
