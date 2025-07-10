import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chart_models.dart';

/// Servicio de cache para indicadores de insectos
/// Implementa cache temporal con expiración automática
class IndicatorCacheService {
  static const String _cacheKey = 'insect_indicators_cache';
  static const String _timestampKey = 'insect_indicators_timestamp';
  static const Duration cacheExpiry = Duration(minutes: 5);

  /// Almacena los datos de indicadores en cache
  static Future<void> cacheIndicators(InsectDashboardSummary data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_timestampKey, timestamp);
    } catch (e) {
      // Silenciosamente falla si no se puede cachear
      debugPrint('Error caching indicators: $e');
    }
  }

  /// Recupera los datos de indicadores del cache si están válidos
  static Future<InsectDashboardSummary?> getCachedIndicators() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_cacheKey) || !prefs.containsKey(_timestampKey)) {
        return null;
      }
      
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (!isCacheValid(cacheTime)) {
        await clearCache();
        return null;
      }
      
      final jsonData = prefs.getString(_cacheKey);
      if (jsonData == null) return null;
      
      final Map<String, dynamic> data = jsonDecode(jsonData);
      return InsectDashboardSummary.fromJson(data);
    } catch (e) {
      // Si hay error al leer cache, lo limpiamos
      await clearCache();
      return null;
    }
  }

  /// Verifica si el cache sigue siendo válido
  static bool isCacheValid(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference < cacheExpiry;
  }

  /// Limpia el cache de indicadores
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Obtiene información sobre el estado del cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      
      if (timestamp == null) {
        return {
          'hasCache': false,
          'isValid': false,
          'lastUpdate': null,
          'expiresAt': null,
        };
      }
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiresAt = cacheTime.add(cacheExpiry);
      final isValid = isCacheValid(cacheTime);
      
      return {
        'hasCache': true,
        'isValid': isValid,
        'lastUpdate': cacheTime.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'remainingMinutes': isValid 
            ? expiresAt.difference(DateTime.now()).inMinutes 
            : 0,
      };
    } catch (e) {
      return {
        'hasCache': false,
        'isValid': false,
        'lastUpdate': null,
        'expiresAt': null,
        'error': e.toString(),
      };
    }
  }

  /// Fuerza la actualización del cache (útil para testing)
  static Future<void> forceCacheExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiredTimestamp = DateTime.now()
          .subtract(cacheExpiry)
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      
      await prefs.setInt(_timestampKey, expiredTimestamp);
    } catch (e) {
      debugPrint('Error forcing cache expiry: $e');
    }
  }
}