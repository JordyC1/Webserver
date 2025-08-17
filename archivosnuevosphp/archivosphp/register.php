<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Recibir datos
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';

    // Verificar si estn vacos
    if (empty($email) || empty($password)) {
        echo json_encode(["error" => "Faltan datos"]);
        exit;
    }

    // Hashear la contrasea antes de guardarla
    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

    // Conectar a la base de datos
    $conn = new mysqli("localhost", "admin", "7008", "insectosDB");

    if ($conn->connect_error) {
        die(json_encode(["error" => "Error de conexin a la BD"]));
    }

    // Insertar usuario
    $stmt = $conn->prepare("INSERT INTO usuarios (email, password, created_at) VALUES (?, ?, NOW())");
    $stmt->bind_param("ss", $email, $hashedPassword);

    if ($stmt->execute()) {
        echo json_encode(["success" => "Usuario registrado"]);
    } else {
        echo json_encode(["error" => "Error al registrar usuario"]);
    }

    $stmt->close();
    $conn->close();
} else {
    echo json_encode(["error" => "Mtodo no permitido"]);
}
?>
