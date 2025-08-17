<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Configuración de la base de datos
$servername = "localhost";
$username = "admin";
$password = "7008";
$database = "insectosDB";

// Conectar a la base de datos
$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Error de conexión a la base de datos"]));
}

// Consulta SQL para obtener los usuarios
$sql = "SELECT id, email, 'Usuario' AS nombre, 'Usuario' AS rol FROM usuarios ORDER BY created_at DESC";

$result = $conn->query($sql);

$usuarios = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $usuarios[] = [
            "id" => $row["id"],
            "nombre" => $row["nombre"], // Placeholder porque la tabla no tiene un campo nombre
            "email" => $row["email"],
            "rol" => $row["rol"], // Placeholder porque la tabla no tiene un campo rol
        ];
    }
}

// Cerrar conexión
$conn->close();

// Devolver datos en formato JSON
echo json_encode($usuarios);
?>
