import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/chart_models.dart';
import 'indicator_cache_service.dart';

class ChartDataService {
  static const String baseUrl = "http://raspberrypi2.local";

  // 📊 Obtener datos de tendencia diaria de insectos
  static Future<ChartDataResponse<List<DailyTrendPoint>>> fetchDailyTrendData({int days = 7}) async {
  try {
    final now = DateTime.now();

  if (days == 1) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(startOfDay);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(endOfDay);

    final response = await http.get(
      Uri.parse("$baseUrl/get_incrementos_por_hora.php?inicio=$formattedStart&fin=$formattedEnd"),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al obtener datos por hora");
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    Map<int, int> datosPorHora = {};

    for (var item in jsonData) {
      final hora = int.tryParse(item['hora'].toString()) ?? 0;
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      datosPorHora[hora] = (datosPorHora[hora] ?? 0) + cantidad;
    }

    // Llenar todas las 24 horas
    List<DailyTrendPoint> datos = [];
    for (int h = 0; h < 24; h++) {
      datos.add(DailyTrendPoint(
        fecha: DateTime(now.year, now.month, now.day, h),
        totalInsectos: datosPorHora[h] ?? 0,
        fechaFormateada: "${h.toString().padLeft(2, '0')}:00",
      ));
    }

    return ChartDataResponse.success(datos);
  }

    // Si no es "Hoy", usar datos diarios
    final startDate = now.subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final response = await http.get(
      Uri.parse("$baseUrl/get_incrementos_por_dia.php?inicio=$formattedStart&fin=$formattedEnd"),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al obtener datos por día");
    }

    List<dynamic> jsonData = jsonDecode(response.body);
    Map<String, int> datosPorFecha = {};

    for (var item in jsonData) {
      final fecha = item['fecha'];
      final total = int.tryParse(item['cantidad'].toString()) ?? 0;
      datosPorFecha[fecha] = (datosPorFecha[fecha] ?? 0) + total;
    }

    List<DailyTrendPoint> datos = [];
    for (int i = 0; i < days; i++) {
      final fecha = startDate.add(Duration(days: i));
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
      final cantidad = datosPorFecha[fechaKey] ?? 0;

      datos.add(DailyTrendPoint(
        fecha: fecha,
        totalInsectos: cantidad,
        fechaFormateada: DateFormat('dd/MM').format(fecha),
      ));
    }

    return ChartDataResponse.success(datos);
  } catch (e) {
    return ChartDataResponse.error("Error al procesar datos de tendencia diaria: $e");
  }
}


static Future<void> actualizarUmbral(String tipo, String periodo, int umbral) async {
  final url = Uri.parse('$baseUrl/update_umbral.php');
  await http.post(url, body: {
    'tipo': tipo,
    'periodo': periodo,
    'umbral': umbral.toString(),
  });
}

  // 🥧 Obtener distribución por tipo de insecto
  static Future<ChartDataResponse<List<InsectTypeData>>>
      fetchInsectTypeDistribution({int days = 30}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/get_lecturas.php"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error(
            "Error al conectar con el servidor: ${response.statusCode}");
      }

      List<Map<String, dynamic>> lecturas =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      if (lecturas.isEmpty) {
        return ChartDataResponse.success(<InsectTypeData>[]);
      }

      // Filtrar últimos N días localmente
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
          // Error al procesar tipo: ${lectura['tipo']} - $e
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

  // 🥧 Obtener distribución por tipo de insecto para un día específico (filtrado local)
  static Future<ChartDataResponse<List<InsectTypeData>>>
      fetchInsectTypeDistributionByDay({DateTime? targetDate}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/get_lecturas.php"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error(
            "Error al conectar con el servidor: ${response.statusCode}");
      }

      List<Map<String, dynamic>> lecturas =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      if (lecturas.isEmpty) {
        return ChartDataResponse.success(<InsectTypeData>[]);
      }

      // Filtrar por día específico localmente
      final date = targetDate ?? DateTime.now();
      final targetDay = DateTime(date.year, date.month, date.day);
      final nextDay = targetDay.add(const Duration(days: 1));

      // Agrupar por tipo para el día específico
      Map<String, int> cantidadPorTipo = {};
      int totalGeneral = 0;

      for (var lectura in lecturas) {
        try {
          final fecha = DateTime.parse(lectura['fecha']);
          // Filtrar solo las lecturas del día específico
          if (fecha.isAfter(targetDay.subtract(const Duration(milliseconds: 1))) && 
              fecha.isBefore(nextDay)) {
            final tipo = lectura['tipo'].toString();
            final cantidad = int.parse(lectura['cantidad'].toString());
            cantidadPorTipo[tipo] = (cantidadPorTipo[tipo] ?? 0) + cantidad;
            totalGeneral += cantidad;
          }
        } catch (e) {
          // Error al procesar tipo: ${lectura['tipo']} - $e
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
          "Error al procesar distribución por tipo para día específico: $e");
    }
  }

  // 📊 Obtener datos para barras apiladas por tipo y día
