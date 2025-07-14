import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class WeeklyCumulativeAreaChart extends StatefulWidget {
  final double? height;
  final bool showDailyValues;
  final int days;

  const WeeklyCumulativeAreaChart({
    Key? key,
    this.height,
    this.showDailyValues = true,
    this.days = 7,
  }) : super(key: key);

  @override
  State<WeeklyCumulativeAreaChart> createState() =>
      _WeeklyCumulativeAreaChartState();
}

class _WeeklyCumulativeAreaChartState extends State<WeeklyCumulativeAreaChart>
    with SingleTickerProviderStateMixin {
  List<WeeklyCumulativeData>? chartData;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutSine),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeeklyCumulativeAreaChart oldWidget) {
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
          await ChartDataService.fetchWeeklyCumulativeData(days: widget.days);

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
    String titulo = widget.days == 1
        ? 'Acumulación de Detecciones del Día'
        : widget.days == 7
            ? 'Acumulación Semanal de Detecciones'
            : 'Acumulación de Detecciones de ${widget.days} Días';

    String subtitulo =
        widget.days == 1 ? 'Progreso horario del día' : 'Progreso día a día';

    return BaseChartCard(
      title: titulo,
      subtitle: subtitulo,
      height: widget.height ?? 320,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: _buildChart(),
      footer: _buildStats(),
    );
  }

  Widget _buildChart() {
    final bool sinDetecciones = chartData == null ||
        chartData!.isEmpty ||
        chartData!.every((data) =>
            data.cantidadAcumulada == 0 && data.cantidadDiaria == 0);

    if (sinDetecciones) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Sin detecciones',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'No se registraron insectos en el período seleccionado',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
            minY: 0,
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
      horizontalInterval: _getMaxY() / 5,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppTheme.textSecondary.withOpacity(0.2),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppTheme.textSecondary.withOpacity(0.1),
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
          reservedSize: 45,
          interval: _getMaxY() / 5,
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
          interval: 1,
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
    // Crear puntos para la línea acumulativa con animación
    final cumulativeSpots = chartData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final animatedValue = data.cantidadAcumulada * _animation.value;
      return FlSpot(index.toDouble(), animatedValue);
    }).toList();

    return [
      // Línea acumulativa principal con área
      LineChartBarData(
        spots: cumulativeSpots,
        isCurved: true,
        curveSmoothness: 0.4,
        color: AppTheme.primaryBlue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 5,
              color: AppTheme.primaryBlue,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.4),
              AppTheme.primaryBlue.withOpacity(0.1),
              AppTheme.primaryBlue.withOpacity(0.02),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        aboveBarData: BarAreaData(show: false),
      ),

      // Línea de valores diarios (opcional)
      if (widget.showDailyValues) ..._buildDailyBarsData(),
    ];
  }

  List<LineChartBarData> _buildDailyBarsData() {
    final dailySpots = chartData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final animatedValue = data.cantidadDiaria * _animation.value;
      return FlSpot(index.toDouble(), animatedValue);
    }).toList();

    return [
      LineChartBarData(
        spots: dailySpots,
        isCurved: false,
        color: AppTheme.primaryBlue.withOpacity(0.6),
        barWidth: 2,
        isStrokeCapRound: true,
        dashArray: [4, 4], // Línea discontinua
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: AppTheme.primaryBlue.withOpacity(0.7),
              strokeWidth: 1,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
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
              final isDaily = spot.barIndex == 1; // Segunda línea es la diaria

              if (isDaily) {
                return LineTooltipItem(
                  '${data.fechaFormateada}\nDiario: ${data.cantidadDiaria}',
                  TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              } else {
                return LineTooltipItem(
                  '${data.fechaFormateada}\nAcumulado: ${data.cantidadAcumulada}\nDiario: ${data.cantidadDiaria}',
                  TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
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

  double _getMaxY() {
    if (chartData == null || chartData!.isEmpty) return 10;

    final maxCumulative = chartData!
        .map((e) => e.cantidadAcumulada)
        .reduce((a, b) => a > b ? a : b);
    final maxDaily = widget.showDailyValues
        ? chartData!
            .map((e) => e.cantidadDiaria)
            .reduce((a, b) => a > b ? a : b)
        : 0;

    final maxValue = maxCumulative > maxDaily ? maxCumulative : maxDaily;
    return (maxValue + (maxValue * 0.1)).clamp(1, double.infinity);
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final totalAcumulado = chartData!.last.cantidadAcumulada;
    final promedioDiario = totalAcumulado / chartData!.length;
    final mejorDia = chartData!
        .reduce((a, b) => a.cantidadDiaria > b.cantidadDiaria ? a : b);
    final tendencia = _calculateTendencia();

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total Semanal',
          value: totalAcumulado.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Promedio/día',
          value: promedioDiario.toStringAsFixed(1),
        ),
        ChartStatItem(
          label: 'Mejor día',
          value: '${mejorDia.cantidadDiaria} (${mejorDia.fechaFormateada})',
        ),
        ChartStatItem(
          label: 'Tendencia',
          value: tendencia['texto'],
          valueColor: tendencia['color'],
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateTendencia() {
    if (chartData == null || chartData!.length < 3) {
      return {'texto': 'N/A', 'color': AppTheme.textSecondary};
    }

    // Comparar los últimos 3 días vs los primeros 3 días
    final primerosTres = chartData!
            .take(3)
            .map((e) => e.cantidadDiaria)
            .reduce((a, b) => a + b) /
        3;
    final ultimosTres = chartData!
            .skip(chartData!.length - 3)
            .map((e) => e.cantidadDiaria)
            .reduce((a, b) => a + b) /
        3;

    final diferencia = ultimosTres - primerosTres;

    if (diferencia > 2) {
      return {'texto': '↗ Creciente', 'color': Colors.red};
    } else if (diferencia < -2) {
      return {'texto': '↘ Decreciente', 'color': Colors.green};
    } else {
      return {'texto': '→ Estable', 'color': Colors.orange};
    }
  }
}