import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class AlertsSeverityChart extends StatefulWidget {
  final double? height;
  final bool showLegend;

  const AlertsSeverityChart({
    Key? key,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  @override
  State<AlertsSeverityChart> createState() => _AlertsSeverityChartState();
}

class _AlertsSeverityChartState extends State<AlertsSeverityChart>
    with SingleTickerProviderStateMixin {
  List<AlertSeverityData>? chartData;
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
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ChartDataService.fetchAlertsBySeverity();

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
      title: 'Alertas por Severidad',
      subtitle: 'Estado actual del sistema',
      height: widget.height ?? 280,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: Column(
        children: [
          // Leyenda superior
          if (widget.showLegend &&
              chartData != null &&
              chartData!.isNotEmpty) ...[
            _buildLegend(),
            const SizedBox(height: 16),
          ],
          // Gráfico
          Expanded(child: _buildChart()),
        ],
      ),
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
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin alertas activas',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Todo funciona correctamente',
              style: TextStyle(
                color: AppTheme.textSecondary,
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
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            barGroups: _buildBarGroups(),
            gridData: _buildGridData(),
            titlesData: _buildTitlesData(),
            borderData: _buildBorderData(),
            barTouchData: _buildTouchData(),
            maxY: _getMaxY(),
            minY: 0,
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeInOutQuart,
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return chartData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.cantidad.toDouble() * _animation.value,
            color: data._getSeverityColor(),
            width: 50,
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: AppTheme.textSecondary.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      drawHorizontalLine: true,
      horizontalInterval: _getMaxY() / 4,
      getDrawingHorizontalLine: (value) {
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
          interval: _getMaxY() / 4,
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
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData!.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  chartData![index].severidadCapitalizada,
                  style: TextStyle(
                    color: chartData![index]._getSeverityColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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

  BarTouchData _buildTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: AppTheme.cardBackground,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final data = chartData![group.x.toInt()];

          return BarTooltipItem(
            'Severidad ${data.severidadCapitalizada}\n${data.cantidad} ${data.cantidad == 1 ? 'alerta' : 'alertas'}',
            TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        // Aquí podríamos agregar lógica adicional para el toque
      },
      handleBuiltInTouches: true,
    );
  }

  double _getMaxY() {
    if (chartData == null || chartData!.isEmpty) return 5;
    final maxValue =
        chartData!.map((e) => e.cantidad).reduce((a, b) => a > b ? a : b);
    return (maxValue + 1).clamp(1, double.infinity).toDouble();
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: chartData!.map((data) {
          return ChartIndicator(
            color: data._getSeverityColor(),
            text: '${data.severidadCapitalizada}: ${data.cantidad}',
            isSquare: true,
            size: 16,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) {
      return ChartStats(
        stats: [
          ChartStatItem(
            label: 'Estado',
            value: 'Óptimo',
            valueColor: Colors.green,
          ),
          ChartStatItem(
            label: 'Total Alertas',
            value: '0',
          ),
          ChartStatItem(
            label: 'Críticas',
            value: '0',
            valueColor: Colors.green,
          ),
        ],
      );
    }

    final totalAlertas = chartData!.fold(0, (sum, data) => sum + data.cantidad);
    final alertasAltas = chartData!
        .where((data) => data.severidad == 'alta')
        .fold(0, (sum, data) => sum + data.cantidad);

    String estadoGeneral = 'Bueno';
    Color colorEstado = Colors.green;

    if (alertasAltas > 0) {
      estadoGeneral = 'Crítico';
      colorEstado = Colors.red;
    } else if (totalAlertas > 3) {
      estadoGeneral = 'Atención';
      colorEstado = Colors.orange;
    }

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Estado',
          value: estadoGeneral,
          valueColor: colorEstado,
        ),
        ChartStatItem(
          label: 'Total',
          value: totalAlertas.toString(),
          valueColor: totalAlertas > 0 ? Colors.orange : AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Críticas',
          value: alertasAltas.toString(),
          valueColor: alertasAltas > 0 ? Colors.red : Colors.green,
        ),
      ],
    );
  }
}

// Extensión para acceder al método _getSeverityColor
extension AlertSeverityDataExtension on AlertSeverityData {
  Color _getSeverityColor() {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return const Color(0xFFF44336); // Rojo
      case 'media':
        return const Color(0xFFFF9800); // Naranja
      case 'baja':
        return const Color(0xFFFFEB3B); // Amarillo
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }
}
