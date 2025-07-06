import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/chart_models.dart';
import 'alert_service.dart';

class ChartDataService {
  static const String baseUrl = "http://raspberrypi2.local";

  // 📊 Obtener datos de tendencia diaria de insectos
  static Future<ChartDataResponse<List<DailyTrendPoint>>> fetchDailyTrendData({int days = 14}) async {
  try {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    final response = await http
        .get(Uri.parse("$baseUrl/get_promedio_diario.php?inicio=$formattedStart&fin=$formattedEnd"))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    Map<String, int> datosPorFecha = {
      for (var item in jsonData)
        item['fecha']: int.tryParse(item['promedio'].toString()) ?? 0,
    };

    List<DailyTrendPoint> puntos = [];
    for (int i = 0; i < days; i++) {
      final fecha = startDate.add(Duration(days: i));
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
      final promedio = datosPorFecha[fechaKey] ?? 0;

      puntos.add(DailyTrendPoint(
        fecha: fecha,
        totalInsectos: promedio,
        fechaFormateada: DateFormat('dd/MM').format(fecha),
      ));
    }

    return ChartDataResponse.success(puntos);
  } catch (e) {
    return ChartDataResponse.error("Error al procesar datos de tendencia: $e");
  }
}



  // 🥧 Obtener distribución por tipo de insecto
  static Future<ChartDataResponse<List<InsectTypeData>>>
      fetchInsectTypeDistribution({int days = 30}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/get_lecturas.php"))
          .timeout(Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error(
            "Error al conectar con el servidor: ${response.statusCode}");
      }

      List<Map<String, dynamic>> lecturas =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      if (lecturas.isEmpty) {
        return ChartDataResponse.success(<InsectTypeData>[]);
      }

      // Filtrar últimos N días
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      // Agrupar por tipo
      Map<String, int> cantidadPorTipo = {};
      int totalGeneral = 0;

      for (var lectura in lecturas) {
        try {
          final fecha = DateTime.parse(lectura['fecha']);
          if (fecha.isAfter(startDate)) {
            final tipo = lectura['tipo'].toString();
            final cantidad = int.parse(lectura['cantidad'].toString());
            cantidadPorTipo[tipo] = (cantidadPorTipo[tipo] ?? 0) + cantidad;
            totalGeneral += cantidad;
          }
        } catch (e) {
          print("Error al procesar tipo: ${lectura['tipo']} - $e");
        }
      }

      if (totalGeneral == 0) {
        return ChartDataResponse.success(<InsectTypeData>[]);
      }

      // Crear lista de datos con colores asignados
      List<InsectTypeData> distribucion = [];
      List<String> colores = [
        'blue',
        'red',
        'green',
        'orange',
        'purple',
        'teal',
        'yellow'
      ];
      int colorIndex = 0;

      cantidadPorTipo.forEach((tipo, cantidad) {
        final porcentaje = (cantidad / totalGeneral) * 100;
        distribucion.add(InsectTypeData(
          tipo: tipo,
          cantidad: cantidad,
          porcentaje: porcentaje,
          color: colores[colorIndex % colores.length],
        ));
        colorIndex++;
      });

      // Ordenar por cantidad descendente
      distribucion.sort((a, b) => b.cantidad.compareTo(a.cantidad));

      return ChartDataResponse.success(distribucion);
    } catch (e) {
      return ChartDataResponse.error(
          "Error al procesar distribución por tipo: $e");
    }
  }

  // 📊 Obtener datos para barras apiladas por tipo y día
  static Future<ChartDataResponse<List<StackedBarData>>> fetchStackedBarData({int days = 7}) async {
  try {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    final response = await http
        .get(Uri.parse("$baseUrl/get_promedio_tipo_por_dia.php?inicio=$formattedStart&fin=$formattedEnd"))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    if (jsonData.isEmpty) {
      return ChartDataResponse.success(<StackedBarData>[]);
    }

    Map<String, Map<String, int>> datosPorFechaYTipo = {};

    for (var item in jsonData) {
      try {
        final fechaKey = item['fecha'];
        final tipo = item['tipo'].toString();
        final promedio = int.tryParse(item['promedio'].toString()) ?? 0;

        datosPorFechaYTipo.putIfAbsent(fechaKey, () => {})[tipo] = promedio;
      } catch (e) {
        print("Error al procesar datos promedio tipo/día: $e");
      }
    }

    List<StackedBarData> datosApilados = [];
    for (int i = 0; i < days; i++) {
      final fecha = startDate.add(Duration(days: i));
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
      final insectosPorTipo = datosPorFechaYTipo[fechaKey] ?? <String, int>{};
      final totalDia = insectosPorTipo.values.fold(0, (sum, cantidad) => sum + cantidad);

      datosApilados.add(StackedBarData(
        fecha: fecha,
        fechaFormateada: DateFormat('dd/MM').format(fecha),
        insectosPorTipo: insectosPorTipo,
        totalDia: totalDia,
      ));
    }

    return ChartDataResponse.success(datosApilados);
  } catch (e) {
    return ChartDataResponse.error("Error al procesar datos de barras apiladas: $e");
  }
}



  // ⚠️ Obtener datos de alertas por severidad
  static Future<ChartDataResponse<List<AlertSeverityData>>> fetchAlertsBySeverity() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/get_alertas_historial.php'));

    if (response.statusCode != 200) {
      return ChartDataResponse.error(
          "Error al conectar con el servidor: ${response.statusCode}");
    }

    List<Map<String, dynamic>> alertas =
        List<Map<String, dynamic>>.from(jsonDecode(response.body));

    // Contar solo alertas activas por severidad
    Map<String, int> cantidadPorSeveridad = {
      'alta': 0,
      'media': 0,
      'baja': 0
    };

    for (var alerta in alertas) {
      if (alerta['estado'] == 'activa') {
        final severidad = alerta['severidad'].toString().toLowerCase();
        if (cantidadPorSeveridad.containsKey(severidad)) {
          cantidadPorSeveridad[severidad] =
              cantidadPorSeveridad[severidad]! + 1;
        }
      }
    }

    // Convertir a lista de datos
    List<AlertSeverityData> datos = [];
    cantidadPorSeveridad.forEach((severidad, cantidad) {
      datos.add(AlertSeverityData(
        severidad: severidad,
        cantidad: cantidad,
        color: severidad, // El modelo debe interpretar este string
      ));
    });

    // Ordenar por severidad (alta > media > baja)
    datos.sort((a, b) {
      const orden = {'alta': 0, 'media': 1, 'baja': 2};
      return orden[a.severidad]!.compareTo(orden[b.severidad]!);
    });

    return ChartDataResponse.success(datos);
  } catch (e) {
    return ChartDataResponse.error(
        "Error al procesar alertas por severidad: $e");
  }
}


  static Future<ChartDataResponse<List<HourlyActivityData>>> fetchHourlyActivityData({int days = 14}) async {
  try {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    final response = await http
        .get(Uri.parse("$baseUrl/get_promedio_hora.php?inicio=$formattedStart&fin=$formattedEnd"))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    if (jsonData.isEmpty) {
      return ChartDataResponse.success(<HourlyActivityData>[]);
    }

    Map<int, Map<int, int>> actividadPorHoraDia = {};
    for (int dia = 0; dia < 7; dia++) {
      actividadPorHoraDia[dia] = {for (int h = 0; h < 24; h++) h: 0};
    }

    int maxPromedio = 0;

    for (var item in jsonData) {
      try {
        final fecha = DateTime.parse(item['fecha']);
        final diaSemana = (fecha.weekday - 1) % 7;
        final hora = fecha.hour;
        final promedio = int.tryParse(item['promedio'].toString()) ?? 0;

        actividadPorHoraDia[diaSemana]![hora] =
            actividadPorHoraDia[diaSemana]![hora]! + promedio;

        if (actividadPorHoraDia[diaSemana]![hora]! > maxPromedio) {
          maxPromedio = actividadPorHoraDia[diaSemana]![hora]!;
        }
      } catch (e) {
        print("Error al procesar item de hora: $e");
      }
    }

    List<HourlyActivityData> datosActividad = [];
    for (int dia = 0; dia < 7; dia++) {
      for (int hora = 0; hora < 24; hora++) {
        final cantidad = actividadPorHoraDia[dia]![hora]!;
        final intensidad = maxPromedio > 0 ? cantidad / maxPromedio : 0.0;

        datosActividad.add(HourlyActivityData(
          hora: hora,
          diaSemana: dia,
          cantidad: cantidad,
          intensidad: intensidad,
        ));
      }
    }

    return ChartDataResponse.success(datosActividad);
  } catch (e) {
    return ChartDataResponse.error("Error al procesar actividad por hora: $e");
  }
}



  // 📈 Obtener datos acumulativos semanales
