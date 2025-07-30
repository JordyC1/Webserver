import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class GroupedDetectionsChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLegend;

  const GroupedDetectionsChart({
    Key? key,
    this.days = 7,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  @override
  State<GroupedDetectionsChart> createState() => _GroupedDetectionsChartState();
}

class _GroupedDetectionsChartState extends State<GroupedDetectionsChart>
    with SingleTickerProviderStateMixin {
  List<GroupedDetectionData>? chartData;
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
  void didUpdateWidget(GroupedDetectionsChart oldWidget) {
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
          await ChartDataService.fetchGroupedDetectionData(days: widget.days);

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
      tiposUnicos.addAll(data.tiposInsectos);
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
      title: 'Detecciones por Trampa y Tipo de Insecto',
        subtitle: 'Últimos ${widget.days} ${widget.days == 1 ? 'horas' : 'días'} - Barras agrupadas por trampa',
      height: widget.height ?? 600, // Aumentado de 500 a 600 para más espacio del gráfico
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
          // Gráfico - Aumentado el espacio
          Expanded(
            flex: 5, // Aún más espacio para el gráfico
            child: _buildChart(),
          ),
        ],
      ),
      footer: _buildStats(),
    );
  }

  Widget _buildChart() {
    final bool sinDetecciones = chartData == null ||
        chartData!.isEmpty ||
        chartData!.every((data) => data.tiposPorCantidad.values
            .every((cantidad) => cantidad == 0));

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
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData!.length) {
              final trampaId = chartData![index].trampaId;

              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  'T$trampaId',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
          
          // Encontrar la trampa y tipo correspondiente al rod
          int currentRodIndex = 0;
          String? trampaActual;
          String? tipoActual;
          int? cantidadActual;
          
          for (String tipo in tiposOrdenados) {
            int cantidad = data.tiposPorCantidad[tipo] ?? 0;
            if (cantidad > 0) {
              if (currentRodIndex == rodIndex) {
                trampaActual = data.trampaId;
                tipoActual = tipo;
                cantidadActual = cantidad;
                break;
              }
              currentRodIndex++;
            }
          }
          
          if (trampaActual != null && tipoActual != null && cantidadActual != null) {
            return BarTooltipItem(
              '$tipoActual\nTrampa $trampaActual\n$cantidadActual insectos',
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
    
    double maxValue = 0;
    for (var data in chartData!) {
      for (String tipo in tiposOrdenados) {
        double cantidad = (data.tiposPorCantidad[tipo] ?? 0).toDouble();
        if (cantidad > maxValue) {
          maxValue = cantidad;
        }
      }
    }
    
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
    if (chartData == null || chartData!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular estadísticas
    Map<String, int> totalPorTipo = {};
    int totalGeneral = 0;
    String trampaMaxima = 'Ninguna';
    int maxCantidadTrampa = 0;
    
    for (var data in chartData!) {
      int totalTrampa = 0;
      for (String tipo in data.tiposInsectos) {
        int cantidad = data.tiposPorCantidad[tipo] ?? 0;
        totalPorTipo[tipo] = (totalPorTipo[tipo] ?? 0) + cantidad;
        totalGeneral += cantidad;
        totalTrampa += cantidad;
      }
      
      if (totalTrampa > maxCantidadTrampa) {
        maxCantidadTrampa = totalTrampa;
        trampaMaxima = 'T${data.trampaId}';
      }
    }

    String tipoMasComun = 'Ninguno';
    int maxCantidad = 0;
    for (var entry in totalPorTipo.entries) {
      if (entry.value > maxCantidad) {
        maxCantidad = entry.value;
        tipoMasComun = entry.key;
      }
    }

    double promedio = totalGeneral / (chartData!.length > 0 ? chartData!.length : 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalGeneral.toString(),
              Icons.analytics,
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Promedio/trampa',
              promedio.toStringAsFixed(1),
              Icons.trending_up,
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
             child: _buildStatCard(
               'Trampa máxima',
               '$trampaMaxima',
               Icons.location_on,
               const Color(0xFFFF9800),
             ),
           ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tipo más común',
              tipoMasComun,
              Icons.star,
              const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ChartIndicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;

  const ChartIndicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
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
            borderRadius: isSquare ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}