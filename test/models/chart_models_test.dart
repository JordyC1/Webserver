import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/models/chart_models.dart';

void main() {
  group('Fase 1 - Modelos de Indicadores de Insectos', () {
    test('AlertLevel debe crear correctamente los niveles', () {
      final alertaNormal = AlertLevel(
        nivel: 'normal',
        color: const Color(0xFF4CAF50),
        icon: Icons.check_circle,
      );

      expect(alertaNormal.nivel, 'normal');
      expect(alertaNormal.nivelCapitalizado, 'Normal');
      expect(alertaNormal.isNormal, true);
      expect(alertaNormal.isWarning, false);
      expect(alertaNormal.isCritical, false);
    });

    test('InsectTypeData debe calcular correctamente el nivel de alerta', () {
      final insectData = InsectTypeData(
        tipo: 'mosca',
        cantidad: 75,
        porcentaje: 50.0,
        color: 'blue',
      );

      // Umbral de 50 - cantidad 75 debe ser warning
      final alertLevel = insectData.calculateAlertLevel(50);
      expect(alertLevel.nivel, 'warning');

      // Umbral de 40 - cantidad 75 debe ser critical (75 >= 40 * 1.5 = 60)
      final criticalLevel = insectData.calculateAlertLevel(40);
      expect(criticalLevel.nivel, 'critical');

      // Umbral de 100 - cantidad 75 debe ser normal
      final normalLevel = insectData.calculateAlertLevel(100);
      expect(normalLevel.nivel, 'normal');
    });

    test('InsectTypeData debe calcular correctamente el porcentaje de tendencia', () {
      final insectData = InsectTypeData(
        tipo: 'mosquito',
        cantidad: 60,
        porcentaje: 40.0,
        color: 'red',
      );

      // De 50 a 60 = 20% de incremento
      final percentage = insectData.calculateTrendPercentage(50);
      expect(percentage, 20.0);

      // De 0 a 60 = 100% (caso especial)
      final percentageFromZero = insectData.calculateTrendPercentage(0);
      expect(percentageFromZero, 100.0);

      // De 80 a 60 = -25% de decremento
      final negativePercentage = insectData.calculateTrendPercentage(80);
      expect(negativePercentage, -25.0);
    });

    test('InsectTypeData debe obtener iconos de tendencia correctos', () {
      expect(InsectTypeData.getTrendIconFromPercentage(10.0), Icons.trending_up);
      expect(InsectTypeData.getTrendIconFromPercentage(-10.0), Icons.trending_down);
      expect(InsectTypeData.getTrendIconFromPercentage(2.0), Icons.trending_flat);
    });

    test('InsectIndicatorData.fromBasicData debe crear correctamente el indicador', () {
      final indicator = InsectIndicatorData.fromBasicData(
        tipo: 'abeja',
        cantidadHoy: 45,
        cantidadAyer: 30,
        color: const Color(0xFFFFEB3B),
        umbral: 40,
        tieneAlerta: false,
      );

      expect(indicator.tipoInsecto, 'abeja');
      expect(indicator.cantidadHoy, 45);
      expect(indicator.cantidadAyer, 30);
      expect(indicator.tendencia, 'up'); // 50% de incremento
      expect(indicator.nivelAlerta.nivel, 'warning'); // 45 >= 40
      expect(indicator.porcentajeCambio, 50.0);
      expect(indicator.tieneCambioSignificativo, true);
    });

    test('InsectIndicatorData debe formatear correctamente el porcentaje', () {
      final indicatorPositivo = InsectIndicatorData(
        tipoInsecto: 'test',
        cantidadHoy: 60,
        cantidadAyer: 50,
        porcentajeCambio: 20.5,
        tendencia: 'up',
        colorTipo: Colors.blue,
        nivelAlerta: AlertLevel(nivel: 'normal', color: Colors.green, icon: Icons.check),
        umbralAlerta: 100,
        tieneAlertaActiva: false,
      );

      expect(indicatorPositivo.porcentajeCambioFormateado, '+20.5%');

      final indicatorNegativo = InsectIndicatorData(
        tipoInsecto: 'test',
        cantidadHoy: 40,
        cantidadAyer: 50,
        porcentajeCambio: -20.0,
        tendencia: 'down',
        colorTipo: Colors.red,
        nivelAlerta: AlertLevel(nivel: 'normal', color: Colors.green, icon: Icons.check),
        umbralAlerta: 100,
        tieneAlertaActiva: false,
      );

      expect(indicatorNegativo.porcentajeCambioFormateado, '-20.0%');
    });

    test('InsectDashboardSummary debe calcular correctamente las estadísticas', () {
      final indicadores = [
        InsectIndicatorData.fromBasicData(
          tipo: 'mosca',
          cantidadHoy: 80,
          cantidadAyer: 60,
          color: Colors.blue,
          umbral: 50, // Critical: 80 >= 75
        ),
        InsectIndicatorData.fromBasicData(
          tipo: 'mosquito',
          cantidadHoy: 60,
          cantidadAyer: 40,
          color: Colors.red,
          umbral: 50, // Warning: 60 >= 50
        ),
        InsectIndicatorData.fromBasicData(
          tipo: 'abeja',
          cantidadHoy: 30,
          cantidadAyer: 25,
          color: Colors.yellow,
          umbral: 50, // Normal: 30 < 50
        ),
      ];

      final summary = InsectDashboardSummary.fromData(
        indicadores: indicadores,
        totalAlertas: 2,
      );

      expect(summary.totalInsectosHoy, 170); // 80 + 60 + 30
      expect(summary.totalAlertasActivas, 2);
      expect(summary.indicadoresCriticos, 1);
      expect(summary.indicadoresAdvertencia, 1);
      expect(summary.indicadoresNormales, 1);
      expect(summary.indicadorMayorCantidad?.tipoInsecto, 'mosca');
      expect(summary.indicadorMayorCrecimiento?.tipoInsecto, 'mosquito'); // 50% vs 33.3% vs 20%
    });

    test('InsectDashboardSummary debe formatear correctamente la última actualización', () {
      final summary = InsectDashboardSummary(
        indicadores: [],
        totalInsectosHoy: 0,
        totalAlertasActivas: 0,
        ultimaActualizacion: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(summary.ultimaActualizacionFormateada, 'Hace 5 min');
    });
  });
}