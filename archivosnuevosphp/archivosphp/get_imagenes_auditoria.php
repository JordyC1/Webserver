<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if (!isset($_GET['fecha'])) {
    echo json_encode(["error" => "Fecha no especificada"]);
    exit;
}

$fecha = $_GET['fecha']; // Formato esperado: YYYY-MM-DD
$baseDir = "/mnt/auditoria/" . $fecha;

if (!is_dir($baseDir)) {
    echo json_encode(["error" => "Directorio no encontrado"]);
    exit;
}

$resultado = [];

// Recorrer carpetas por hora (11, 12, 13...)
$horas = scandir($baseDir);
foreach ($horas as $hora) {
    $horaPath = $baseDir . "/" . $hora;

    if ($hora === "." || $hora === ".." || !is_dir($horaPath)) {
        continue;
    }

    $imagenes = [];
    $archivos = scandir($horaPath);

    foreach ($archivos as $archivo) {
        if (preg_match('/\.jpg$/i', $archivo)) {
            $imagenes[] = $archivo;
        }
    }

    if (!empty($imagenes)) {
        sort($imagenes); // Opcional: ordenar cronolgicamente
        $resultado[$hora] = $imagenes;
    }
}

echo json_encode($resultado);
