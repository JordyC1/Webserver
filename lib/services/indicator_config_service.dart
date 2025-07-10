import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chart_models.dart';
import 'package:flutter/material.dart';

/// Servicio para gestionar la configuración de umbrales de alertas de insectos
/// Maneja tanto la persistencia local como la sincronización con el servidor
class IndicatorConfigService {
  static const String _thresholdsKey = 'insect_thresholds';
  static const String baseUrl = "http://raspberrypi2.local";
  
  /// Umbrales por defecto para diferentes tipos de insectos
  static const Map<String, int> defaultThresholds = {
    'mosca': 50,
    'mosquito': 30,
    'abeja': 20,
    'avispa': 25,
    'polilla': 40,
    'escarabajo': 35,
    'chinche': 45,
    'hormiga': 60,
    'cucaracha': 15,
    'termita': 25,
  };
  
  /// Carga los umbrales desde el almacenamiento local
  /// Si no existen, retorna los valores por defecto
  static Future<Map<String, int>> loadThresholds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final thresholdsJson = prefs.getString(_thresholdsKey);
      
      if (thresholdsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(thresholdsJson);
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      print('Error al cargar umbrales desde almacenamiento local: $e');
    }
    
    // Retornar valores por defecto si no hay datos guardados
    return Map.from(defaultThresholds);
  }
  
  /// Guarda los umbrales en el almacenamiento local
  /// Opcionalmente sincroniza con el servidor
  static Future<bool> saveThresholds(Map<String, int> thresholds, {bool syncToServer = true}) async {
    try {
      // Guardar localmente
      final prefs = await SharedPreferences.getInstance();
      final thresholdsJson = jsonEncode(thresholds);
      await prefs.setString(_thresholdsKey, thresholdsJson);
      
      // Sincronizar con el servidor si se solicita
      if (syncToServer) {
        await _syncThresholdsToServer(thresholds);
      }
      
      return true;
    } catch (e) {
      print('Error al guardar umbrales: $e');
      return false;
    }
  }
  
  /// Sincroniza los umbrales con el servidor
  static Future<bool> _syncThresholdsToServer(Map<String, int> thresholds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_configuracion_plagas.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'umbrales': thresholds,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al sincronizar umbrales con el servidor: $e');
      return false;
    }
  }
  
  /// Carga los umbrales desde el servidor y los guarda localmente
  static Future<Map<String, int>> loadThresholdsFromServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/get_configuracion_plagas.php'))
          .timeout(const Duration(seconds: 10));
          
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        Map<String, int> serverThresholds = {};
        
        for (var config in data) {
          final tipo = config['tipo'].toString();
          final umbral = int.tryParse(config['umbral_alerta'].toString()) ?? defaultThresholds[tipo] ?? 50;
          serverThresholds[tipo] = umbral;
        }
        
        // Guardar localmente los datos del servidor
        await saveThresholds(serverThresholds, syncToServer: false);
        return serverThresholds;
      }
    } catch (e) {
      print('Error al cargar umbrales desde el servidor: $e');
    }
    
    // Si falla, cargar desde almacenamiento local
    return await loadThresholds();
  }
  
  /// Calcula el nivel de alerta basado en la cantidad actual y el umbral
  static AlertLevel calculateAlertLevel(int current, int threshold) {
    if (current < threshold) {
      return AlertLevel(
        nivel: 'normal',
        color: const Color(0xFF4CAF50), // Verde
        icon: Icons.check_circle,
      );
    } else if (current < threshold * 1.5) {
      return AlertLevel(
        nivel: 'warning',
        color: const Color(0xFFFF9800), // Naranja
        icon: Icons.warning,
      );
    } else {
      return AlertLevel(
        nivel: 'critical',
        color: const Color(0xFFF44336), // Rojo
        icon: Icons.error,
      );
    }
  }
  
  /// Obtiene el umbral para un tipo específico de insecto
  static Future<int> getThresholdForType(String insectType) async {
    final thresholds = await loadThresholds();
    return thresholds[insectType] ?? defaultThresholds[insectType] ?? 50;
  }
  
  /// Actualiza el umbral para un tipo específico de insecto
  static Future<bool> updateThresholdForType(String insectType, int threshold) async {
    final currentThresholds = await loadThresholds();
    currentThresholds[insectType] = threshold;
    return await saveThresholds(currentThresholds);
  }
  
  /// Resetea todos los umbrales a los valores por defecto
  static Future<bool> resetToDefaults() async {
    return await saveThresholds(Map.from(defaultThresholds));
  }
  
  /// Obtiene todos los tipos de insectos configurados
  static Future<List<String>> getConfiguredInsectTypes() async {
    final thresholds = await loadThresholds();
    return thresholds.keys.toList()..sort();
  }
  
  /// Agrega un nuevo tipo de insecto con su umbral
  static Future<bool> addInsectType(String insectType, int threshold) async {
    final currentThresholds = await loadThresholds();
    currentThresholds[insectType] = threshold;
    return await saveThresholds(currentThresholds);
  }
  
  /// Elimina un tipo de insecto de la configuración
  static Future<bool> removeInsectType(String insectType) async {
    final currentThresholds = await loadThresholds();
    currentThresholds.remove(insectType);
    return await saveThresholds(currentThresholds);
  }
  
  /// Valida que un umbral esté en un rango aceptable
  static bool isValidThreshold(int threshold) {
    return threshold >= 1 && threshold <= 1000;
  }
  
  /// Obtiene estadísticas de configuración
  static Future<Map<String, dynamic>> getConfigurationStats() async {
    final thresholds = await loadThresholds();
    
    return {
      'totalTypes': thresholds.length,
      'averageThreshold': thresholds.values.isEmpty 
          ? 0 
          : thresholds.values.reduce((a, b) => a + b) / thresholds.values.length,
      'minThreshold': thresholds.values.isEmpty ? 0 : thresholds.values.reduce((a, b) => a < b ? a : b),
      'maxThreshold': thresholds.values.isEmpty ? 0 : thresholds.values.reduce((a, b) => a > b ? a : b),
      'lastModified': DateTime.now().toIso8601String(),
    };
  }
  
  /// Exporta la configuración actual como JSON
  static Future<String> exportConfiguration() async {
    final thresholds = await loadThresholds();
    final stats = await getConfigurationStats();
    
    return jsonEncode({
      'thresholds': thresholds,
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'stats': stats,
      },
    });
  }
  
  /// Importa configuración desde JSON
  static Future<bool> importConfiguration(String jsonConfig) async {
    try {
      final config = jsonDecode(jsonConfig);
      final thresholds = Map<String, int>.from(config['thresholds']);
      
      // Validar umbrales
      for (var threshold in thresholds.values) {
        if (!isValidThreshold(threshold)) {
          return false;
        }
      }
      
      return await saveThresholds(thresholds);
    } catch (e) {
      print('Error al importar configuración: $e');
      return false;
    }
  }
}