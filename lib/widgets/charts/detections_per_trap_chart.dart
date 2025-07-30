import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class DetectionsPerTrapChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLegend;

  const DetectionsPerTrapChart({
    Key? key,
    this.days = 7,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  @override
  State<DetectionsPerTrapChart> createState() => _DetectionsPerTrapChartState();
}

class _DetectionsPerTrapChartState extends State<DetectionsPerTrapChart>
    with SingleTickerProviderStateMixin {
  List<StackedTrapData>? chartData;
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
  void didUpdateWidget(DetectionsPerTrapChart oldWidget) {
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
          await ChartDataService.fetchStackedTrapData(days: widget.days);

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
      title: 'Detecciones por Trampa y Tipo',
      subtitle: 'Últimos ${widget.days} días - Barras apiladas',
      height: widget.height ?? 350,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: Column(
        children: [
          // Información de trampa máxima
          _buildMaxTrapInfo(),
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
    final bool sinDetecciones = chartData == null ||
        chartData!.isEmpty ||
        chartData!.every((data) => data.totalTrap == 0);

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
              'No se registraron insectos en las trampas',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
            alignment: BarChartAlignment.spaceAround,
          groupsSpace: 32,
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
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData!.length) {
              final etiqueta = chartData![index].trapId;

              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Transform.rotate(
                  angle: -0.5, // -30 grados
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
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
              '$tipoActual\nTrampa ${data.trapId}\n$cantidad insectos',
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
        chartData!.map((e) => e.totalTrap).reduce((a, b) => a > b ? a : b);
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

  Widget _buildMaxTrapInfo() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final trampaMaxima = chartData!.reduce((a, b) => a.totalTrap > b.totalTrap ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Trampa máxima: ID ${trampaMaxima.trapId} con ${trampaMaxima.totalTrap} detecciones',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final totalGeneral = chartData!.fold(0, (sum, data) => sum + data.totalTrap);
    final promedioPorTrampa = totalGeneral / chartData!.length;
    final trampaMaxima =
        chartData!.reduce((a, b) => a.totalTrap > b.totalTrap ? a : b);

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
          label: 'Promedio/trampa',
          value: promedioPorTrampa.toStringAsFixed(1),
        ),
        ChartStatItem(
          label: 'Trampa máxima',
          value: '${trampaMaxima.totalTrap} (ID ${trampaMaxima.trapId})',
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