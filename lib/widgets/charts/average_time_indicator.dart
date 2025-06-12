import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart' as models;
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class AverageTimeIndicator extends StatefulWidget {
  final int days;
  final double? height;
  final bool showDetails;

  const AverageTimeIndicator({
    Key? key,
    this.days = 7,
    this.height,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<AverageTimeIndicator> createState() => _AverageTimeIndicatorState();
}

class _AverageTimeIndicatorState extends State<AverageTimeIndicator>
    with SingleTickerProviderStateMixin {
  models.AverageTimeIndicator? indicatorData;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AverageTimeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response =
          await ChartDataService.calculateAverageTimeBetweenDetections(
        days: widget.days,
      );

      if (response.success && response.data != null) {
        setState(() {
          indicatorData = response.data!;
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = response.error ?? 'Error desconocido';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar datos: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Tiempo Promedio entre Detecciones',
      subtitle: 'Últimos ${widget.days} días',
      height: widget.height ?? 180,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: _buildIndicator(),
      footer: widget.showDetails ? _buildDetails() : null,
    );
  }

  Widget _buildIndicator() {
    if (indicatorData == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tiempo principal
              Text(
                indicatorData!.tiempoFormateado,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: indicatorData!.colorEstado,
                ),
              ),

              const SizedBox(height: 8),

              // Estado textual
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: indicatorData!.colorEstado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getEstadoTexto(indicatorData!.estado),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: indicatorData!.colorEstado,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel de Frecuencia',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: LinearProgressIndicator(
                        value: indicatorData!.porcentajeIndicador *
                            _progressAnimation.value,
                        backgroundColor:
                            AppTheme.textSecondary.withOpacity(0.2),
                        color: indicatorData!.colorEstado,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Escala de referencia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Más frecuente',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Menos frecuente',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetails() {
    if (indicatorData == null) return const SizedBox.shrink();

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total Detecciones',
          value: indicatorData!.totalDetecciones.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Estado',
          value: _getEstadoTexto(indicatorData!.estado),
          valueColor: indicatorData!.colorEstado,
        ),
        ChartStatItem(
          label: 'Frecuencia',
          value:
              '${(indicatorData!.porcentajeIndicador * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'bueno':
        return 'Excelente';
      case 'regular':
        return 'Moderado';
      case 'malo':
        return 'Escaso';
      default:
        return 'Desconocido';
    }
  }
}
