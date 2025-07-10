import 'package:flutter/material.dart';
import '../../models/chart_models.dart';
import '../../theme/app_theme.dart';

/// Widget de tarjeta de resumen general de insectos
class InsectsSummaryCard extends StatelessWidget {
  final InsectDashboardSummary summary;
  final double? height;
  final String? currentPeriodLabel;
  final String? previousPeriodLabel;

  const InsectsSummaryCard({
    super.key,
    required this.summary,
    this.height,
    this.currentPeriodLabel,
    this.previousPeriodLabel,
  });

  /// Construye la sección de total de insectos
  Widget _buildTotalInsects() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Insectos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.totalInsectosHoy.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de alertas activas
  Widget _buildActiveAlerts() {
    Color alertColor;
    IconData alertIcon;
    String statusText;

    if (summary.totalAlertasActivas == 0) {
      alertColor = const Color(0xFF4CAF50); // Verde
      alertIcon = Icons.check_circle;
      statusText = 'Todo Normal';
    } else if (summary.totalAlertasActivas <= 3) {
      alertColor = const Color(0xFFFF9800); // Naranja
      alertIcon = Icons.warning;
      statusText = 'Atención';
    } else {
      alertColor = const Color(0xFFF44336); // Rojo
      alertIcon = Icons.error;
      statusText = 'Crítico';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alertIcon,
                color: alertColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertas Activas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                summary.totalAlertasActivas.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: alertColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la sección de última actualización
  Widget _buildLastUpdate() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Última actualización: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            summary.ultimaActualizacionFormateada,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye las estadísticas rápidas
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Tipos',
                summary.indicadores.length.toString(),
                Icons.category,
                const Color(0xFF9C27B0),
              ),
              _buildStatItem(
                'Críticos',
                summary.indicadoresCriticos.toString(),
                Icons.priority_high,
                const Color(0xFFF44336),
              ),
              _buildStatItem(
                'Normales',
                summary.indicadoresNormales.toString(),
                Icons.check_circle_outline,
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye un elemento de estadística individual
  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título de la tarjeta con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen de Insectos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fila principal con totales
            Row(
              children: [
                Expanded(child: _buildTotalInsects()),
                const SizedBox(width: 16),
                Expanded(child: _buildActiveAlerts()),
              ],
            ),
            const SizedBox(height: 20),

            // Estadísticas rápidas
            _buildQuickStats(),
            const SizedBox(height: 16),

            // Última actualización
            _buildLastUpdate(),
          ],
        ),
      ),
    );
  }
}
