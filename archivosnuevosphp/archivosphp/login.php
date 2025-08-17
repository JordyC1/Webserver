<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Conectar a la base de datos
$conn = new mysqli("localhost", "admin", "7008", "insectosDB");

if ($conn->connect_error) {
    die(json_encode(["error" => "Error de conexin a la base de datos"]));
}

// Recibir datos del JSON
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data["email"]) || !isset($data["password"])) {
    echo json_encode(["error" => "Faltan datos"]);
    exit();
}

$email = $conn->real_escape_string($data["email"]);
$password = $data["password"];

// Buscar usuario en la base de datos
$sql = "SELECT id, email, password FROM usuarios WHERE email = '$email'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // Verificar la contrasea
    if (password_verify($password, $user["password"])) {
        echo json_encode(["success" => true, "message" => "Inicio de sesin exitoso"]);
    } else {
        echo json_encode(["error" => "Contrasea incorrecta"]);
    }
} else {
    echo json_encode(["error" => "Usuario no encontrado"]);
}

$conn->close();
?>
