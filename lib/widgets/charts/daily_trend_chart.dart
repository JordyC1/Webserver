import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class DailyTrendChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showAverage;

  const DailyTrendChart({
    Key? key,
    this.days = 14,
    this.height,
    this.showAverage = true,
  }) : super(key: key);

  @override
  State<DailyTrendChart> createState() => _DailyTrendChartState();
}

class _DailyTrendChartState extends State<DailyTrendChart>
    with SingleTickerProviderStateMixin {
  List<DailyTrendPoint>? chartData;
  bool isLoading = true;
  String? errorMessage;
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
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DailyTrendChart oldWidget) {
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
          await ChartDataService.fetchDailyTrendData(days: widget.days);

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
      title: 'Tendencia Diaria de Insectos',
      subtitle: 'Últimos ${widget.days} días',
      height: widget.height ?? 300,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: _buildChart(),
      footer: _buildStats(),
    );
  }

  Widget _buildChart() {
    if (chartData == null || chartData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report_outlined,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron detecciones\nen el período seleccionado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 📊 Verificar si todos los valores son cero
    final hasAnyDetections = chartData!.any((point) => point.totalInsectos > 0);

    if (!hasAnyDetections) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin detecciones',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se registraron insectos\nen los últimos ${widget.days} días',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: _buildGridData(),
            titlesData: _buildTitlesData(),
            borderData: _buildBorderData(),
            lineBarsData: _buildLineBarsData(),
            lineTouchData: _buildTouchData(),
            minX: 0,
            maxX: (chartData!.length - 1).toDouble(),
            minY: _getMinY(),
            maxY: _getMaxY(),
            clipData: FlClipData.all(),
          ),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      horizontalInterval: (_getMaxY() - _getMinY()) / 4,
      verticalInterval: chartData!.length > 7 ? 2 : 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppTheme.textSecondary.withOpacity(0.2),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppTheme.textSecondary.withOpacity(0.2),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: (_getMaxY() - _getMinY()) / 4,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 25,
          interval: chartData!.length > 7 ? 2 : 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData!.length) {
              return Text(
                chartData![index].fechaFormateada,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: AppTheme.textSecondary.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final spots = chartData!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalInsectos.toDouble());
    }).toList();

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: AppTheme.primaryBlue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: AppTheme.primaryBlue,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppTheme.primaryBlue.withOpacity(0.1),
        ),
        aboveBarData: BarAreaData(show: false),
      ),
    ];
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: AppTheme.cardBackground,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            if (index >= 0 && index < chartData!.length) {
              final data = chartData![index];
              return LineTooltipItem(
                '${data.fechaFormateada}\n${data.totalInsectos} insectos',
                TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }
            return null;
          }).toList();
        },
      ),
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        // Aquí podríamos agregar lógica adicional para el toque
      },
      handleBuiltInTouches: true,
    );
  }

  double _getMinY() {
    if (chartData == null || chartData!.isEmpty) return 0;

    final hasAnyDetections = chartData!.any((point) => point.totalInsectos > 0);
    if (!hasAnyDetections) return 0;

    final minValue =
        chartData!.map((e) => e.totalInsectos).reduce((a, b) => a < b ? a : b);
    return (minValue - (minValue * 0.1)).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (chartData == null || chartData!.isEmpty) return 10;

    final hasAnyDetections = chartData!.any((point) => point.totalInsectos > 0);
    if (!hasAnyDetections) return 10; // Valor mínimo para mostrar grid

    final maxValue =
        chartData!.map((e) => e.totalInsectos).reduce((a, b) => a > b ? a : b);

    // Asegurar que siempre hay un rango mínimo visible
    final adjustedMax = maxValue + (maxValue * 0.1);
    return adjustedMax < 1 ? 10 : adjustedMax;
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final total = chartData!.fold(0, (sum, point) => sum + point.totalInsectos);

    // 📊 Manejar caso cuando no hay detecciones
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  '0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
            Column(
              children: [
                Text(
                  '0.0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Promedio',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
            Column(
              children: [
                Text(
                  'N/A',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pico',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final average = total / chartData!.length;
    final maxValue =
        chartData!.map((e) => e.totalInsectos).reduce((a, b) => a > b ? a : b);
    final maxDay = chartData!.firstWhere((e) => e.totalInsectos == maxValue);

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total',
          value: total.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Promedio',
          value: average.toStringAsFixed(1),
        ),
        ChartStatItem(
          label: 'Máximo',
          value: '$maxValue (${maxDay.fechaFormateada})',
          valueColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }
}