static Future<ChartDataResponse<List<StackedBarData>>> fetchStackedBarData({int days = 7}) async {
  try {
    final now = DateTime.now();

    if (days == 1) {
      // 🔄 Por hora si es HOY
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(startOfDay);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(endOfDay);

      final response = await http.get(
        Uri.parse("$baseUrl/get_incrementos_por_hora.php?inicio=$formattedStart&fin=$formattedEnd"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error("Error al conectar con el servidor (hora): ${response.statusCode}");
      }

      List<dynamic> jsonData = jsonDecode(response.body);
      Map<int, Map<String, int>> datosPorHoraYTipo = {};

      for (var item in jsonData) {
        try {
          final hora = int.tryParse(item['hora'].toString()) ?? 0;
          final tipo = item['tipo'].toString();
          final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

          datosPorHoraYTipo.putIfAbsent(hora, () => {})[tipo] = cantidad;
        } catch (_) {}
      }

      List<StackedBarData> datosApilados = [];
      for (int h = 0; h < 24; h++) {
        final insectosPorTipo = datosPorHoraYTipo[h] ?? <String, int>{};
        final totalHora = insectosPorTipo.values.fold(0, (sum, cantidad) => sum + cantidad);

        datosApilados.add(StackedBarData(
          fecha: now,
          fechaFormateada: "${h.toString().padLeft(2, '0')}:00",
          insectosPorTipo: insectosPorTipo,
          totalDia: totalHora,
        ));
      }

      return ChartDataResponse.success(datosApilados);
    }

    // 🔄 Por día si es más de un día
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    final response = await http.get(
      Uri.parse("$baseUrl/get_incrementos_por_dia.php?inicio=$formattedStart&fin=$formattedEnd"),
    ).timeout(const Duration(seconds: 15));

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
        final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

        datosPorFechaYTipo.putIfAbsent(fechaKey, () => {})[tipo] = cantidad;
      } catch (_) {}
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
      final formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(now.year, now.month, now.day, 23, 59, 59));

      final response = await http
          .get(Uri.parse("$baseUrl/get_incrementos_por_hora_con_fecha.php?inicio=$formattedStart&fin=$formattedEnd"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
      }

      List<dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.isEmpty) {
        return ChartDataResponse.success(<HourlyActivityData>[]);
      }

      // Estructura para almacenar cantidad por día de la semana y hora
      Map<int, Map<int, int>> actividadPorHoraDia = {};
      for (int dia = 0; dia < 7; dia++) {
        actividadPorHoraDia[dia] = {for (int h = 0; h < 24; h++) h: 0};
      }

      int maxCantidad = 0;

      for (var item in jsonData) {
        try {
          final fechaStr = item['fecha'];
          final fecha = DateTime.parse(fechaStr);
          final diaSemana = (fecha.weekday - 1) % 7; // Lunes = 0, Domingo = 6
          final hora = int.tryParse(item['hora'].toString()) ?? 0;
          final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

          actividadPorHoraDia[diaSemana]![hora] =
              actividadPorHoraDia[diaSemana]![hora]! + cantidad;

          if (actividadPorHoraDia[diaSemana]![hora]! > maxCantidad) {
            maxCantidad = actividadPorHoraDia[diaSemana]![hora]!;
          }
        } catch (_) {
          // Ignorar errores individuales
        }
      }

      List<HourlyActivityData> datosActividad = [];
      for (int dia = 0; dia < 7; dia++) {
        for (int hora = 0; hora < 24; hora++) {
          final cantidad = actividadPorHoraDia[dia]![hora]!;
          final intensidad = maxCantidad > 0 ? cantidad / maxCantidad : 0.0;

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

    if (days == 1) {
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(startOfDay);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(endOfDay);

      final response = await http.get(
        Uri.parse("$baseUrl/get_incrementos_totales_por_hora.php?inicio=$formattedStart&fin=$formattedEnd"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error("Error al obtener datos por hora");
      }

      List<dynamic> jsonData = jsonDecode(response.body);
      Map<int, int> datosPorHora = {};

      for (var item in jsonData) {
        final hora = int.tryParse(item['hora'].toString()) ?? 0;
        final total = int.tryParse(item['total'].toString()) ?? 0;
        datosPorHora[hora] = total;
      }

      // Llenar 24 horas acumulando
      List<WeeklyCumulativeData> datos = [];
      int acumulado = 0;

      for (int h = 0; h < 24; h++) {
        final cantidad = datosPorHora[h] ?? 0;
        acumulado += cantidad;

        datos.add(WeeklyCumulativeData(
          fecha: now,
          cantidadDiaria: cantidad,
          cantidadAcumulada: acumulado,
          fechaFormateada: "${h.toString().padLeft(2, '0')}:00",
        ));
      }

      return ChartDataResponse.success(datos);
    }

    // Para más de un día
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    final response = await http.get(
      Uri.parse("$baseUrl/get_incrementos_por_dia.php?inicio=$formattedStart&fin=$formattedEnd"),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al obtener datos por día");
    }

    List<dynamic> jsonData = jsonDecode(response.body);

    // Agrupar por fecha y sumar los incrementos de todos los tipos
    Map<String, int> totalPorFecha = {};
    for (var item in jsonData) {
      final fecha = item['fecha'];
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

      totalPorFecha[fecha] = (totalPorFecha[fecha] ?? 0) + cantidad;
    }

    List<WeeklyCumulativeData> datos = [];
    int acumulado = 0;

    for (int i = 0; i < days; i++) {
      final fecha = startDate.add(Duration(days: i));
      final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
      final cantidad = totalPorFecha[fechaKey] ?? 0;
      acumulado += cantidad;

      datos.add(WeeklyCumulativeData(
        fecha: fecha,
        cantidadDiaria: cantidad,
        cantidadAcumulada: acumulado,
        fechaFormateada: DateFormat('dd/MM').format(fecha),
      ));
    }

    return ChartDataResponse.success(datos);
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error(
            "Error al conectar con el servidor: ${response.statusCode}");
      }

      List<Map<String, dynamic>> lecturas =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      if (lecturas.isEmpty) {
        return ChartDataResponse.success(AverageTimeIndicator(
          tiempoPromedio: const Duration(hours: 24),
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
          // Error al procesar fecha para tiempo promedio: $e
        }
      }

      if (fechasDetecciones.length < 2) {
        return ChartDataResponse.success(AverageTimeIndicator(
          tiempoPromedio: const Duration(hours: 24),
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

  // 📊 FASE 2: Nuevos métodos para indicadores de insectos
  
  // 🎯 Obtener resumen completo de indicadores para el dashboard (con cache y notificaciones)
static Future<ChartDataResponse<InsectDashboardSummary>> fetchInsectIndicators({
  int daysForComparison = 1,
  bool useCache = true,
}) async {
  try {
    if (useCache) {
      final cachedData = await IndicatorCacheService.getCachedIndicators();
      if (cachedData != null) {
        
        return ChartDataResponse.success(cachedData);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;
    DateTime endDate = today.add(const Duration(days: 1));

    if (daysForComparison == 1) {
      startDate = today;
    } else {
      startDate = today.subtract(Duration(days: daysForComparison - 1));
    }

    final previousStartDate = startDate.subtract(Duration(days: daysForComparison));
    final previousEndDate = startDate;

    final formatter = DateFormat('yyyy-MM-dd');
    final queryStart = formatter.format(previousStartDate);
    final queryEnd = formatter.format(endDate);

    // 1. Obtener incrementos reales
    final response = await http.get(Uri.parse(
      "$baseUrl/get_incrementos_por_dia.php?inicio=$queryStart&fin=$queryEnd",
    )).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return ChartDataResponse.error("Error al conectar con el servidor: ${response.statusCode}");
    }

    final List<dynamic> data = jsonDecode(response.body);

    // 2. Determinar período para los umbrales
    String periodo;
    switch (daysForComparison) {
      case 1:
        periodo = 'hoy';
        break;
      case 7:
        periodo = 'semana';
        break;
      case 30:
        periodo = 'mes';
        break;
      default:
        periodo = 'hoy';
    }

    // 3. Obtener umbrales personalizados para ese período
    final thresholdResponse = await http.get(Uri.parse(
      "$baseUrl/get_umbral_por_tipo.php?periodo=$periodo",
    )).timeout(const Duration(seconds: 10));

    if (thresholdResponse.statusCode != 200) {
      return ChartDataResponse.error("No se pudo obtener umbrales del servidor.");
    }

    final thresholdJson = jsonDecode(thresholdResponse.body);
    if (thresholdJson['success'] != true || thresholdJson['data'] == null) {
      return ChartDataResponse.error("Respuesta inválida al obtener umbrales.");
    }

    final Map<String, dynamic> rawThresholds = thresholdJson['data'];
    final Map<String, int> thresholds = rawThresholds.map((key, value) =>
        MapEntry(key.toString().toLowerCase(), int.tryParse(value.toString()) ?? 50));

    // 4. Obtener alertas activas
    final alertsResponse = await fetchAlertsBySeverity();
    int totalAlertas = 0;
    if (alertsResponse.success) {
      totalAlertas = alertsResponse.data!.fold(0, (sum, alert) => sum + alert.cantidad);
    }

    // 5. Agrupar los datos por tipo y período
    final Map<String, int> currentPeriodCounts = {};
    final Map<String, int> previousPeriodCounts = {};

    for (final item in data) {
      try {
        final fecha = DateTime.parse(item['fecha']);
        final tipoOriginal = item['tipo'].toString();
        final tipo = tipoOriginal.toLowerCase();
        final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

        if (fecha.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
            fecha.isBefore(endDate)) {
          currentPeriodCounts[tipo] = (currentPeriodCounts[tipo] ?? 0) + cantidad;
        }

        if (fecha.isAfter(previousStartDate.subtract(const Duration(milliseconds: 1))) &&
            fecha.isBefore(previousEndDate)) {
          previousPeriodCounts[tipo] = (previousPeriodCounts[tipo] ?? 0) + cantidad;
        }
      } catch (_) {}
    }

    // 6. Construir indicadores
    final allTypes = {...currentPeriodCounts.keys, ...previousPeriodCounts.keys};

    List<InsectIndicatorData> indicadores = [];
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFFF44336),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF009688),
      const Color(0xFFFFEB3B),
    ];

    int colorIndex = 0;
    for (String tipo in allTypes) {
      final cantidadActual = currentPeriodCounts[tipo] ?? 0;
      final cantidadAnterior = previousPeriodCounts[tipo] ?? 0;
      final umbral = thresholds[tipo] ?? 50;

      indicadores.add(InsectIndicatorData.fromBasicData(
        tipo: tipo[0].toUpperCase() + tipo.substring(1),
        cantidadHoy: cantidadActual,
        cantidadAyer: cantidadAnterior,
        color: colors[colorIndex % colors.length],
        umbral: umbral,
        tieneAlerta: cantidadActual >= umbral,
      ));

      colorIndex++;
    }

    final summary = InsectDashboardSummary.fromData(
      indicadores: indicadores,
      totalAlertas: totalAlertas,
    );

    if (useCache) {
      await IndicatorCacheService.cacheIndicators(summary);
    }
    return ChartDataResponse.success(summary);

  } catch (e) {
    return ChartDataResponse.error("Error al procesar indicadores: $e");
  }
}




  
  // 🐛 Obtener indicadores específicos por tipo de insecto
  static Future<ChartDataResponse<List<InsectIndicatorData>>> fetchInsectTypeIndicators({
    DateTime? targetDate,
  }) async {
    try {
      final date = targetDate ?? DateTime.now();
      final today = DateTime(date.year, date.month, date.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final nextDay = today.add(const Duration(days: 1));
      
      // Obtener todas las lecturas de una sola vez
      final allLecturasResponse = await http
          .get(Uri.parse("$baseUrl/get_lecturas.php"))
          .timeout(const Duration(seconds: 15));
          
      if (allLecturasResponse.statusCode != 200) {
        return ChartDataResponse.error("Error al conectar con el servidor: ${allLecturasResponse.statusCode}");
      }
      
      // Obtener umbrales
      final thresholdsResponse = await fetchInsectThresholds();
      final thresholds = thresholdsResponse.success ? thresholdsResponse.data! : <String, int>{};
      
      // Procesar todas las lecturas y filtrar localmente
      final allLecturas = List<Map<String, dynamic>>.from(jsonDecode(allLecturasResponse.body));
      
      Map<String, int> todayCounts = {};
      Map<String, int> yesterdayCounts = {};
      
      for (var lectura in allLecturas) {
        try {
          final fecha = DateTime.parse(lectura['fecha']);
          final tipo = lectura['tipo'].toString();
          final cantidad = int.tryParse(lectura['cantidad'].toString()) ?? 0;
          
          // Filtrar lecturas de hoy
          if (fecha.isAfter(today.subtract(const Duration(milliseconds: 1))) && 
              fecha.isBefore(nextDay)) {
            todayCounts[tipo] = (todayCounts[tipo] ?? 0) + cantidad;
          }
          
          // Filtrar lecturas de ayer
          if (fecha.isAfter(yesterday.subtract(const Duration(milliseconds: 1))) && 
              fecha.isBefore(today)) {
            yesterdayCounts[tipo] = (yesterdayCounts[tipo] ?? 0) + cantidad;
          }
        } catch (e) {
          // Error al procesar lectura: $e
        }
      }
      
      // Crear indicadores
      final allTypes = {...todayCounts.keys, ...yesterdayCounts.keys};
      List<InsectIndicatorData> indicadores = [];
      
      final colors = [
        const Color(0xFF2196F3), // blue
        const Color(0xFFF44336), // red
        const Color(0xFF4CAF50), // green
        const Color(0xFFFF9800), // orange
        const Color(0xFF9C27B0), // purple
        const Color(0xFF009688), // teal
        const Color(0xFFFFEB3B), // yellow
      ];
      
      int colorIndex = 0;
      for (String tipo in allTypes) {
        final cantidadHoy = todayCounts[tipo] ?? 0;
        final cantidadAyer = yesterdayCounts[tipo] ?? 0;
        final umbral = thresholds[tipo] ?? 50;
        
        indicadores.add(InsectIndicatorData.fromBasicData(
          tipo: tipo,
          cantidadHoy: cantidadHoy,
          cantidadAyer: cantidadAyer,
          color: colors[colorIndex % colors.length],
          umbral: umbral,
          tieneAlerta: cantidadHoy >= umbral,
        ));
        
        colorIndex++;
      }
      
      // Ordenar por cantidad descendente
      indicadores.sort((a, b) => b.cantidadHoy.compareTo(a.cantidadHoy));
      
      return ChartDataResponse.success(indicadores);
      
    } catch (e) {
      return ChartDataResponse.error("Error al procesar indicadores por tipo: $e");
    }
  }
  
  // ⚙️ Obtener umbrales de configuración para alertas
  static Future<ChartDataResponse<Map<String, int>>> fetchInsectThresholds() async {
  try {
    final response = await http
        .get(Uri.parse("$baseUrl/get_umbral_por_tipo.php"))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['success'] == true && json['data'] is Map) {
        final umbrales = Map<String, int>.from(json['data']);
        return ChartDataResponse.success(umbrales);
      } else {
        return ChartDataResponse.error("Respuesta inválida del servidor");
      }
    }
  } catch (e) {
    // Manejar error silenciosamente
  }

  // Valores por defecto
  const defaultThresholds = {
    'mosca': 50,
    'mosquito': 30,
    'abeja': 20,
    'avispa': 25,
    'polilla': 40,
    'escarabajo': 35,
    'chinche': 45,
  };

  return ChartDataResponse.success(defaultThresholds);
}

static Future<List<AlertaPlaga>> fetchAlertasPosiblesPlagas() async {
  final response = await http.get(
    Uri.parse('$baseUrl/get_alertas_historial.php'),
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => AlertaPlaga.fromJson(json))
        .where((a) => a.tipo == 'Posible plaga' && a.estado == 'activa')
        .toList();
  } else {
    throw Exception('Error al cargar alertas');
  }
}


  // 📈 Obtener datos de tendencia semanal por tipo de insecto
static Future<ChartDataResponse<List<WeeklyTrendPoint>>> fetchWeeklyTrendByType({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  try {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 6));
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final isToday = start.year == now.year &&
                    start.month == now.month &&
                    start.day == now.day &&
                    end.year == now.year &&
                    end.month == now.month &&
                    end.day == now.day;

    if (isToday) {
      print("✅ Entrando a endpoint por HORA para HOY");
      // --- HOY: usar endpoint por hora para mostrar 24 horas ---
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(startOfDay);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(endOfDay);

      final response = await http.get(
        Uri.parse('$baseUrl/get_incrementos_por_hora.php?inicio=$formattedStart&fin=$formattedEnd'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error("Error al obtener datos por hora");
      }

      final jsonData = jsonDecode(response.body);
      print("📊 Datos recibidos del API por hora: $jsonData");
      Map<int, Map<String, int>> datosPorHoraYTipo = {};

      for (var item in jsonData) {
        final hora = int.tryParse(item['hora'].toString()) ?? 0;
        final tipo = item['tipo'].toString();
        final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
        print("📊 Procesando: hora=$hora, tipo=$tipo, cantidad=$cantidad");

        datosPorHoraYTipo.putIfAbsent(hora, () => {})[tipo] = cantidad;
      }

      // Generar 24 puntos horarios
      List<WeeklyTrendPoint> puntos = [];
      for (int h = 0; h < 24; h++) {
        final fechaHora = DateTime(now.year, now.month, now.day, h);
        final fechaStr = DateFormat('yyyy-MM-dd HH:00').format(fechaHora);
        final cantidadesPorTipo = datosPorHoraYTipo[h] ?? <String, int>{};
        
        final punto = WeeklyTrendPoint(
          fecha: fechaStr,
          cantidadesPorTipo: cantidadesPorTipo,
          fechaDateTime: fechaHora,
        );
        print("📊 Hora ${h.toString().padLeft(2, '0')}:00: ${punto.cantidadesPorTipo} (total: ${punto.totalInsectos})");
        puntos.add(punto);
      }

      return ChartDataResponse.success(puntos);
    } else {
      // --- RANGO DE DÍAS: endpoint por día ---
      final formattedStart = DateFormat('yyyy-MM-dd').format(start);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

      final response = await http.get(
        Uri.parse('$baseUrl/get_incrementos_por_dia.php?inicio=$formattedStart&fin=$formattedEnd'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return ChartDataResponse.error("Error al obtener datos por día");
      }

      final jsonData = jsonDecode(response.body);
      Map<String, List<WeeklyTrendByTypeData>> datosPorFecha = {};

      for (var item in jsonData) {
        final fechaStr = item['fecha'];
        final tipo = item['tipo'].toString();
        final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;

        final fechaDT = DateTime.parse(fechaStr);
        datosPorFecha.putIfAbsent(fechaStr, () => []).add(
          WeeklyTrendByTypeData(
            fecha: fechaStr,
            tipoInsecto: tipo,
            cantidad: cantidad,
            fechaDateTime: fechaDT,
          ),
        );
      }

      // Generar lista continua de días
      List<WeeklyTrendPoint> puntos = [];
      final totalDays = end.difference(start).inDays + 1;
      for (int i = 0; i < totalDays; i++) {
        final fecha = start.add(Duration(days: i));
        final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
        final datos = datosPorFecha[fechaKey] ?? [];
        puntos.add(WeeklyTrendPoint.fromTrendDataList(fechaKey, datos));
      }

      return ChartDataResponse.success(puntos);
    }
  } catch (e) {
    return ChartDataResponse.error("Error al procesar datos: $e");
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
  
  // 🎯 Método extendido para obtener todos los datos incluyendo indicadores
  static Future<Map<String, dynamic>> fetchAllDashboardData() async {
    final results = await Future.wait([
      fetchDailyTrendData(),
      fetchInsectTypeDistribution(),
      fetchStackedBarData(),
      fetchAlertsBySeverity(),
      fetchHourlyActivityData(),
      fetchWeeklyCumulativeData(),
      calculateAverageTimeBetweenDetections(),
      fetchInsectIndicators(),
      fetchInsectTypeIndicators(),
    ]);

    return {
      'dailyTrend': results[0],
      'insectDistribution': results[1],
      'stackedBar': results[2],
      'alertsSeverity': results[3],
      'hourlyActivity': results[4],
      'weeklyCumulative': results[5],
      'averageTime': results[6],
      'insectIndicators': results[7],
      'typeIndicators': results[8],
    };
  }

  static Future<ChartDataResponse<List<StackedTrapData>>> fetchStackedTrapData({required int days}) async {
    try {
      final now = DateTime.now();
      DateTime start;
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      String endpoint;
      String formattedStart;
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

      if (days == 1) {
        start = DateTime(now.year, now.month, now.day);
        endpoint = 'get_incrementos_por_hora.php';
        formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
      } else {
        start = now.subtract(Duration(days: days - 1));
        start = DateTime(start.year, start.month, start.day);
        endpoint = 'get_incrementos_por_dia.php';
        formattedStart = DateFormat('yyyy-MM-dd').format(start);
      }

      // Fetch trap IDs
      final trapsResponse = await http.get(Uri.parse('$baseUrl/get_trampas.php')).timeout(const Duration(seconds: 10));
      if (trapsResponse.statusCode != 200) {
        return ChartDataResponse.error('Error al obtener trampas');
      }
      final trapsJson = jsonDecode(trapsResponse.body);
      List<String> trapIds = [];
      if (trapsJson is List) {
        trapIds = trapsJson.map((t) => t['trampa_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
      } else if (trapsJson['success'] && trapsJson['data'] is List) {
        trapIds = (trapsJson['data'] as List).map((t) => t['trampa_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
      }
      if (trapIds.isEmpty) {
        return ChartDataResponse.error('No se encontraron trampas');
      }

      // Fetch data for each trap
      List<StackedTrapData> data = [];
      for (String trapId in trapIds) {
        final url = Uri.parse('$baseUrl/$endpoint?inicio=$formattedStart&fin=$formattedEnd&trampa_id=$trapId');
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          Map<String, int> insectosPorTipo = {};
          for (var item in jsonData) {
            final tipo = item['tipo']?.toString() ?? 'desconocido';
            final cantidad = int.tryParse(item['cantidad']?.toString() ?? '0') ?? 0;
            insectosPorTipo[tipo] = (insectosPorTipo[tipo] ?? 0) + cantidad;
          }
          final total = insectosPorTipo.values.fold(0, (sum, v) => sum + v);
          data.add(StackedTrapData(
            trapId: trapId,
            insectosPorTipo: insectosPorTipo,
            totalTrap: total,
          ));
        }
      }

      data.sort((a, b) => int.parse(a.trapId).compareTo(int.parse(b.trapId)));
      return ChartDataResponse.success(data);
    } catch (e) {
      return ChartDataResponse.error('Error al cargar datos por trampa: $e');
    }
  }

  // Función para obtener datos agrupados por trampa con tipos de insectos
  static Future<ChartDataResponse<List<GroupedDetectionData>>> fetchGroupedDetectionData({required int days}) async {
    try {
      final now = DateTime.now();
      DateTime start;
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      String endpoint;
      String formattedStart;
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

      if (days == 1) {
        start = DateTime(now.year, now.month, now.day);
        endpoint = 'get_incrementos_por_hora_con_trampa.php';
        formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
      } else {
        start = now.subtract(Duration(days: days - 1));
        start = DateTime(start.year, start.month, start.day);
        endpoint = 'get_incrementos_por_dia_con_trampa.php';
        formattedStart = DateFormat('yyyy-MM-dd').format(start);
      }

      // Obtener todos los datos
      final url = Uri.parse('$baseUrl/$endpoint?inicio=$formattedStart&fin=$formattedEnd');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        return ChartDataResponse.error('Error al obtener datos: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData is! List) {
        return ChartDataResponse.error('Formato de datos inválido');
      }

      // Convertir a objetos DetectionByDateTrapData
      List<DetectionByDateTrapData> detections = jsonData
          .map((item) => DetectionByDateTrapData.fromJson(item))
          .toList();

      // Agrupar por trampa_id
      Map<String, Map<String, int>> groupedByTrap = {};
      Set<String> allTypes = {};

      for (var detection in detections) {
        groupedByTrap[detection.trampaId] ??= {};
        groupedByTrap[detection.trampaId]![detection.tipo] = 
            (groupedByTrap[detection.trampaId]![detection.tipo] ?? 0) + detection.cantidad;
        
        allTypes.add(detection.tipo);
      }

      // Crear lista de GroupedDetectionData
      List<GroupedDetectionData> result = [];
      List<String> sortedTraps = groupedByTrap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      List<String> sortedTypes = allTypes.toList()..sort();

      for (String trampaId in sortedTraps) {
        result.add(GroupedDetectionData(
          trampaId: trampaId,
          tiposPorCantidad: groupedByTrap[trampaId]!,
          tiposInsectos: sortedTypes,
        ));
      }

      return ChartDataResponse.success(result);
    } catch (e) {
      return ChartDataResponse.error('Error al cargar datos agrupados: $e');
    }
  }

}