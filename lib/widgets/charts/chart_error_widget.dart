import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChartErrorWidget extends StatelessWidget {
  final String? message;
  final ChartErrorType errorType;
  final VoidCallback? onRetry;
  final String? details;

  const ChartErrorWidget({
    Key? key,
    this.message,
    this.errorType = ChartErrorType.generic,
    this.onRetry,
    this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono según el tipo de error
            _buildErrorIcon(),

            const SizedBox(height: 16),

            // Título del error
            Text(
              _getErrorTitle(),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Mensaje del error
            Text(
              message ?? _getDefaultErrorMessage(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            // Detalles adicionales si existen
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles del error:',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details!,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botones de acción
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor;

    switch (errorType) {
      case ChartErrorType.network:
        iconData = Icons.wifi_off;
        iconColor = Colors.orange;
        break;
      case ChartErrorType.server:
        iconData = Icons.cloud_off;
        iconColor = Colors.red;
        break;
      case ChartErrorType.timeout:
        iconData = Icons.timer_off;
        iconColor = Colors.amber;
        break;
      case ChartErrorType.parsing:
        iconData = Icons.error_outline;
        iconColor = Colors.purple;
        break;
      case ChartErrorType.noPermission:
        iconData = Icons.block;
        iconColor = Colors.red;
        break;
      case ChartErrorType.generic:
      default:
        iconData = Icons.error_outline;
        iconColor = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(0.1),
      ),
      child: Icon(
        iconData,
        size: 48,
        color: iconColor,
      ),
    );
  }

  String _getErrorTitle() {
    switch (errorType) {
      case ChartErrorType.network:
        return 'Sin conexión';
      case ChartErrorType.server:
        return 'Error del servidor';
      case ChartErrorType.timeout:
        return 'Tiempo agotado';
      case ChartErrorType.parsing:
        return 'Error de datos';
      case ChartErrorType.noPermission:
        return 'Sin permisos';
      case ChartErrorType.generic:
      default:
        return 'Error al cargar datos';
    }
  }

  String _getDefaultErrorMessage() {
    switch (errorType) {
      case ChartErrorType.network:
        return 'Verifica tu conexión a internet e intenta nuevamente.';
      case ChartErrorType.server:
        return 'El servidor no está disponible. Intenta más tarde.';
      case ChartErrorType.timeout:
        return 'La solicitud tardó demasiado en responder.';
      case ChartErrorType.parsing:
        return 'Los datos recibidos no tienen el formato esperado.';
      case ChartErrorType.noPermission:
        return 'No tienes permisos para acceder a estos datos.';
      case ChartErrorType.generic:
      default:
        return 'Ocurrió un error inesperado al cargar los datos.';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de reintentar (siempre disponible si hay callback)
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

        // Botón adicional según el tipo de error
        if (_shouldShowAdditionalButton()) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _getAdditionalButtonAction(),
            icon: Icon(_getAdditionalButtonIcon()),
            label: Text(_getAdditionalButtonLabel()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldShowAdditionalButton() {
    return errorType == ChartErrorType.network ||
        errorType == ChartErrorType.server ||
        errorType == ChartErrorType.noPermission;
  }

  IconData _getAdditionalButtonIcon() {
    switch (errorType) {
      case ChartErrorType.network:
        return Icons.settings;
      case ChartErrorType.server:
        return Icons.info_outline;
      case ChartErrorType.noPermission:
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }

  String _getAdditionalButtonLabel() {
    switch (errorType) {
      case ChartErrorType.network:
        return 'Configurar';
      case ChartErrorType.server:
        return 'Más info';
      case ChartErrorType.noPermission:
        return 'Permisos';
      default:
        return 'Ayuda';
    }
  }

  VoidCallback? _getAdditionalButtonAction() {
    // Por ahora retorna null, pero se pueden implementar acciones específicas
    // como abrir configuraciones, mostrar más información, etc.
    return null;
  }
}

enum ChartErrorType {
  generic, // Error genérico
  network, // Sin conexión a internet
  server, // Error del servidor (500, 503, etc.)
  timeout, // Timeout de la solicitud
  parsing, // Error al parsear los datos JSON
  noPermission, // Sin permisos para acceder
}

// Widget para errores específicos de gráficas fl_chart
class FlChartErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const FlChartErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Error en la gráfica',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La gráfica no se pudo renderizar correctamente',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget de error mínimo para espacios pequeños
class ChartMiniErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onTap;

  const ChartMiniErrorWidget({
    Key? key,
    this.message,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message ?? 'Error',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
