import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class WeeklyTrendByTypeChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLegend;

  const WeeklyTrendByTypeChart({
    Key? key,
    this.days = 7,
    this.height,
    this.showLegend = true,
  }) : super(key: key);

  // Métodos para obtener títulos dinámicos
  String getTitle() {
    switch (days) {
      case 1:
        return 'Tendencia Horaria por Tipo de Insecto';
      case 7:
        return 'Tendencia Semanal por Tipo de Insecto';
      case 30:
        return 'Tendencia Mensual por Tipo de Insecto';
      default:
        return 'Tendencia por Tipo de Insecto';
    }
  }

  String getSubtitle() {
    switch (days) {
      case 1:
        return 'Últimas 24 horas';
      case 7:
        return 'Últimos 7 días';
      case 30:
        return 'Últimos 30 días';
      default:
        return 'Últimos $days días';
    }
  }

  @override
  State<WeeklyTrendByTypeChart> createState() => _WeeklyTrendByTypeChartState();
}

class _WeeklyTrendByTypeChartState extends State<WeeklyTrendByTypeChart>
    with SingleTickerProviderStateMixin {
  List<WeeklyTrendPoint>? chartData;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<String> insectTypes = [];

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
  void didUpdateWidget(WeeklyTrendByTypeChart oldWidget) {
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
      // Calcular fechas basadas en los días solicitados
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;
      
      if (widget.days == 1) {
        // Para "Hoy", trabajar por horas (últimas 24 horas)
        endDate = now;
        startDate = now.subtract(const Duration(hours: 23));
      } else {
        // Para otros períodos, trabajar por días
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: widget.days - 1));
      }
      
      final response = await ChartDataService.fetchWeeklyTrendByType(
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        setState(() {
          chartData = response.data!;
          isLoading = false;
          _extractInsectTypes();
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

  void _extractInsectTypes() {
    if (chartData == null || chartData!.isEmpty) {
      insectTypes = [];
      return;
    }

    final Set<String> types = {};
    for (final point in chartData!) {
      types.addAll(point.cantidadesPorTipo.keys);
    }
    insectTypes = types.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: widget.getTitle(),
      subtitle: widget.getSubtitle(),
      height: widget.height ?? 350,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: Column(
        children: [
          Expanded(child: _buildChart()),
          if (widget.showLegend && insectTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLegend(),
          ],
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
              Icons.bug_report_outlined,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Verificar si hay detecciones
    final hasAnyDetections = chartData!.any((point) => 
        point.cantidadesPorTipo.values.any((cantidad) => cantidad > 0));

    if (!hasAnyDetections) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
              widget.days == 1 
                  ? 'No se registraron insectos\nen las últimas 24 horas'
                  : 'No se registraron insectos\nen los últimos ${widget.days} días',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
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
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
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
              final fecha = chartData![index].fecha;
              
              if (widget.days == 1) {
                // Para período de 1 día, mostrar horas
                final parts = fecha.split(' ');
                if (parts.length >= 2) {
                  final timePart = parts[1].split(':');
                  if (timePart.length >= 2) {
                    return Text(
                      '${timePart[0]}:${timePart[1]}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  }
                }
              } else {
                // Para otros períodos, mostrar días
                final parts = fecha.split('-');
                if (parts.length == 3) {
                  return Text(
                    '${parts[2]}/${parts[1]}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  );
                }
              }
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
        color: AppTheme.textSecondary.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lines = [];

    for (int typeIndex = 0; typeIndex < insectTypes.length; typeIndex++) {
      final type = insectTypes[typeIndex];
      final color = _getTypeColors()[typeIndex % _getTypeColors().length];
      
      final spots = chartData!.asMap().entries.map((entry) {
        final cantidad = entry.value.cantidadesPorTipo[type] ?? 0;
        return FlSpot(entry.key.toDouble(), cantidad.toDouble());
      }).toList();

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
          aboveBarData: BarAreaData(show: false),
        ),
      );
    }

    return lines;
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: AppTheme.cardBackground,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItems: (touchedSpots) {
          if (touchedSpots.isEmpty) return [];
          
          final index = touchedSpots.first.x.toInt();
          if (index < 0 || index >= chartData!.length) return [];
          
          final data = chartData![index];
          final fecha = data.fecha;
          String fechaFormateada;
          
          if (widget.days == 1) {
            // Para período de 1 día, mostrar fecha y hora
            final parts = fecha.split(' ');
            if (parts.length >= 2) {
              final dateParts = parts[0].split('-');
              final timeParts = parts[1].split(':');
              if (dateParts.length == 3 && timeParts.length >= 2) {
                fechaFormateada = '${dateParts[2]}/${dateParts[1]} ${timeParts[0]}:${timeParts[1]}';
              } else {
                fechaFormateada = fecha;
              }
            } else {
              fechaFormateada = fecha;
            }
          } else {
            // Para otros períodos, mostrar solo fecha
            final parts = fecha.split('-');
            fechaFormateada = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : fecha;
          }
          
          final List<LineTooltipItem> items = [];
          
          // Título con la fecha
          items.add(
            LineTooltipItem(
              '$fechaFormateada\n',
              TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          
          // Información de cada tipo de insecto
          for (final spot in touchedSpots) {
            final typeIndex = touchedSpots.indexOf(spot);
            if (typeIndex < insectTypes.length) {
              final type = insectTypes[typeIndex];
              final cantidad = data.cantidadesPorTipo[type] ?? 0;
              final color = _getTypeColors()[typeIndex % _getTypeColors().length];
              
              items.add(
                LineTooltipItem(
                  '$type: $cantidad\n',
                  TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
          }
          
          return items;
        },
      ),
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        // Lógica adicional para el toque si es necesaria
      },
      handleBuiltInTouches: true,
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: insectTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final color = _getTypeColors()[index % _getTypeColors().length];
        
        return ChartIndicator(
          color: color,
          text: type,
          isSquare: false,
          size: 12,
        );
      }).toList(),
    );
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    // Calcular estadísticas totales
    final Map<String, int> totalPorTipo = {};
    int totalGeneral = 0;
    
    for (final point in chartData!) {
      for (final entry in point.cantidadesPorTipo.entries) {
        totalPorTipo[entry.key] = (totalPorTipo[entry.key] ?? 0) + entry.value;
        totalGeneral += entry.value;
      }
    }

    if (totalGeneral == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
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
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.textSecondary.withValues(alpha: 0.2),
            ),
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
                  'Tipos',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Encontrar el tipo más común
    final tipoMasComun = totalPorTipo.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final promedio = widget.days == 1 
        ? (totalGeneral / 24).toStringAsFixed(1)  // Promedio por hora para período de 1 día
        : (totalGeneral / widget.days).toStringAsFixed(1);  // Promedio por día para otros períodos
    final promedioLabel = widget.days == 1 ? 'Promedio/hora' : 'Promedio/día';

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total',
          value: totalGeneral.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Tipos',
          value: insectTypes.length.toString(),
        ),
        ChartStatItem(
          label: 'Más común',
          value: '${tipoMasComun.key} (${tipoMasComun.value})',
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: promedioLabel,
          value: promedio,
        ),
      ],
    );
  }

  List<Color> _getTypeColors() {
    return [
      AppTheme.primaryBlue,
      const Color(0xFF4CAF50), // Verde
      const Color(0xFFFF9800), // Naranja
      const Color(0xFF9C27B0), // Púrpura
      const Color(0xFFF44336), // Rojo
      const Color(0xFF00BCD4), // Cian
      const Color(0xFFFFEB3B), // Amarillo
      const Color(0xFF795548), // Marrón
      const Color(0xFF607D8B), // Azul gris
      const Color(0xFFE91E63), // Rosa
    ];
  }

  double _getMinY() {
    if (chartData == null || chartData!.isEmpty) return 0;

    final hasAnyDetections = chartData!.any((point) => 
        point.cantidadesPorTipo.values.any((cantidad) => cantidad > 0));
    if (!hasAnyDetections) return 0;

    final allValues = <int>[];
    for (final point in chartData!) {
      allValues.addAll(point.cantidadesPorTipo.values);
    }
    
    if (allValues.isEmpty) return 0;
    
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    return (minValue - (minValue * 0.1)).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (chartData == null || chartData!.isEmpty) return 10;

    final hasAnyDetections = chartData!.any((point) => 
        point.cantidadesPorTipo.values.any((cantidad) => cantidad > 0));
    if (!hasAnyDetections) return 10;

    final allValues = <int>[];
    for (final point in chartData!) {
      allValues.addAll(point.cantidadesPorTipo.values);
    }
    
    if (allValues.isEmpty) return 10;
    
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final adjustedMax = maxValue + (maxValue * 0.1);
    return adjustedMax < 1 ? 10 : adjustedMax;
  }
}