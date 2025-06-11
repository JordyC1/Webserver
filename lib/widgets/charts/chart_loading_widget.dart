import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChartLoadingWidget extends StatelessWidget {
  final String? message;
  final bool showProgress;
  final double? progress;

  const ChartLoadingWidget({
    Key? key,
    this.message,
    this.showProgress = true,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de progreso
          _buildProgressIndicator(),

          const SizedBox(height: 20),

          // Mensaje de carga
          Text(
            message ?? 'Cargando datos...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          // Texto adicional
          Text(
            'Por favor espere un momento',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (progress != null) {
      // Indicador de progreso determinístico
      return SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
        ),
      );
    } else if (showProgress) {
      // Indicador de progreso indeterminístico
      return SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    } else {
      // Solo un ícono de carga
      return Icon(
        Icons.hourglass_empty,
        size: 48,
        color: AppTheme.primaryBlue,
      );
    }
  }
}

// Widget para skeleton loading (placeholder mientras carga)
class ChartSkeletonLoader extends StatefulWidget {
  final ChartType chartType;
  final double? height;

  const ChartSkeletonLoader({
    Key? key,
    required this.chartType,
    this.height,
  }) : super(key: key);

  @override
  State<ChartSkeletonLoader> createState() => _ChartSkeletonLoaderState();
}

class _ChartSkeletonLoaderState extends State<ChartSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _buildSkeletonForChartType();
        },
      ),
    );
  }

  Widget _buildSkeletonForChartType() {
    switch (widget.chartType) {
      case ChartType.line:
        return _buildLineChartSkeleton();
      case ChartType.bar:
        return _buildBarChartSkeleton();
      case ChartType.pie:
        return _buildPieChartSkeleton();
      case ChartType.area:
        return _buildAreaChartSkeleton();
      case ChartType.heatmap:
        return _buildHeatmapSkeleton();
      default:
        return _buildGenericSkeleton();
    }
  }

  Widget _buildLineChartSkeleton() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 80 + (index * 20).toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _getSkeletonColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 30,
                      decoration: BoxDecoration(
                        color: _getSkeletonColor(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSkeleton() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 60 + (index * 30).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _getSkeletonColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSkeleton() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getSkeletonColor(),
        ),
      ),
    );
  }

  Widget _buildAreaChartSkeleton() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getSkeletonColor(),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapSkeleton() {
    return Column(
      children: List.generate(7, (row) {
        return Expanded(
          child: Row(
            children: List.generate(24, (col) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: _getSkeletonColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildGenericSkeleton() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _getSkeletonColor(),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _getSkeletonColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getSkeletonColor() {
    final baseColor = AppTheme.textSecondary.withOpacity(0.1);
    final highlightColor = AppTheme.textSecondary.withOpacity(0.2);
    return Color.lerp(baseColor, highlightColor, _animation.value)!;
  }
}

enum ChartType {
  line,
  bar,
  pie,
  area,
  heatmap,
  generic,
}

// Widget para mostrar estado de "sin datos"
class ChartNoDataWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ChartNoDataWidget({
    Key? key,
    this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No hay datos disponibles',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar el rango de fechas o actualizar los datos',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
