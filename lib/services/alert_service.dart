import 'package:http/http.dart' as http;
import 'dart:convert';

class Alerta {
  final int? id;
  final String tipo;
  final String mensaje;
  final String fecha;
  final String severidad;
  final String? estado;
  final int? capturaId;
  final int? trampaId;
  final String? fechaResolucion;
  final String? notasResolucion;
  final int? totalInsectos;
  final String? fechaCaptura;
  final String? estadoTrampa;
  final int? minutosDesdealerta;

  Alerta({
    this.id,
    required this.tipo,
    required this.mensaje,
    required this.fecha,
    required this.severidad,
    this.estado,
    this.capturaId,
    this.trampaId,
    this.fechaResolucion,
    this.notasResolucion,
    this.totalInsectos,
    this.fechaCaptura,
    this.estadoTrampa,
    this.minutosDesdealerta,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      tipo: json['tipo'],
      mensaje: json['mensaje'],
      fecha: json['fecha'],
      severidad: json['severidad'],
      estado: json['estado'],
      capturaId: json['captura_id'],
      trampaId: json['trampa_id'],
      fechaResolucion: json['fecha_resolucion'],
      notasResolucion: json['notas_resolucion'],
      totalInsectos: json['total_insectos'],
      fechaCaptura: json['fecha_captura'],
      estadoTrampa: json['estado_trampa'],
      minutosDesdealerta: json['minutos_desde_alerta'],
    );
  }
}

class AlertaResponse {
  final bool success;
  final List<Alerta> alertas;
  final int totalEncontradas;
  final Map<String, int> estadisticas;
  final String? error;

  AlertaResponse({
    required this.success,
    required this.alertas,
    required this.totalEncontradas,
    required this.estadisticas,
    this.error,
  });

  factory AlertaResponse.fromJson(Map<String, dynamic> json) {
    return AlertaResponse(
      success: json['success'] ?? false,
      alertas: json['alertas'] != null
          ? (json['alertas'] as List).map((a) => Alerta.fromJson(a)).toList()
          : [],
      totalEncontradas: json['total_encontradas'] ?? 0,
      estadisticas: json['estadisticas'] != null
          ? Map<String, int>.from(json['estadisticas'])
          : {},
      error: json['message'],
    );
  }
}

class AlertService {
  static const String baseUrl = "http://raspberrypi2.local";

  // 📝 Método para registrar alerta en la base de datos
  static Future<bool> _registrarAlerta({
    required String tipo,
    required String mensaje,
    required String severidad,
    int? capturaId,
    int? trampaId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/registrar_alerta.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tipo': tipo,
              'mensaje': mensaje,
              'severidad': severidad,
              'captura_id': capturaId,
              'trampa_id': trampaId,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error al registrar alerta: $e");
      return false;
    }
  }

