import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BaseChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String? errorMessage;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? footer;

  const BaseChartCard({
    Key? key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.trailing,
    this.onRefresh,
    this.isLoading = false,
    this.errorMessage,
    this.height,
    this.padding,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título, subtítulo y botón de actualizar
            _buildHeader(context),

            // Espacio entre header y contenido
            const SizedBox(height: 16),

            // Contenido principal (gráfica, loading o error)
            Expanded(
              child: _buildContent(context),
            ),

            // Footer opcional
            if (footer != null) ...[
              const SizedBox(height: 16),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              // Subtítulo opcional
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Trailing widget (ej: botón de opciones)
        if (trailing != null) trailing!,

        // Botón de refresh
        if (onRefresh != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isLoading ? AppTheme.textSecondary : AppTheme.primaryBlue,
            ),
            onPressed: isLoading ? null : onRefresh,
            tooltip: 'Actualizar datos',
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    // Mostrar error si existe
    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    // Mostrar loading si está cargando
    if (isLoading) {
      return _buildLoadingState(context);
    }

    // Mostrar gráfica
    return chart;
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando datos...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onRefresh != null)
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ✨ Widget auxiliar para mostrar estadísticas del gráfico
class ChartStats extends StatelessWidget {
  final List<ChartStatItem> stats;
  final EdgeInsets? padding;

  const ChartStats({
    Key? key,
    required this.stats,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => Expanded(child: stat)).toList(),
      ),
    );
  }
}

// 📊 Widget para un item individual de estadísticas
class ChartStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double? fontSize;

  const ChartStatItem({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: (fontSize ?? 14) - 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// 🔴 Widget indicador para leyendas
class ChartIndicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  const ChartIndicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = true,
    this.size = 16,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            borderRadius: isSquare ? BorderRadius.circular(3) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: textColor ?? AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
