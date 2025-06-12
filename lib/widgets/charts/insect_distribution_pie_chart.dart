import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class InsectDistributionPieChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLegend;

  const InsectDistributionPieChart({
    Key? key,
    this.days = 30,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  @override
  State<InsectDistributionPieChart> createState() =>
      _InsectDistributionPieChartState();
}

class _InsectDistributionPieChartState extends State<InsectDistributionPieChart>
    with SingleTickerProviderStateMixin {
  List<InsectTypeData>? chartData;
  bool isLoading = true;
  String? errorMessage;
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InsectDistributionPieChart oldWidget) {
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
          await ChartDataService.fetchInsectTypeDistribution(days: widget.days);

      if (response.success && response.data != null) {
        setState(() {
          chartData = response.data!;
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
      title: 'Distribución por Tipo de Insecto',
      subtitle: 'Últimos ${widget.days} días',
      height: widget.height ?? 320,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: _buildChart(),
      footer: widget.showLegend ? _buildLegend() : null,
    );
  }

  Widget _buildChart() {
    if (chartData == null || chartData!.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Solo mostrar el gráfico de pastel sin leyenda lateral
        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sections: _buildSections(),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback:
                      (FlTouchEvent event, PieTouchResponse? response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.touchedSection != null) {
                      setState(() {
                        touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    }
                  },
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
              swapAnimationCurve: Curves.easeInOutQuint,
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections() {
    return chartData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isSelected = index == touchedIndex;

      return data.toPieChartSection(isSelected);
    }).toList();
  }

  Widget _buildSideLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: chartData!.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isSelected = index == touchedIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              touchedIndex = isSelected ? -1 : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: data._getColorFromString(data.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.tipo,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${data.cantidad} (${data.porcentaje.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: chartData!.map((data) {
          return ChartIndicator(
            color: data._getColorFromString(data.color),
            text: '${data.tipo}: ${data.porcentaje.toStringAsFixed(1)}%',
            isSquare: false,
            size: 12,
          );
        }).toList(),
      ),
    );
  }
}

// Extensión para acceder al método privado _getColorFromString
extension InsectTypeDataExtension on InsectTypeData {
  Color _getColorFromString(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'blue':
        return const Color(0xFF2796F4);
      case 'red':
        return const Color(0xFFF44336);
      case 'green':
        return const Color(0xFF4CAF50);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'teal':
        return const Color(0xFF009688);
      case 'yellow':
        return const Color(0xFFFFEB3B);
      default:
        return const Color(0xFF2796F4);
    }
  }
}
