import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// 📊 Modelo para puntos de tendencia diaria
class DailyTrendPoint {
  final DateTime fecha;
  final int totalInsectos;
  final String fechaFormateada;

  DailyTrendPoint({
    required this.fecha,
    required this.totalInsectos,
    required this.fechaFormateada,
  });

  // Convertir a FlSpot para fl_chart
  FlSpot toFlSpot(int index) {
    return FlSpot(index.toDouble(), totalInsectos.toDouble());
  }

  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) {
    return DailyTrendPoint(
      fecha: DateTime.parse(json['fecha']),
      totalInsectos: int.parse(json['total'].toString()),
      fechaFormateada: json['fechaFormateada'] ?? '',
    );
  }
}

// 🥧 Modelo para distribución por tipo de insecto
class InsectTypeData {
  final String tipo;
  final int cantidad;
  final double porcentaje;
  final String color;

  InsectTypeData({
    required this.tipo,
    required this.cantidad,
    required this.porcentaje,
    required this.color,
  });

  // 🎯 Métodos agregados para indicadores (Fase 1)
  
  /// Calcula el nivel de alerta basado en un umbral
  AlertLevel calculateAlertLevel(int threshold) {
    if (cantidad >= threshold * 1.5) {
      return AlertLevel(
        nivel: 'critical',
        color: const Color(0xFFF44336), // Rojo
        icon: Icons.warning,
      );
    } else if (cantidad >= threshold) {
      return AlertLevel(
        nivel: 'warning',
        color: const Color(0xFFFF9800), // Naranja
        icon: Icons.info,
      );
    } else {
      return AlertLevel(
        nivel: 'normal',
        color: const Color(0xFF4CAF50), // Verde
        icon: Icons.check_circle,
      );
    }
  }

  /// Calcula el porcentaje de cambio respecto a un valor anterior
  double calculateTrendPercentage(int previousValue) {
    if (previousValue == 0) {
      return cantidad > 0 ? 100.0 : 0.0;
    }
    return ((cantidad - previousValue) / previousValue) * 100;
  }

  /// Obtiene el icono de tendencia basado en el cambio porcentual
  IconData getTrendIcon() {
    // Necesitamos un valor anterior para calcular la tendencia
    // Este método será usado en conjunto con calculateTrendPercentage
    return Icons.trending_flat; // Por defecto, estable
  }

  /// Obtiene el icono de tendencia basado en un porcentaje de cambio específico
  static IconData getTrendIconFromPercentage(double percentage) {
    if (percentage > 5.0) {
      return Icons.trending_up;
    } else if (percentage < -5.0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  // Convertir a PieChartSectionData para fl_chart
  PieChartSectionData toPieChartSection(bool isSelected) {
    return PieChartSectionData(
      color: _getColorFromString(color),
      value: cantidad.toDouble(),
      title: isSelected
          ? '$tipo\n${porcentaje.toStringAsFixed(1)}%'
          : '${porcentaje.toStringAsFixed(1)}%',
      radius: isSelected ? 60 : 50,
      titleStyle: TextStyle(
        fontSize: isSelected ? 14 : 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFEEEEEE),
      ),
    );
  }

  Color _getColorFromString(String colorStr) {
    // Convertir string de color a Color
    switch (colorStr.toLowerCase()) {
      case 'blue':
        return const Color(0xFF2796F4);
      case 'red':
        return const Color(0xFFF44336);
      case 'green':
        return const Color(0xFF4CAF50);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'teal':
        return const Color(0xFF009688);
      case 'yellow':
        return const Color(0xFFFFEB3B);
      default:
        return const Color(0xFF2796F4);
    }
  }
}

// 🎯 Modelo para nivel de alerta (Fase 1)
class AlertLevel {
  final String nivel; // 'normal', 'warning', 'critical'
  final Color color;
  final IconData icon;

  AlertLevel({
    required this.nivel,
    required this.color,
    required this.icon,
  });

  /// Obtiene el texto capitalizado del nivel
  String get nivelCapitalizado {
    switch (nivel) {
      case 'normal':
        return 'Normal';
      case 'warning':
        return 'Advertencia';
      case 'critical':
        return 'Crítico';
      default:
        return nivel[0].toUpperCase() + nivel.substring(1);
    }
  }

