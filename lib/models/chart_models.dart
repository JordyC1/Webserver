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
  final double intensidad; // 0.0-1.0 normalizada

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
    return baseColor.withOpacity(0.1 + (intensidad * 0.9));
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
}
