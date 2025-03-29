import 'package:http/http.dart' as http;
import 'dart:convert';

class Alerta {
  final String tipo;
  final String mensaje;
  final String fecha;
  final String severidad;

  Alerta({
    required this.tipo,
    required this.mensaje,
    required this.fecha,
    required this.severidad,
  });
}

class AlertService {
  static Future<List<Alerta>> verificarAlertas() async {
    List<Alerta> alertas = [];

    try {
      final lecturasResp = await http.get(Uri.parse("http://raspberrypi2.local/get_lecturas.php"));

      if (lecturasResp.statusCode == 200) {
        List<Map<String, dynamic>> lecturas =
            List<Map<String, dynamic>>.from(jsonDecode(lecturasResp.body));

        if (lecturas.isEmpty) {
          alertas.add(Alerta(
            tipo: 'Sin datos',
            mensaje: 'No hay lecturas registradas en el sistema',
            fecha: DateTime.now().toString(),
            severidad: 'alta',
          ));
        } else {
          // Obtener la última captura
          int maxCapturaId = lecturas
              .map((l) => int.parse(l['captura_id'].toString()))
              .reduce((a, b) => a > b ? a : b);

          var lecturasUltimaCaptura = lecturas
              .where((l) => int.parse(l['captura_id'].toString()) == maxCapturaId)
              .toList();

          int totalInsectos = lecturasUltimaCaptura.fold(
            0,
            (sum, l) => sum + int.parse(l['cantidad'].toString()),
          );

          // Alerta si total es 0
          if (totalInsectos == 0) {
            alertas.add(Alerta(
              tipo: 'Captura sin detección',
              mensaje: 'La última captura (ID $maxCapturaId) no tiene insectos detectados.',
              fecha: DateTime.now().toString(),
              severidad: 'baja',
            ));
          }

          if (totalInsectos > 25) {
            alertas.add(Alerta(
              tipo: 'Alta cantidad de insectos en la trampa',
              mensaje: 'Se detectaron $totalInsectos insectos en la última captura se recomienda reemplazar la trampa',
              fecha: DateTime.now().toString(),
              severidad: 'alta',
            ));
          }

          // Última lectura > 45 minutos
          var ultimaLectura = lecturas.reduce((a, b) =>
              DateTime.parse(a['fecha']).isAfter(DateTime.parse(b['fecha'])) ? a : b);
          var diff = DateTime.now().difference(DateTime.parse(ultimaLectura['fecha']));
          if (diff.inMinutes > 45) {
            alertas.add(Alerta(
              tipo: 'Sin lecturas recientes',
              mensaje: 'No se han registrado lecturas en los últimos 45 minutos',
              fecha: DateTime.now().toString(),
              severidad: 'media',
            ));
          }
        }
      } else {
        alertas.add(Alerta(
          tipo: 'Error Base de Datos',
          mensaje: 'No se pudo conectar con la base de datos. Código: ${lecturasResp.statusCode}',
          fecha: DateTime.now().toString(),
          severidad: 'alta',
        ));
      }

      // Verificar trampas activas
      final trampasResp = await http.get(Uri.parse("http://raspberrypi2.local/get_trampas_activas.php"));

      if (trampasResp.statusCode == 200) {
        final data = jsonDecode(trampasResp.body);
        int trampasActivas = int.tryParse(data["trampas_activas"].toString()) ?? 0;

        if (trampasActivas == 0) {
          alertas.add(Alerta(
            tipo: 'Trampas inactivas',
            mensaje: 'No hay trampas activas registradas en los últimos 10 minutos',
            fecha: DateTime.now().toString(),
            severidad: 'alta',
          ));
        }
      } else {
        alertas.add(Alerta(
          tipo: 'Error Base de Datos',
          mensaje: 'No se pudo obtener la cantidad de trampas activas. Código: ${trampasResp.statusCode}',
          fecha: DateTime.now().toString(),
          severidad: 'alta',
        ));
      }

    } catch (e) {
      alertas.add(Alerta(
        tipo: 'Error',
        mensaje: 'Error al procesar alertas: $e',
        fecha: DateTime.now().toString(),
        severidad: 'alta',
      ));
    }

    // Ordenar por severidad (alta > media > baja)
    alertas.sort((a, b) {
      const orden = {'alta': 0, 'media': 1, 'baja': 2};
      return orden[a.severidad]!.compareTo(orden[b.severidad]!);
    });

    return alertas;
  }
}