  /// Verifica si el nivel es crítico
  bool get isCritical => nivel == 'critical';

  /// Verifica si el nivel es de advertencia
  bool get isWarning => nivel == 'warning';

  /// Verifica si el nivel es normal
  bool get isNormal => nivel == 'normal';
}

// 🎯 Modelo para datos de indicador de insecto (Fase 1)
class InsectIndicatorData {
  final String tipoInsecto;
  final int cantidadHoy;
  final int cantidadAyer;
  final double porcentajeCambio;
  final String tendencia; // 'up', 'down', 'stable'
  final Color colorTipo;
  final AlertLevel nivelAlerta;
  final int umbralAlerta;
  final bool tieneAlertaActiva;

  InsectIndicatorData({
    required this.tipoInsecto,
    required this.cantidadHoy,
    required this.cantidadAyer,
    required this.porcentajeCambio,
    required this.tendencia,
    required this.colorTipo,
    required this.nivelAlerta,
    required this.umbralAlerta,
    required this.tieneAlertaActiva,
  });

  /// Obtiene el icono de tendencia basado en la tendencia
  IconData get iconoTendencia {
    switch (tendencia) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  /// Obtiene el color de la tendencia
  Color get colorTendencia {
    switch (tendencia) {
      case 'up':
        return const Color(0xFFF44336); // Verde
      case 'down':
        return const Color(0xFF4CAF50); // Rojo
      case 'stable':
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  /// Obtiene el texto formateado del porcentaje de cambio
  String get porcentajeCambioFormateado {
    final signo = porcentajeCambio >= 0 ? '+' : '';
    return '$signo${porcentajeCambio.toStringAsFixed(1)}%';
  }

  /// Verifica si hay un cambio significativo (mayor a 5%)
  bool get tieneCambioSignificativo => porcentajeCambio.abs() > 5.0;

  /// Factory constructor para crear desde datos básicos
  factory InsectIndicatorData.fromBasicData({
    required String tipo,
    required int cantidadHoy,
    required int cantidadAyer,
    required Color color,
    required int umbral,
    bool tieneAlerta = false,
  }) {
    final porcentaje = cantidadAyer == 0 
        ? (cantidadHoy > 0 ? 100.0 : 0.0)
        : ((cantidadHoy - cantidadAyer) / cantidadAyer) * 100;
    
    String tendencia;
    if (porcentaje > 5.0) {
      tendencia = 'up';
    } else if (porcentaje < -5.0) {
      tendencia = 'down';
    } else {
      tendencia = 'stable';
    }

    AlertLevel nivel;
    if (cantidadHoy >= umbral * 1.5) {
      nivel = AlertLevel(
        nivel: 'critical',
        color: const Color(0xFFF44336),
        icon: Icons.warning,
      );
    } else if (cantidadHoy >= umbral) {
      nivel = AlertLevel(
        nivel: 'warning',
        color: const Color(0xFFFF9800),
        icon: Icons.info,
      );
    } else {
      nivel = AlertLevel(
        nivel: 'normal',
        color: const Color(0xFF4CAF50),
        icon: Icons.check_circle,
      );
    }

    return InsectIndicatorData(
      tipoInsecto: tipo,
      cantidadHoy: cantidadHoy,
      cantidadAyer: cantidadAyer,
      porcentajeCambio: porcentaje,
      tendencia: tendencia,
      colorTipo: color,
      nivelAlerta: nivel,
      umbralAlerta: umbral,
      tieneAlertaActiva: tieneAlerta,
    );
  }

  /// Convierte el objeto a JSON para serialización
  Map<String, dynamic> toJson() {
    return {
      'tipoInsecto': tipoInsecto,
      'cantidadHoy': cantidadHoy,
      'cantidadAyer': cantidadAyer,
      'porcentajeCambio': porcentajeCambio,
      'tendencia': tendencia,
      'colorTipo': colorTipo.toARGB32(),
      'nivelAlerta': {
        'nivel': nivelAlerta.nivel,
        'color': nivelAlerta.color.toARGB32(),
        'icon': nivelAlerta.icon.codePoint,
      },
      'umbralAlerta': umbralAlerta,
      'tieneAlertaActiva': tieneAlertaActiva,
    };
  }

  /// Factory constructor para crear desde JSON
  factory InsectIndicatorData.fromJson(Map<String, dynamic> json) {
    final nivelAlertaData = json['nivelAlerta'] as Map<String, dynamic>;
    
    return InsectIndicatorData(
      tipoInsecto: json['tipoInsecto'] ?? '',
      cantidadHoy: json['cantidadHoy'] ?? 0,
      cantidadAyer: json['cantidadAyer'] ?? 0,
      porcentajeCambio: (json['porcentajeCambio'] ?? 0.0).toDouble(),
      tendencia: json['tendencia'] ?? 'stable',
      colorTipo: Color(json['colorTipo'] ?? 0xFF2796F4),
      nivelAlerta: AlertLevel(
        nivel: nivelAlertaData['nivel'] ?? 'normal',
        color: Color(nivelAlertaData['color'] ?? 0xFF4CAF50),
        icon: IconData(nivelAlertaData['icon'] ?? Icons.check_circle.codePoint, fontFamily: 'MaterialIcons'),
      ),
      umbralAlerta: json['umbralAlerta'] ?? 0,
      tieneAlertaActiva: json['tieneAlertaActiva'] ?? false,
    );
  }
}

// 🎯 Modelo para resumen del dashboard de insectos (Fase 1)
class InsectDashboardSummary {
  final List<InsectIndicatorData> indicadores;
  final int totalInsectosHoy;
  final int totalAlertasActivas;
  final DateTime ultimaActualizacion;

  InsectDashboardSummary({
    required this.indicadores,
    required this.totalInsectosHoy,
    required this.totalAlertasActivas,
    required this.ultimaActualizacion,
  });

  /// Obtiene el número de indicadores con alertas críticas
  int get indicadoresCriticos {
    return indicadores.where((i) => i.nivelAlerta.isCritical).length;
  }

  /// Obtiene el número de indicadores con advertencias
  int get indicadoresAdvertencia {
    return indicadores.where((i) => i.nivelAlerta.isWarning).length;
  }

  /// Obtiene el número de indicadores normales
  int get indicadoresNormales {
    return indicadores.where((i) => i.nivelAlerta.isNormal).length;
  }

  /// Obtiene el indicador con mayor cantidad del día
  InsectIndicatorData? get indicadorMayorCantidad {
    if (indicadores.isEmpty) return null;
    return indicadores.reduce((a, b) => a.cantidadHoy > b.cantidadHoy ? a : b);
  }

  /// Obtiene el indicador con mayor cambio porcentual positivo
  InsectIndicatorData? get indicadorMayorCrecimiento {
    if (indicadores.isEmpty) return null;
    final crecientes = indicadores.where((i) => i.porcentajeCambio > 0);
    if (crecientes.isEmpty) return null;
    return crecientes.reduce((a, b) => a.porcentajeCambio > b.porcentajeCambio ? a : b);
  }

  /// Obtiene el texto formateado de la última actualización
  String get ultimaActualizacionFormateada {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(ultimaActualizacion);
    
    if (diferencia.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else {
      return 'Hace ${diferencia.inDays} días';
    }
  }

  /// Factory constructor para crear desde listas básicas
  factory InsectDashboardSummary.fromData({
    required List<InsectIndicatorData> indicadores,
    required int totalAlertas,
  }) {
    final totalHoy = indicadores.fold<int>(0, (sum, i) => sum + i.cantidadHoy);
    
    return InsectDashboardSummary(
      indicadores: indicadores,
      totalInsectosHoy: totalHoy,
      totalAlertasActivas: totalAlertas,
      ultimaActualizacion: DateTime.now(),
    );
  }

  /// Convierte el objeto a JSON para serialización
  Map<String, dynamic> toJson() {
    return {
      'indicadores': indicadores.map((i) => i.toJson()).toList(),
      'totalInsectosHoy': totalInsectosHoy,
      'totalAlertasActivas': totalAlertasActivas,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }

  /// Factory constructor para crear desde JSON
  factory InsectDashboardSummary.fromJson(Map<String, dynamic> json) {
    return InsectDashboardSummary(
      indicadores: (json['indicadores'] as List)
          .map((i) => InsectIndicatorData.fromJson(i))
          .toList(),
      totalInsectosHoy: json['totalInsectosHoy'] ?? 0,
      totalAlertasActivas: json['totalAlertasActivas'] ?? 0,
      ultimaActualizacion: DateTime.parse(json['ultimaActualizacion']),
    );
  }
}

// 📊 Modelo para datos de barras apiladas por tipo y día
class StackedBarData {
  final DateTime fecha;
  final String fechaFormateada;
  final Map<String, int> insectosPorTipo;
  final int totalDia;

  StackedBarData({
    required this.fecha,
    required this.fechaFormateada,
    required this.insectosPorTipo,
    required this.totalDia,
  });

  // Convertir a BarChartGroupData para fl_chart
  BarChartGroupData toBarChartGroup(int index, List<String> tiposOrdenados,
      Map<String, Color> coloresPorTipo) {
    List<BarChartRodData> rods = [];
    double currentY = 0;

    for (String tipo in tiposOrdenados) {
      int cantidad = insectosPorTipo[tipo] ?? 0;
      if (cantidad > 0) {
        rods.add(BarChartRodData(
          fromY: currentY,
          toY: currentY + cantidad.toDouble(),
          color: coloresPorTipo[tipo] ?? const Color(0xFF2796F4),
          width: 20,
        ));
        currentY += cantidad.toDouble();
      }
    }

    return BarChartGroupData(x: index, barRods: rods);
  }
}

// ⚠️ Modelo para datos de alertas por severidad
class AlertSeverityData {
  final String severidad;
  final int cantidad;
  final String color;

  AlertSeverityData({
    required this.severidad,
    required this.cantidad,
    required this.color,
  });

  // Convertir a BarChartGroupData para fl_chart
  BarChartGroupData toBarChartGroup(int index) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: cantidad.toDouble(),
          color: _getSeverityColor(),
          width: 30,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Color _getSeverityColor() {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return const Color(0xFFF44336); // Rojo
      case 'media':
        return const Color(0xFFFF9800); // Naranja
      case 'baja':
        return const Color(0xFFFFEB3B); // Amarillo
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  String get severidadCapitalizada {
    return severidad[0].toUpperCase() + severidad.substring(1);
  }
}

// 🕐 Modelo para actividad por hora del día (heatmap)
class HourlyActivityData {
  final int hora; // 0-23
  final int diaSemana; // 0-6 (Lunes=0, Domingo=6)
  final int cantidad;
  double intensidad; // 0.0-1.0 normalizada

  HourlyActivityData({
    required this.hora,
    required this.diaSemana,
    required this.cantidad,
    required this.intensidad,
  });

  String get horaFormateada {
    return '${hora.toString().padLeft(2, '0')}:00';
  }

  String get diaFormateado {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[diaSemana];
  }

  Color get colorIntensidad {
    // Gradiente del azul del tema
    const baseColor = Color(0xFF2796F4);
    return baseColor.withValues(alpha: 0.1 + (intensidad * 0.9));
  }
}

// 📈 Modelo para datos acumulativos semanales
class WeeklyCumulativeData {
  final DateTime fecha;
  final int cantidadDiaria;
  final int cantidadAcumulada;
  final String fechaFormateada;

  WeeklyCumulativeData({
    required this.fecha,
    required this.cantidadDiaria,
    required this.cantidadAcumulada,
    required this.fechaFormateada,
  });

  // Convertir a FlSpot para fl_chart
  FlSpot toFlSpot(int index) {
    return FlSpot(index.toDouble(), cantidadAcumulada.toDouble());
  }
}

// ⏱️ Modelo para indicador de tiempo promedio
class AverageTimeIndicator {
  final Duration tiempoPromedio;
  final int totalDetecciones;
  final String estado; // 'bueno', 'regular', 'malo'

  AverageTimeIndicator({
    required this.tiempoPromedio,
    required this.totalDetecciones,
    required this.estado,
  });

  String get tiempoFormateado {
    if (tiempoPromedio.inDays > 0) {
      return '${tiempoPromedio.inDays}d ${tiempoPromedio.inHours % 24}h';
    } else if (tiempoPromedio.inHours > 0) {
      return '${tiempoPromedio.inHours}h ${tiempoPromedio.inMinutes % 60}m';
    } else {
      return '${tiempoPromedio.inMinutes}m';
    }
  }

  Color get colorEstado {
    switch (estado) {
      case 'bueno':
        return const Color(0xFF4CAF50); // Verde
      case 'regular':
        return const Color(0xFFFF9800); // Naranja
      case 'malo':
        return const Color(0xFFF44336); // Rojo
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  double get porcentajeIndicador {
    // Convertir tiempo a porcentaje para el indicador (0.0-1.0)
    // Menos tiempo = mejor (más porcentaje)
    const maxMinutos = 60; // 1 hora es "malo"
    final minutos = tiempoPromedio.inMinutes;
    return (maxMinutos - minutos.clamp(0, maxMinutos)) / maxMinutos;
  }
}

// 📊 Modelo para datos de tendencia semanal por tipo de insecto
class WeeklyTrendByTypeData {
  final String fecha;
  final String tipoInsecto;
  final int cantidad;
  final DateTime fechaDateTime;

  WeeklyTrendByTypeData({
    required this.fecha,
    required this.tipoInsecto,
    required this.cantidad,
    required this.fechaDateTime,
  });

  /// Convierte a FlSpot para fl_chart
  FlSpot toFlSpot(int index) {
    return FlSpot(index.toDouble(), cantidad.toDouble());
  }

  /// Obtiene la fecha formateada para mostrar en gráficas
  String get fechaFormateada {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fechaDateTime.day}/${meses[fechaDateTime.month - 1]}';
  }

  /// Factory constructor para crear desde JSON
  factory WeeklyTrendByTypeData.fromJson(Map<String, dynamic> json) {
    final fechaStr = json['fecha'] ?? '';
    DateTime fechaDateTime;
    
    try {
      fechaDateTime = DateTime.parse(fechaStr);
    } catch (e) {
      fechaDateTime = DateTime.now();
    }

    return WeeklyTrendByTypeData(
      fecha: fechaStr,
      tipoInsecto: json['tipo_insecto'] ?? json['tipoInsecto'] ?? '',
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      fechaDateTime: fechaDateTime,
    );
  }

  /// Convierte el objeto a JSON para serialización
  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'tipoInsecto': tipoInsecto,
      'cantidad': cantidad,
      'fechaDateTime': fechaDateTime.toIso8601String(),
    };
  }
}

class AlertaPlaga {
  final int id;
  final String tipo;
  final String mensaje;
  final String severidad;
  final String estado;
  final DateTime fecha; 

  AlertaPlaga({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.severidad,
    required this.estado,
    required this.fecha,
  });

  factory AlertaPlaga.fromJson(Map<String, dynamic> json) {
    return AlertaPlaga(
      id: int.parse(json['id'].toString()),
      tipo: json['tipo'],
      mensaje: json['mensaje'],
      severidad: json['severidad'],
      estado: json['estado'],
      fecha: DateTime.parse(json['fecha']), 
    );
  }
}

// 📈 Modelo para puntos de tendencia semanal agrupados por fecha
class WeeklyTrendPoint {
  final String fecha;
  final Map<String, int> cantidadesPorTipo;
  final DateTime fechaDateTime;

  WeeklyTrendPoint({
    required this.fecha,
    required this.cantidadesPorTipo,
    required this.fechaDateTime,
  });

  /// Obtiene la fecha formateada para mostrar en gráficas
  String get fechaFormateada {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fechaDateTime.day}/${meses[fechaDateTime.month - 1]}';
  }

  /// Obtiene el total de insectos para un tipo específico
  int getTotalForType(String tipo) {
    return cantidadesPorTipo[tipo] ?? 0;
  }

  /// Obtiene el total de insectos para todos los tipos en esta fecha
  int get totalInsectos {
    return cantidadesPorTipo.values.fold(0, (sum, cantidad) => sum + cantidad);
  }

  /// Obtiene la lista de tipos de insectos disponibles
  List<String> get tiposDisponibles {
    return cantidadesPorTipo.keys.toList()..sort();
  }

  /// Verifica si hay datos para un tipo específico
  bool hasDataForType(String tipo) {
    return cantidadesPorTipo.containsKey(tipo) && cantidadesPorTipo[tipo]! > 0;
  }

  /// Factory constructor para crear desde JSON
  factory WeeklyTrendPoint.fromJson(Map<String, dynamic> json) {
    final fechaStr = json['fecha'] ?? '';
    DateTime fechaDateTime;
    
    try {
      fechaDateTime = DateTime.parse(fechaStr);
    } catch (e) {
      fechaDateTime = DateTime.now();
    }

    // Procesar cantidades por tipo
    Map<String, int> cantidades = {};
    if (json['cantidadesPorTipo'] != null) {
      final cantidadesData = json['cantidadesPorTipo'] as Map<String, dynamic>;
      cantidadesData.forEach((tipo, cantidad) {
        cantidades[tipo] = int.tryParse(cantidad.toString()) ?? 0;
      });
    }

    return WeeklyTrendPoint(
      fecha: fechaStr,
      cantidadesPorTipo: cantidades,
      fechaDateTime: fechaDateTime,
    );
  }

  /// Factory constructor para crear desde lista de WeeklyTrendByTypeData
  factory WeeklyTrendPoint.fromTrendDataList(
    String fecha,
    List<WeeklyTrendByTypeData> trendDataList,
  ) {
    DateTime fechaDateTime;
    try {
      fechaDateTime = DateTime.parse(fecha);
    } catch (e) {
      fechaDateTime = DateTime.now();
    }

    Map<String, int> cantidades = {};
    // Procesar todos los datos de la lista ya que todos corresponden a la misma fecha/hora
    for (final trendData in trendDataList) {
      cantidades[trendData.tipoInsecto] = trendData.cantidad;
    }

    return WeeklyTrendPoint(
      fecha: fecha,
      cantidadesPorTipo: cantidades,
      fechaDateTime: fechaDateTime,
    );
  }

  /// Convierte el objeto a JSON para serialización
  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'cantidadesPorTipo': cantidadesPorTipo,
      'fechaDateTime': fechaDateTime.toIso8601String(),
    };
  }
}

// 📋 Clase para respuesta del servicio de datos
class ChartDataResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final DateTime timestamp;

  ChartDataResponse({
    required this.success,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory ChartDataResponse.success(T data) {
    return ChartDataResponse(
      success: true,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory ChartDataResponse.error(String error) {
    return ChartDataResponse(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }

  // Getter methods for compatibility
  bool get isSuccess => success;
  String? get errorMessage => error;
}

class StackedTrapData {
  final String trapId;
  final Map<String, int> insectosPorTipo;
  final int totalTrap;

  StackedTrapData({
    required this.trapId,
    required this.insectosPorTipo,
    required this.totalTrap,
  });

  factory StackedTrapData.fromJson(Map<String, dynamic> json) {
    final insectos = Map<String, int>.from(
      (json['insectos_por_tipo'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );

    return StackedTrapData(
      trapId: json['trampa_id'].toString(),
      insectosPorTipo: insectos,
      totalTrap: insectos.values.fold(0, (sum, count) => sum + count),
    );
  }

  BarChartGroupData toBarChartGroup(
    int x,
    List<String> tiposOrdenados,
    Map<String, Color> coloresPorTipo,
  ) {
    double currentY = 0;
    List<BarChartRodStackItem> stackItems = [];

    for (String tipo in tiposOrdenados) {
      int cantidad = insectosPorTipo[tipo] ?? 0;
      if (cantidad > 0) {
        final color = coloresPorTipo[tipo] ?? Colors.grey;
        stackItems.add(BarChartRodStackItem(
          currentY,
          currentY + cantidad,
          color,
        ));
        currentY += cantidad;
      }
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: totalTrap.toDouble(),
          rodStackItems: stackItems,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
