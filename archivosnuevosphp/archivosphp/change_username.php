<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Conexi a la base de datos
$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conexion->connect_error) {
    die(json_encode(["status" => "error", "message" => "Error de conexin a la base de datos"]));
}

// Obtener datos del formulario
$email = $_POST["email"];
$nuevo_nombre = $_POST["nuevo_nombre"];

// Validar que el usuario exista
$verificar = $conexion->prepare("SELECT id FROM usuarios WHERE email = ?");
$verificar->bind_param("s", $email);
$verificar->execute();
$verificar->store_result();

if ($verificar->num_rows > 0) {
    // Actualizar nombre de usuario
    $stmt = $conexion->prepare("UPDATE usuarios SET nombre_usuario = ? WHERE email = ?");
    $stmt->bind_param("ss", $nuevo_nombre, $email);
    if ($stmt->execute()) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "No se pudo actualizar"]);
    }
    $stmt->close();
} else {
    echo json_encode(["status" => "error", "message" => "Usuario no encontrado"]);
}

$verificar->close();
$conexion->close();
?>
