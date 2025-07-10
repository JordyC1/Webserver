import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/chart_models.dart';
import 'indicator_config_service.dart';

/// Servicio de notificaciones para alertas críticas de insectos
/// Maneja notificaciones locales cuando se superan umbrales críticos
class NotificationService {
  static bool _isInitialized = false;
  static final List<String> _sentNotifications = [];
  
  /// Inicializa el servicio de notificaciones
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      // En web, las notificaciones se manejan a través del navegador
      if (kIsWeb) {
        await _requestWebPermission();
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }
  
  /// Solicita permisos para notificaciones web
  static Future<void> _requestWebPermission() async {
    // En Flutter Web, usamos la API de notificaciones del navegador
    // Esta implementación es básica y puede expandirse
    if (kIsWeb) {
      try {
        // Verificar si las notificaciones están soportadas
        debugPrint('Requesting web notification permission...');
      } catch (e) {
        debugPrint('Web notifications not supported: $e');
      }
    }
  }
  
  /// Verifica y envía notificaciones para alertas críticas
  static Future<void> checkAndNotifyAlerts(InsectDashboardSummary summary) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await IndicatorConfigService.loadThresholds();
      
      for (final indicator in summary.indicadores) {
        await _checkIndicatorAlert(indicator);
      }
      
      // Verificar alertas generales
      await _checkGeneralAlerts(summary);
      
    } catch (e) {
      debugPrint('Error checking alerts: $e');
    }
  }
  
  /// Verifica alertas para un indicador específico
  static Future<void> _checkIndicatorAlert(
    InsectIndicatorData indicator
  ) async {
    if (indicator.nivelAlerta.nivel == 'critical') {
      final notificationId = 'critical_${indicator.tipoInsecto}_${DateTime.now().day}';
      
      // Evitar notificaciones duplicadas en el mismo día
      if (_sentNotifications.contains(notificationId)) {
        return;
      }
      
      final threshold = await IndicatorConfigService.getThresholdForType(indicator.tipoInsecto);
      
      await _sendNotification(
        id: notificationId,
        title: '🚨 Alerta Crítica: ${indicator.tipoInsecto}',
        body: 'Se detectaron ${indicator.cantidadHoy} ${indicator.tipoInsecto.toLowerCase()}. '
              'Umbral crítico: $threshold',
        priority: NotificationPriority.high,
      );
      
      _sentNotifications.add(notificationId);
    }
  }
  
  /// Verifica alertas generales del sistema
  static Future<void> _checkGeneralAlerts(InsectDashboardSummary summary) async {
    // Alerta por múltiples tipos en estado crítico
    final criticalCount = summary.indicadores
        .where((i) => i.nivelAlerta.nivel == 'critical')
        .length;
    
    if (criticalCount >= 3) {
      final notificationId = 'multiple_critical_${DateTime.now().day}';
      
      if (!_sentNotifications.contains(notificationId)) {
        await _sendNotification(
          id: notificationId,
          title: '⚠️ Múltiples Alertas Críticas',
          body: '$criticalCount tipos de insectos en estado crítico. Revisar inmediatamente.',
          priority: NotificationPriority.max,
        );
        
        _sentNotifications.add(notificationId);
      }
    }
    
    // Alerta por total de insectos muy alto
    if (summary.totalInsectosHoy > 100) {
      final notificationId = 'high_total_${DateTime.now().day}';
      
      if (!_sentNotifications.contains(notificationId)) {
        await _sendNotification(
          id: notificationId,
          title: '📊 Alto Nivel de Actividad',
          body: 'Total de insectos detectados: ${summary.totalInsectosHoy}',
          priority: NotificationPriority.default_,
        );
        
        _sentNotifications.add(notificationId);
      }
    }
  }
  
  /// Envía una notificación
  static Future<void> _sendNotification({
    required String id,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.default_,
  }) async {
    try {
      if (kIsWeb) {
        await _sendWebNotification(title, body);
      } else {
        // Para plataformas móviles, aquí se integraría con flutter_local_notifications
        debugPrint('Mobile notification: $title - $body');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
  
  /// Envía notificación web usando la API del navegador
  static Future<void> _sendWebNotification(String title, String body) async {
    if (kIsWeb) {
      try {
        // Simular notificación web - en implementación real se usaría JS interop
        debugPrint('Web Notification: $title - $body');
        
        // Vibración si está disponible
        HapticFeedback.heavyImpact();
      } catch (e) {
        debugPrint('Error sending web notification: $e');
      }
    }
  }
  
  /// Limpia las notificaciones enviadas (útil para testing)
  static void clearSentNotifications() {
    _sentNotifications.clear();
  }
  
  /// Obtiene estadísticas de notificaciones
  static Map<String, dynamic> getNotificationStats() {
    return {
      'isInitialized': _isInitialized,
      'sentToday': _sentNotifications.length,
      'lastNotifications': _sentNotifications.take(5).toList(),
    };
  }
  
  /// Envía una notificación de prueba
  static Future<void> sendTestNotification() async {
    await _sendNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: '🧪 Notificación de Prueba',
      body: 'El sistema de notificaciones está funcionando correctamente.',
      priority: NotificationPriority.default_,
    );
  }
}

/// Prioridades de notificación
enum NotificationPriority {
  min,
  low,
  default_,
  high,
  max,
}