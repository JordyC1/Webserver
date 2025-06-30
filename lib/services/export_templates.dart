// export_templates.dart
const String plantillaUsuarios = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Usuarios Exportados</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f9f9f9;
      padding: 20px;
    }
    h1 {
      color: #333;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      background: #fff;
    }
    th, td {
      border: 1px solid #ccc;
      padding: 10px;
      text-align: left;
    }
    th {
      background: #e8f0fe;
    }
  </style>
</head>
<body>
  <h1>Lista de Usuarios</h1>
  <table>
    <thead>
      <tr>
        <th>ID</th>
        <th>Nombre</th>
        <th>Correo</th>
        <th>Rol</th>
      </tr>
    </thead>
    <tbody>
      {{FILAS}}
    </tbody>
  </table>
</body>
</html>
''';

const String plantillaLecturas = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Lecturas Exportadas</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f9f9f9;
      padding: 20px;
    }
    h1 {
      color: #333;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      background: #fff;
    }
    th, td {
      border: 1px solid #ccc;
      padding: 10px;
      text-align: center;
    }
    th {
      background: #e6f7ec;
    }
  </style>
</head>
<body>
  <h1>Historial de Lecturas</h1>
  <table>
    <thead>
      <tr>
        <th>ID</th>
        <th>Trampa</th>
        <th>Tipo de Insecto</th>
        <th>Cantidad</th>
        <th>Fecha</th>
      </tr>
    </thead>
    <tbody>
      {{FILAS}}
    </tbody>
  </table>
</body>
</html>
''';

const String plantillaAlertas = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Alertas Exportadas</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f9f9f9;
      padding: 20px;
    }
    h1 {
      color: #333;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      background: #fff;
    }
    th, td {
      border: 1px solid #ccc;
      padding: 10px;
      text-align: left;
    }
    th {
      background: #fff3cd;
    }
  </style>
</head>
<body>
  <h1>Registro de Alertas</h1>
  <table>
    <thead>
      <tr>
        <th>Tipo</th>
        <th>Mensaje</th>
        <th>Fecha</th>
        <th>Severidad</th>
      </tr>
    </thead>
    <tbody>
      {{FILAS}}
    </tbody>
  </table>
</body>
</html>
''';

String generarPlantillaHTMLAlertas(List<dynamic> alertas) {
  if (alertas.isEmpty) {
    return "<html><body><p>No hay alertas registradas</p></body></html>";
  }

  String rows = alertas.map((a) {
    return '''
      <tr>
        <td>${a["id"]}</td>
        <td>${a["tipo"]}</td>
        <td>${a["mensaje"]}</td>
        <td>${a["fecha"]}</td>
        <td>${a["severidad"]}</td>
        <td>${a["estado"]}</td>
        <td>${a["captura_id"] ?? ''}</td>
        <td>${a["trampa_id"] ?? ''}</td>
        <td>${a["fecha_resolucion"] ?? ''}</td>
        <td>${a["notas_resolucion"] ?? ''}</td>
      </tr>
    ''';
  }).join();

  return '''
  <html>
  <head>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; }
      table { border-collapse: collapse; width: 100%; }
      th, td { border: 1px solid #ccc; padding: 8px; text-align: center; }
      th { background-color: #f2f2f2; }
    </style>
  </head>
  <body>
    <h2>Historial de Alertas</h2>
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Tipo</th>
          <th>Mensaje</th>
          <th>Fecha</th>
          <th>Severidad</th>
          <th>Estado</th>
          <th>ID Captura</th>
          <th>ID Trampa</th>
          <th>Fecha Resolución</th>
          <th>Notas de Resolución</th>
        </tr>
      </thead>
      <tbody>
        $rows
      </tbody>
    </table>
  </body>
  </html>
  ''';
}
