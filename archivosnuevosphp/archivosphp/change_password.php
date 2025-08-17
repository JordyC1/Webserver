<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Conexin a la base de datos
$conexion = new mysqli("localhost", "admin", "7008", "insectosDB");
if ($conexion->connect_error) {
    die(json_encode(["status" => "error", "message" => "Error de conexin a la base de datos"]));
}

// Obtener datos del formulario
$email = $_POST["email"];
$actual = $_POST["actual"];
$nueva = $_POST["nueva"];

// Verificar contrasea actual
$stmt = $conexion->prepare("SELECT password FROM usuarios WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    $stmt->bind_result($hashed_password);
    $stmt->fetch();

    if (password_verify($actual, $hashed_password)) {
        $nueva_hash = password_hash($nueva, PASSWORD_DEFAULT);

        $update = $conexion->prepare("UPDATE usuarios SET password = ? WHERE email = ?");
        $update->bind_param("ss", $nueva_hash, $email);
        if ($update->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => "No se pudo actualizar"]);
        }
        $update->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Contrasea actual incorrecta"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Usuario no encontrado"]);
}

$stmt->close();
$conexion->close();
?>
