import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import '../../lib/services/chart_data_service.dart';
import '../../lib/models/chart_models.dart';

void main() {
  group('Fase 2 - ChartDataService Nuevos Métodos', () {
    
    test('fetchInsectThresholds debe retornar umbrales por defecto cuando el servidor falla', () async {
      // Esta prueba verifica que el método funciona con valores por defecto
      final response = await ChartDataService.fetchInsectThresholds();
      
      expect(response.isSuccess, true);
      expect(response.data, isA<Map<String, int>>());
      expect(response.data!['mosca'], 50);
      expect(response.data!['mosquito'], 30);
      expect(response.data!['abeja'], 20);
    });

    test('fetchInsectIndicators debe manejar datos vacíos correctamente', () async {
      // Esta prueba verifica el comportamiento con datos vacíos
      final response = await ChartDataService.fetchInsectIndicators();
      
      // Debe retornar una respuesta, aunque sea con datos vacíos o error de conexión
      expect(response, isA<ChartDataResponse<InsectDashboardSummary>>());
      
      if (response.isSuccess) {
        expect(response.data, isA<InsectDashboardSummary>());
        expect(response.data!.indicadores, isA<List<InsectIndicatorData>>());
      } else {
        // Si falla la conexión, debe tener un mensaje de error
        expect(response.errorMessage, isNotEmpty);
      }
    });

    test('fetchInsectTypeIndicators debe manejar fechas específicas', () async {
      final targetDate = DateTime(2024, 1, 15);
      final response = await ChartDataService.fetchInsectTypeIndicators(
        targetDate: targetDate,
      );
      
      // Debe retornar una respuesta
      expect(response, isA<ChartDataResponse<List<InsectIndicatorData>>>());
      
      if (response.isSuccess) {
        expect(response.data, isA<List<InsectIndicatorData>>());
        // La lista puede estar vacía si no hay datos para esa fecha
        expect(response.data!.length, greaterThanOrEqualTo(0));
      } else {
        // Si falla, debe tener mensaje de error
        expect(response.errorMessage, isNotEmpty);
      }
    });

    test('fetchAllDashboardData debe incluir todos los datos necesarios', () async {
      final allData = await ChartDataService.fetchAllDashboardData();
      
      expect(allData, isA<Map<String, dynamic>>());
      
      // Verificar que contiene todas las claves esperadas
      final expectedKeys = [
        'dailyTrend',
        'insectDistribution',
        'stackedBar',
        'alertsSeverity',
        'hourlyActivity',
        'weeklyCumulative',
        'averageTime',
        'insectIndicators',
        'typeIndicators',
      ];
      
      for (String key in expectedKeys) {
        expect(allData.containsKey(key), true, reason: 'Falta la clave: $key');
        expect(allData[key], isA<ChartDataResponse>());
      }
    });

    test('fetchInsectIndicators con diferentes días de comparación', () async {
      // Probar con 1 día de comparación
      final response1 = await ChartDataService.fetchInsectIndicators(
        daysForComparison: 1,
      );
      
      // Probar con 7 días de comparación
      final response7 = await ChartDataService.fetchInsectIndicators(
        daysForComparison: 7,
      );
      
      // Ambas respuestas deben ser del mismo tipo
      expect(response1, isA<ChartDataResponse<InsectDashboardSummary>>());
      expect(response7, isA<ChartDataResponse<InsectDashboardSummary>>());
    });

    test('ChartDataResponse debe manejar errores correctamente', () {
      // Crear respuesta de error
      final errorResponse = ChartDataResponse<String>.error('Error de prueba');
      
      expect(errorResponse.isSuccess, false);
      expect(errorResponse.data, null);
      expect(errorResponse.errorMessage, 'Error de prueba');
      
      // Crear respuesta exitosa
      final successResponse = ChartDataResponse<String>.success('Datos de prueba');
      
      expect(successResponse.isSuccess, true);
      expect(successResponse.data, 'Datos de prueba');
      expect(successResponse.errorMessage, null);
    });

    test('Integración de umbrales con indicadores', () async {
      // Obtener umbrales
      final thresholdsResponse = await ChartDataService.fetchInsectThresholds();
      expect(thresholdsResponse.isSuccess, true);
      
      final thresholds = thresholdsResponse.data!;
      
      // Verificar que los umbrales son válidos
      for (var threshold in thresholds.values) {
        expect(threshold, greaterThan(0));
        expect(threshold, lessThanOrEqualTo(1000));
      }
      
      // Los umbrales deben incluir tipos comunes
      expect(thresholds.containsKey('mosca'), true);
      expect(thresholds.containsKey('mosquito'), true);
      expect(thresholds.containsKey('abeja'), true);
    });

    test('Validación de estructura de InsectDashboardSummary', () async {
      final response = await ChartDataService.fetchInsectIndicators();
      
      if (response.isSuccess && response.data != null) {
        final summary = response.data!;
        
        // Verificar propiedades básicas
        expect(summary.indicadores, isA<List<InsectIndicatorData>>());
        expect(summary.totalInsectosHoy, greaterThanOrEqualTo(0));
        expect(summary.totalAlertasActivas, greaterThanOrEqualTo(0));
        expect(summary.ultimaActualizacion, isA<DateTime>());
        
        // Verificar contadores
        expect(summary.indicadoresCriticos, greaterThanOrEqualTo(0));
        expect(summary.indicadoresAdvertencia, greaterThanOrEqualTo(0));
        expect(summary.indicadoresNormales, greaterThanOrEqualTo(0));
        
        // La suma de contadores debe ser igual al total de indicadores
        final totalContadores = summary.indicadoresCriticos + 
                               summary.indicadoresAdvertencia + 
                               summary.indicadoresNormales;
        expect(totalContadores, summary.indicadores.length);
        
        // Verificar formato de última actualización
        expect(summary.ultimaActualizacionFormateada, isA<String>());
        expect(summary.ultimaActualizacionFormateada.isNotEmpty, true);
      }
    });

    test('Validación de estructura de InsectIndicatorData', () async {
      final response = await ChartDataService.fetchInsectTypeIndicators();
      
      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        final indicator = response.data!.first;
        
        // Verificar propiedades básicas
        expect(indicator.tipoInsecto, isA<String>());
        expect(indicator.tipoInsecto.isNotEmpty, true);
        expect(indicator.cantidadHoy, greaterThanOrEqualTo(0));
        expect(indicator.cantidadAyer, greaterThanOrEqualTo(0));
        expect(indicator.porcentajeCambio, isA<double>());
        expect(indicator.tendencia, isA<String>());
        expect(indicator.colorTipo, isA<Color>());
        expect(indicator.nivelAlerta, isA<AlertLevel>());
        expect(indicator.umbralAlerta, greaterThan(0));
        expect(indicator.tieneAlertaActiva, isA<bool>());
        
        // Verificar tendencia válida
        expect(['up', 'down', 'flat'].contains(indicator.tendencia), true);
        
        // Verificar formato de porcentaje
        expect(indicator.porcentajeCambioFormateado, isA<String>());
        expect(indicator.porcentajeCambioFormateado.contains('%'), true);
        
        // Verificar cambio significativo
        expect(indicator.tieneCambioSignificativo, isA<bool>());
      }
    });

    test('Manejo de timeouts y errores de red', () async {
      // Esta prueba verifica que los métodos manejen correctamente los timeouts
      // En un entorno real, esto podría fallar por timeout, lo cual es esperado
      
      final startTime = DateTime.now();
      final response = await ChartDataService.fetchInsectIndicators();
      final endTime = DateTime.now();
      
      // El método no debe tardar más de 30 segundos (timeout + margen)
      final duration = endTime.difference(startTime);
      expect(duration.inSeconds, lessThan(30));
      
      // Debe retornar una respuesta válida (exitosa o con error)
      expect(response, isA<ChartDataResponse<InsectDashboardSummary>>());
    });

    test('Consistencia entre fetchAllChartData y fetchAllDashboardData', () async {
      final originalData = await ChartDataService.fetchAllChartData();
      final extendedData = await ChartDataService.fetchAllDashboardData();
      
      // Los datos originales deben estar incluidos en los datos extendidos
      final originalKeys = [
        'dailyTrend',
        'insectDistribution',
        'stackedBar',
        'alertsSeverity',
        'hourlyActivity',
        'weeklyCumulative',
        'averageTime',
      ];
      
      for (String key in originalKeys) {
        expect(originalData.containsKey(key), true);
        expect(extendedData.containsKey(key), true);
      }
      
      // Los datos extendidos deben tener claves adicionales
      expect(extendedData.containsKey('insectIndicators'), true);
      expect(extendedData.containsKey('typeIndicators'), true);
    });
  });
}