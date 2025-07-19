import 'package:flutter/material.dart';
import 'package:aplicacionweb/theme/app_theme.dart';
class PlagaAlertCard extends StatelessWidget {
  final String mensaje;
  final String severidad;
  final DateTime fecha; // ✅ Nueva propiedad

  const PlagaAlertCard({
    super.key,
    required this.mensaje,
    required this.severidad,
    required this.fecha,
  });

  Color _getBackgroundColor() {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Colors.red.withOpacity(0.15);
      case 'media':
        return Colors.orange.withOpacity(0.15);
      case 'baja':
        return Colors.yellow.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  IconData _getIcon() {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Icons.dangerous;
      case 'media':
        return Icons.warning;
      case 'baja':
        return Icons.info_outline;
      default:
        return Icons.bug_report;
    }
  }

  Color _getBorderColor() {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'media':
        return Colors.orangeAccent;
      case 'baja':
        return Colors.yellow.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha() {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border.all(color: _getBorderColor(), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIcon(), color: _getBorderColor(), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detectada: ${_formatFecha()}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