  // 📋 Método para obtener alertas desde la base de datos
  static Future<AlertaResponse> obtenerAlertas({
    String estado = 'activa',
    String? severidad,
    int limite = 50,
    String? desdeFecha,
  }) async {
    try {
      final queryParams = <String, String>{
        'estado': estado,
        'limite': limite.toString(),
      };

      if (severidad != null) queryParams['severidad'] = severidad;
      if (desdeFecha != null) queryParams['desde_fecha'] = desdeFecha;

      final uri = Uri.parse("$baseUrl/get_alertas.php").replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlertaResponse.fromJson(data);
      } else {
        return AlertaResponse(
          success: false,
          alertas: [],
          totalEncontradas: 0,
          estadisticas: {},
          error: "Error del servidor: ${response.statusCode}",
        );
      }
    } catch (e) {
      return AlertaResponse(
        success: false,
        alertas: [],
        totalEncontradas: 0,
        estadisticas: {},
        error: "Error de conexión: $e",
      );
    }
  }

  // ✅ Método para resolver una alerta
  static Future<bool> resolverAlerta({
    required int alertaId,
    String estado = 'resuelta',
    String? notas,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/resolver_alerta.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'alerta_id': alertaId,
              'estado': estado,
              'notas': notas,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error al resolver alerta: $e");
      return false;
    }
  }

  // 🔍 Método principal para verificar y generar alertas (mantiene compatibilidad)
  static Future<List<Alerta>> verificarAlertas() async {
    List<Alerta> alertas = [];

    try {
      final lecturasResp =
          await http.get(Uri.parse("$baseUrl/get_lecturas.php"));

      if (lecturasResp.statusCode == 200) {
        List<Map<String, dynamic>> lecturas =
            List<Map<String, dynamic>>.from(jsonDecode(lecturasResp.body));

        if (lecturas.isEmpty) {
          final alerta = Alerta(
            tipo: 'Sin datos',
            mensaje: 'No hay lecturas registradas en el sistema',
            fecha: DateTime.now().toString(),
            severidad: 'alta',
          );
          alertas.add(alerta);

          // 📝 Registrar en BD
          await _registrarAlerta(
            tipo: alerta.tipo,
            mensaje: alerta.mensaje,
            severidad: alerta.severidad,
          );
        } else {
          // Obtener la última captura
          int maxCapturaId = lecturas
              .map((l) => int.parse(l['captura_id'].toString()))
              .reduce((a, b) => a > b ? a : b);

          var lecturasUltimaCaptura = lecturas
              .where(
                  (l) => int.parse(l['captura_id'].toString()) == maxCapturaId)
              .toList();

          int totalInsectos = lecturasUltimaCaptura.fold(
            0,
            (sum, l) => sum + int.parse(l['cantidad'].toString()),
          );

          // Alerta si total es 0
          if (totalInsectos == 0) {
            final alerta = Alerta(
              tipo: 'Captura sin detección',
              mensaje:
                  'La última captura (ID $maxCapturaId) no tiene insectos detectados.',
              fecha: DateTime.now().toString(),
              severidad: 'baja',
              capturaId: maxCapturaId,
            );
            alertas.add(alerta);

            // 📝 Registrar en BD
            await _registrarAlerta(
              tipo: alerta.tipo,
              mensaje: alerta.mensaje,
              severidad: alerta.severidad,
              capturaId: maxCapturaId,
            );
          }

          // Alerta por alta cantidad
          if (totalInsectos > 25) {
            final alerta = Alerta(
              tipo: 'Alta cantidad de insectos en la trampa',
              mensaje:
                  'Se detectaron $totalInsectos insectos en la última captura se recomienda reemplazar la trampa',
              fecha: DateTime.now().toString(),
              severidad: 'alta',
              capturaId: maxCapturaId,
            );
            alertas.add(alerta);

            // 📝 Registrar en BD
            await _registrarAlerta(
              tipo: alerta.tipo,
              mensaje: alerta.mensaje,
              severidad: alerta.severidad,
              capturaId: maxCapturaId,
            );
          }

          // Última lectura > 45 minutos
          var ultimaLectura = lecturas.reduce((a, b) =>
              DateTime.parse(a['fecha']).isAfter(DateTime.parse(b['fecha']))
                  ? a
                  : b);
          var diff =
              DateTime.now().difference(DateTime.parse(ultimaLectura['fecha']));
          if (diff.inMinutes > 45) {
            final alerta = Alerta(
              tipo: 'Sin lecturas recientes',
              mensaje:
                  'No se han registrado lecturas en los últimos 45 minutos',
              fecha: DateTime.now().toString(),
              severidad: 'media',
            );
            alertas.add(alerta);

            // 📝 Registrar en BD
            await _registrarAlerta(
              tipo: alerta.tipo,
              mensaje: alerta.mensaje,
              severidad: alerta.severidad,
            );
          }
        }
      } else {
        final alerta = Alerta(
          tipo: 'Error Base de Datos',
          mensaje:
              'No se pudo conectar con la base de datos. Código: ${lecturasResp.statusCode}',
          fecha: DateTime.now().toString(),
          severidad: 'alta',
        );
        alertas.add(alerta);

        // 📝 Registrar en BD
        await _registrarAlerta(
          tipo: alerta.tipo,
          mensaje: alerta.mensaje,
          severidad: alerta.severidad,
        );
      }

      // Verificar trampas activas
      final trampasResp =
          await http.get(Uri.parse("$baseUrl/get_trampas_activas.php"));

      if (trampasResp.statusCode == 200) {
        final data = jsonDecode(trampasResp.body);
        int trampasActivas =
            int.tryParse(data["trampas_activas"].toString()) ?? 0;

        if (trampasActivas == 0) {
          final alerta = Alerta(
            tipo: 'Trampas inactivas',
            mensaje:
                'No hay trampas activas registradas en los últimos 10 minutos',
            fecha: DateTime.now().toString(),
            severidad: 'alta',
          );
          alertas.add(alerta);

          // 📝 Registrar en BD
          await _registrarAlerta(
            tipo: alerta.tipo,
            mensaje: alerta.mensaje,
            severidad: alerta.severidad,
          );
        }
      } else {
        final alerta = Alerta(
          tipo: 'Error Base de Datos',
          mensaje:
              'No se pudo obtener la cantidad de trampas activas. Código: ${trampasResp.statusCode}',
          fecha: DateTime.now().toString(),
          severidad: 'alta',
        );
        alertas.add(alerta);

        // 📝 Registrar en BD
        await _registrarAlerta(
          tipo: alerta.tipo,
          mensaje: alerta.mensaje,
          severidad: alerta.severidad,
        );
      }
    } catch (e) {
      final alerta = Alerta(
        tipo: 'Error',
        mensaje: 'Error al procesar alertas: $e',
        fecha: DateTime.now().toString(),
        severidad: 'alta',
      );
      alertas.add(alerta);

      // 📝 Registrar en BD
      await _registrarAlerta(
        tipo: alerta.tipo,
        mensaje: alerta.mensaje,
        severidad: alerta.severidad,
      );
    }

    // Ordenar por severidad (alta > media > baja)
    alertas.sort((a, b) {
      const orden = {'alta': 0, 'media': 1, 'baja': 2};
      return orden[a.severidad]!.compareTo(orden[b.severidad]!);
    });

    return alertas;
  }
}
