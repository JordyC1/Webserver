import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class StackedBarChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLegend;

  const StackedBarChart({
    Key? key,
    this.days = 7,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  @override
  State<StackedBarChart> createState() => _StackedBarChartState();
}

class _StackedBarChartState extends State<StackedBarChart>
    with SingleTickerProviderStateMixin {
  List<StackedBarData>? chartData;
  bool isLoading = true;
  String? errorMessage;
  List<String> tiposOrdenados = [];
  Map<String, Color> coloresPorTipo = {};
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StackedBarChart oldWidget) {
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
          await ChartDataService.fetchStackedBarData(days: widget.days);

      if (response.success && response.data != null) {
        setState(() {
          chartData = response.data!;
          _processChartData();
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

  void _processChartData() {
    if (chartData == null || chartData!.isEmpty) return;

    // Extraer todos los tipos únicos y crear colores
    Set<String> tiposUnicos = {};
    for (var data in chartData!) {
      tiposUnicos.addAll(data.insectosPorTipo.keys);
    }

    tiposOrdenados = tiposUnicos.toList()..sort();

    // Asignar colores a cada tipo
    List<Color> coloresDisponibles = [
      const Color(0xFF2796F4), // Azul
      const Color(0xFFF44336), // Rojo
      const Color(0xFF4CAF50), // Verde
      const Color(0xFFFF9800), // Naranja
      const Color(0xFF9C27B0), // Púrpura
      const Color(0xFF009688), // Teal
      const Color(0xFFFFEB3B), // Amarillo
      const Color(0xFFE91E63), // Pink
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];

    coloresPorTipo.clear();
    for (int i = 0; i < tiposOrdenados.length; i++) {
      coloresPorTipo[tiposOrdenados[i]] =
          coloresDisponibles[i % coloresDisponibles.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Detecciones por Tipo por Día',
      subtitle: 'Últimos ${widget.days} días - Barras apiladas',
      height: widget.height ?? 350,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: Column(
        children: [
          // Leyenda superior
          if (widget.showLegend && tiposOrdenados.isNotEmpty) ...[
            _buildTopLegend(),
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
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: _buildBarGroups(),
            gridData: _buildGridData(),
            titlesData: _buildTitlesData(),
            borderData: _buildBorderData(),
            barTouchData: _buildTouchData(),
            maxY: _getMaxY(),
            minY: 0,
          ),
          swapAnimationDuration: const Duration(milliseconds: 600),
          swapAnimationCurve: Curves.easeInOutQuint,
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return chartData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return data.toBarChartGroup(index, tiposOrdenados, coloresPorTipo);
    }).toList();
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      drawHorizontalLine: true,
      horizontalInterval: _getMaxY() / 5,
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

  BarTouchData _buildTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: AppTheme.cardBackground,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final data = chartData![group.x.toInt()];

          // Encontrar el tipo correspondiente al rod
          String? tipoActual;
          double currentY = 0;
          for (String tipo in tiposOrdenados) {
            int cantidad = data.insectosPorTipo[tipo] ?? 0;
            if (cantidad > 0) {
              if (rod.fromY == currentY && rod.toY == currentY + cantidad) {
                tipoActual = tipo;
                break;
              }
              currentY += cantidad;
            }
          }

          if (tipoActual != null) {
            final cantidad = data.insectosPorTipo[tipoActual] ?? 0;
            return BarTooltipItem(
              '$tipoActual\n${data.fechaFormateada}\n$cantidad insectos',
              TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            );
          }

          return null;
        },
      ),
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        // Aquí podríamos agregar lógica adicional para el toque
      },
      handleBuiltInTouches: true,
    );
  }

  double _getMaxY() {
    if (chartData == null || chartData!.isEmpty) return 10;
    final maxValue =
        chartData!.map((e) => e.totalDia).reduce((a, b) => a > b ? a : b);
    return (maxValue + (maxValue * 0.1)).clamp(1, double.infinity);
  }

  Widget _buildTopLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: tiposOrdenados.map((tipo) {
          return ChartIndicator(
            color: coloresPorTipo[tipo] ?? AppTheme.primaryBlue,
            text: tipo,
            isSquare: true,
            size: 14,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final totalGeneral = chartData!.fold(0, (sum, data) => sum + data.totalDia);
    final promedioDiario = totalGeneral / chartData!.length;
    final diaMaximo =
        chartData!.reduce((a, b) => a.totalDia > b.totalDia ? a : b);

    // Calcular tipo más común
    Map<String, int> totalPorTipo = {};
    for (var data in chartData!) {
      data.insectosPorTipo.forEach((tipo, cantidad) {
        totalPorTipo[tipo] = (totalPorTipo[tipo] ?? 0) + cantidad;
      });
    }

    String tipoMasComun = 'N/A';
    if (totalPorTipo.isNotEmpty) {
      tipoMasComun =
          totalPorTipo.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total',
          value: totalGeneral.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Promedio/día',
          value: promedioDiario.toStringAsFixed(1),
        ),
        ChartStatItem(
          label: 'Día máximo',
          value: '${diaMaximo.totalDia} (${diaMaximo.fechaFormateada})',
        ),
        ChartStatItem(
          label: 'Tipo más común',
          value: tipoMasComun,
          valueColor: coloresPorTipo[tipoMasComun],
        ),
      ],
    );
  }
}
