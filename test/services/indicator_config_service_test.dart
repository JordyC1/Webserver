import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/indicator_config_service.dart';
import '../../lib/models/chart_models.dart';

void main() {
  group('Fase 2 - IndicatorConfigService', () {
    setUp(() {
      // Configurar SharedPreferences mock para las pruebas
      SharedPreferences.setMockInitialValues({});
    });

    test('defaultThresholds debe contener valores válidos', () {
      expect(IndicatorConfigService.defaultThresholds.isNotEmpty, true);
      expect(IndicatorConfigService.defaultThresholds['mosca'], 50);
      expect(IndicatorConfigService.defaultThresholds['mosquito'], 30);
      expect(IndicatorConfigService.defaultThresholds['abeja'], 20);
      
      // Verificar que todos los umbrales son válidos
      for (var threshold in IndicatorConfigService.defaultThresholds.values) {
        expect(IndicatorConfigService.isValidThreshold(threshold), true);
      }
    });

    test('loadThresholds debe retornar valores por defecto cuando no hay datos guardados', () async {
      final thresholds = await IndicatorConfigService.loadThresholds();
      
      expect(thresholds.isNotEmpty, true);
      expect(thresholds['mosca'], IndicatorConfigService.defaultThresholds['mosca']);
      expect(thresholds['mosquito'], IndicatorConfigService.defaultThresholds['mosquito']);
    });

    test('saveThresholds debe guardar y cargar correctamente', () async {
      final testThresholds = {
        'mosca': 60,
        'mosquito': 40,
        'abeja': 25,
      };
      
      // Guardar umbrales
      final saveResult = await IndicatorConfigService.saveThresholds(
        testThresholds, 
        syncToServer: false, // No sincronizar en pruebas
      );
      expect(saveResult, true);
      
      // Cargar umbrales
      final loadedThresholds = await IndicatorConfigService.loadThresholds();
      expect(loadedThresholds['mosca'], 60);
      expect(loadedThresholds['mosquito'], 40);
      expect(loadedThresholds['abeja'], 25);
    });

    test('calculateAlertLevel debe retornar niveles correctos', () {
      // Nivel normal
      final normalLevel = IndicatorConfigService.calculateAlertLevel(30, 50);
      expect(normalLevel.nivel, 'normal');
      expect(normalLevel.isNormal, true);
      expect(normalLevel.color, const Color(0xFF4CAF50));
      
      // Nivel warning
      final warningLevel = IndicatorConfigService.calculateAlertLevel(60, 50);
      expect(warningLevel.nivel, 'warning');
      expect(warningLevel.isWarning, true);
      expect(warningLevel.color, const Color(0xFFFF9800));
      
      // Nivel critical
      final criticalLevel = IndicatorConfigService.calculateAlertLevel(80, 50);
      expect(criticalLevel.nivel, 'critical');
      expect(criticalLevel.isCritical, true);
      expect(criticalLevel.color, const Color(0xFFF44336));
    });

    test('getThresholdForType debe retornar umbral correcto', () async {
      // Configurar umbrales de prueba
      await IndicatorConfigService.saveThresholds({
        'mosca': 70,
        'mosquito': 35,
      }, syncToServer: false);
      
      // Obtener umbral existente
      final moscaThreshold = await IndicatorConfigService.getThresholdForType('mosca');
      expect(moscaThreshold, 70);
      
      // Obtener umbral por defecto para tipo no configurado
      final abejasThreshold = await IndicatorConfigService.getThresholdForType('abeja');
      expect(abejasThreshold, IndicatorConfigService.defaultThresholds['abeja']);
      
      // Obtener umbral por defecto para tipo desconocido
      final unknownThreshold = await IndicatorConfigService.getThresholdForType('desconocido');
      expect(unknownThreshold, 50); // valor por defecto
    });

    test('updateThresholdForType debe actualizar correctamente', () async {
      // Actualizar umbral
      final updateResult = await IndicatorConfigService.updateThresholdForType('mosca', 80);
      expect(updateResult, true);
      
      // Verificar que se actualizó
      final updatedThreshold = await IndicatorConfigService.getThresholdForType('mosca');
      expect(updatedThreshold, 80);
    });

    test('resetToDefaults debe restaurar valores por defecto', () async {
      // Configurar umbrales personalizados
      await IndicatorConfigService.saveThresholds({
        'mosca': 100,
        'mosquito': 200,
      }, syncToServer: false);
      
      // Resetear a valores por defecto
      final resetResult = await IndicatorConfigService.resetToDefaults();
      expect(resetResult, true);
      
      // Verificar que se restauraron los valores por defecto
      final thresholds = await IndicatorConfigService.loadThresholds();
      expect(thresholds['mosca'], IndicatorConfigService.defaultThresholds['mosca']);
      expect(thresholds['mosquito'], IndicatorConfigService.defaultThresholds['mosquito']);
    });

    test('getConfiguredInsectTypes debe retornar lista ordenada', () async {
      await IndicatorConfigService.saveThresholds({
        'zebra': 10, // Debe aparecer al final
        'abeja': 20,
        'mosca': 50,
      }, syncToServer: false);
      
      final types = await IndicatorConfigService.getConfiguredInsectTypes();
      expect(types.length, 3);
      expect(types[0], 'abeja'); // Orden alfabético
      expect(types[1], 'mosca');
      expect(types[2], 'zebra');
    });

    test('addInsectType debe agregar nuevo tipo', () async {
      final addResult = await IndicatorConfigService.addInsectType('libélula', 15);
      expect(addResult, true);
      
      final threshold = await IndicatorConfigService.getThresholdForType('libélula');
      expect(threshold, 15);
    });

    test('removeInsectType debe eliminar tipo', () async {
      // Agregar tipo
      await IndicatorConfigService.addInsectType('temporal', 25);
      
      // Verificar que existe
      var threshold = await IndicatorConfigService.getThresholdForType('temporal');
      expect(threshold, 25);
      
      // Eliminar tipo
      final removeResult = await IndicatorConfigService.removeInsectType('temporal');
      expect(removeResult, true);
      
      // Verificar que ya no existe (debe retornar valor por defecto)
      threshold = await IndicatorConfigService.getThresholdForType('temporal');
      expect(threshold, 50); // valor por defecto
    });

    test('isValidThreshold debe validar rangos correctamente', () {
      expect(IndicatorConfigService.isValidThreshold(1), true);
      expect(IndicatorConfigService.isValidThreshold(50), true);
      expect(IndicatorConfigService.isValidThreshold(1000), true);
      
      expect(IndicatorConfigService.isValidThreshold(0), false);
      expect(IndicatorConfigService.isValidThreshold(-1), false);
      expect(IndicatorConfigService.isValidThreshold(1001), false);
    });

    test('getConfigurationStats debe calcular estadísticas correctamente', () async {
      await IndicatorConfigService.saveThresholds({
        'tipo1': 10,
        'tipo2': 20,
        'tipo3': 30,
      }, syncToServer: false);
      
      final stats = await IndicatorConfigService.getConfigurationStats();
      
      expect(stats['totalTypes'], 3);
      expect(stats['averageThreshold'], 20.0);
      expect(stats['minThreshold'], 10);
      expect(stats['maxThreshold'], 30);
      expect(stats['lastModified'], isA<String>());
    });

    test('exportConfiguration debe generar JSON válido', () async {
      await IndicatorConfigService.saveThresholds({
        'mosca': 50,
        'mosquito': 30,
      }, syncToServer: false);
      
      final exportedJson = await IndicatorConfigService.exportConfiguration();
      expect(exportedJson, isA<String>());
      expect(exportedJson.contains('thresholds'), true);
      expect(exportedJson.contains('metadata'), true);
    });

    test('importConfiguration debe importar configuración válida', () async {
      final configJson = '''{
        "thresholds": {
          "mosca": 75,
          "mosquito": 45
        },
        "metadata": {
          "version": "1.0"
        }
      }''';
      
      final importResult = await IndicatorConfigService.importConfiguration(configJson);
      expect(importResult, true);
      
      // Verificar que se importó correctamente
      final moscaThreshold = await IndicatorConfigService.getThresholdForType('mosca');
      expect(moscaThreshold, 75);
    });

    test('importConfiguration debe rechazar configuración inválida', () async {
      final invalidConfigJson = '''{
        "thresholds": {
          "mosca": 2000,
          "mosquito": -5
        }
      }''';
      
      final importResult = await IndicatorConfigService.importConfiguration(invalidConfigJson);
      expect(importResult, false);
    });
  });
}