static Future<ChartDataResponse<List<WeeklyCumulativeData>>> fetchWeeklyCumulativeData({int days = 7}) async {
  try {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    final response = await http
        .get(Uri.parse("$baseUrl/get_promedio_diario.php?inicio=$formattedStart&fin=$formattedEnd"))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
    }

    List<dynamic> jsonData = jsonDecode(response.body);

    Map<String, int> promedioPorFecha = {
      for (var item in jsonData)
        item['fecha']: int.tryParse(item['promedio'].toString()) ?? 0,
    };

    List<WeeklyCumulativeData> datosAcumulativos = [];
    int acumulado = 0;

    for (int i = 0; i < days; i++) {
      final fecha = startDate.add(Duration(days: i));
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
      final promedioDiario = promedioPorFecha[fechaKey] ?? 0;
      acumulado += promedioDiario;

      datosAcumulativos.add(WeeklyCumulativeData(
        fecha: fecha,
        cantidadDiaria: promedioDiario,
        cantidadAcumulada: acumulado,
        fechaFormateada: DateFormat('dd/MM').format(fecha),
      ));
    }

    return ChartDataResponse.success(datosAcumulativos);
  } catch (e) {
    return ChartDataResponse.error("Error al procesar datos acumulativos: $e");
  }
}


  // ⏱️ Calcular tiempo promedio entre detecciones
  static Future<ChartDataResponse<AverageTimeIndicator>>
      calculateAverageTimeBetweenDetections({int days = 7}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/get_lecturas.php"))
          .timeout(Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error(
            "Error al conectar con el servidor: ${response.statusCode}");
      }

      List<Map<String, dynamic>> lecturas =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      if (lecturas.isEmpty) {
        return ChartDataResponse.success(AverageTimeIndicator(
          tiempoPromedio: Duration(hours: 24),
          totalDetecciones: 0,
          estado: 'malo',
        ));
      }

      // Filtrar últimos N días y ordenar por fecha
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      List<DateTime> fechasDetecciones = [];
      for (var lectura in lecturas) {
        try {
          final fecha = DateTime.parse(lectura['fecha']);
          if (fecha.isAfter(startDate)) {
            fechasDetecciones.add(fecha);
          }
        } catch (e) {
          print("Error al procesar fecha para tiempo promedio: $e");
        }
      }

      if (fechasDetecciones.length < 2) {
        return ChartDataResponse.success(AverageTimeIndicator(
          tiempoPromedio: Duration(hours: 24),
          totalDetecciones: fechasDetecciones.length,
          estado: 'malo',
        ));
      }

      // Ordenar fechas
      fechasDetecciones.sort();

      // Calcular diferencias entre detecciones consecutivas
      List<Duration> intervalos = [];
      for (int i = 1; i < fechasDetecciones.length; i++) {
        final intervalo =
            fechasDetecciones[i].difference(fechasDetecciones[i - 1]);
        intervalos.add(intervalo);
      }

      // Calcular promedio
      final totalMinutos =
          intervalos.fold(0, (sum, intervalo) => sum + intervalo.inMinutes);
      final promedioMinutos = totalMinutos / intervalos.length;
      final tiempoPromedio = Duration(minutes: promedioMinutos.round());

      // Determinar estado basado en el tiempo promedio
      String estado;
      if (promedioMinutos <= 15) {
        estado = 'bueno'; // Cada 15 minutos o menos
      } else if (promedioMinutos <= 45) {
        estado = 'regular'; // Entre 15-45 minutos
      } else {
        estado = 'malo'; // Más de 45 minutos
      }

      return ChartDataResponse.success(AverageTimeIndicator(
        tiempoPromedio: tiempoPromedio,
        totalDetecciones: fechasDetecciones.length,
        estado: estado,
      ));
    } catch (e) {
      return ChartDataResponse.error("Error al calcular tiempo promedio: $e");
    }
  }

  // 🔄 Método para obtener todos los datos de una vez (opcional, para optimización)
  static Future<Map<String, dynamic>> fetchAllChartData() async {
    final results = await Future.wait([
      fetchDailyTrendData(),
      fetchInsectTypeDistribution(),
      fetchStackedBarData(),
      fetchAlertsBySeverity(),
      fetchHourlyActivityData(),
      fetchWeeklyCumulativeData(),
      calculateAverageTimeBetweenDetections(),
    ]);

    return {
      'dailyTrend': results[0],
      'insectDistribution': results[1],
      'stackedBar': results[2],
      'alertsSeverity': results[3],
      'hourlyActivity': results[4],
      'weeklyCumulative': results[5],
      'averageTime': results[6],
    };
  }
}