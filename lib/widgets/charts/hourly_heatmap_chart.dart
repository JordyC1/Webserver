import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/chart_models.dart';
import '../../services/chart_data_service.dart';
import 'base_chart_card.dart';

class HourlyHeatmapChart extends StatefulWidget {
  final int days;
  final double? height;
  final bool showLabels;

  const HourlyHeatmapChart({
    Key? key,
    this.days = 14,
    this.height,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<HourlyHeatmapChart> createState() => _HourlyHeatmapChartState();
}

class _HourlyHeatmapChartState extends State<HourlyHeatmapChart>
    with SingleTickerProviderStateMixin {
  List<HourlyActivityData>? chartData;
  bool isLoading = true;
  String? errorMessage;
  Map<String, HourlyActivityData> dataMap = {};
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HourlyHeatmapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      dataMap.clear();
    });

    try {
      final response =
          await ChartDataService.fetchHourlyActivityData(days: widget.days);

      if (response.success && response.data != null) {
        setState(() {
          chartData = response.data!;
          _processData();
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

  void _processData() {
    dataMap.clear();
    if (chartData != null) {
      for (var data in chartData!) {
        final key = '${data.diaSemana}_${data.hora}';
        dataMap[key] = data;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Actividad por Hora del Día',
      subtitle: 'Mapa de calor de los últimos ${widget.days} días',
      height: widget.height ?? 400,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadData,
      chart: Column(
        children: [
          _buildIntensityLegend(),
          const SizedBox(height: 16),
          Expanded(child: _buildHeatmap()),
        ],
      ),
      footer: _buildStats(),
    );
  }

  Widget _buildIntensityLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Baja actividad',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (index) {
            final intensity = index / 4.0;
            return Container(
              width: 16,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryBlue.withOpacity(0.1 + (intensity * 0.9)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          'Alta actividad',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    if (chartData == null) {
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showLabels) _buildHourLabels(),
                const SizedBox(height: 4),
                Column(
                  children: List.generate(7, (dayIndex) {
                    return Row(
                      children: [
                        if (widget.showLabels) _buildDayLabel(dayIndex),
                        ...List.generate(24, (hourIndex) {
                          return _buildHeatmapCell(dayIndex, hourIndex);
                        }),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourLabels() {
    return Row(
      children: [
        const SizedBox(width: 40),
        ...List.generate(6, (index) {
          final hour = index * 4;
          return Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayLabel(int dayIndex) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Container(
      width: 40,
      height: 20,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        dias[dayIndex],
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeatmapCell(int dayIndex, int hourIndex) {
    final key = '${dayIndex}_$hourIndex';
    final data = dataMap[key];
    final intensity = data?.intensidad ?? 0.0;
    final cantidad = data?.cantidad ?? 0;

    return GestureDetector(
      onTap: () => _showTooltip(dayIndex, hourIndex, data),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (dayIndex * hourIndex * 5)),
        curve: Curves.easeOutQuart,
        width: 15,
        height: 20,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(
            (0.1 + (intensity * 0.9)) * _animation.value,
          ),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: intensity > 0.7
            ? Center(
                child: Text(
                  cantidad.toString(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showTooltip(int dayIndex, int hourIndex, HourlyActivityData? data) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final hora = '${hourIndex.toString().padLeft(2, '0')}:00';
    final cantidad = data?.cantidad ?? 0;
    final intensidad = data?.intensidad ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Actividad Detallada',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Día:', dias[dayIndex]),
            _buildInfoRow('Hora:', hora),
            _buildInfoRow('Detecciones:', cantidad.toString()),
            _buildInfoRow(
                'Intensidad:', '${(intensidad * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryBlue.withOpacity(0.1 + (intensidad * 0.9)),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              child: Center(
                child: Text(
                  _getActivityLevel(intensidad),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        intensidad > 0.5 ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityLevel(double intensity) {
    if (intensity == 0) return 'Sin actividad';
    if (intensity < 0.3) return 'Baja';
    if (intensity < 0.6) return 'Media';
    if (intensity < 0.8) return 'Alta';
    return 'Muy Alta';
  }

  Widget _buildStats() {
    if (chartData == null || chartData!.isEmpty) return const SizedBox.shrink();

    final totalDetecciones =
        chartData!.fold(0, (sum, data) => sum + data.cantidad);
    final horasPico = _getHorasPico();
    final diasPico = _getDiasPico();
    final nivelActividad = _getNivelActividadGeneral();

    return ChartStats(
      stats: [
        ChartStatItem(
          label: 'Total',
          value: totalDetecciones.toString(),
          valueColor: AppTheme.primaryBlue,
        ),
        ChartStatItem(
          label: 'Horas pico',
          value: horasPico,
        ),
        ChartStatItem(
          label: 'Días activos',
          value: diasPico,
        ),
        ChartStatItem(
          label: 'Nivel general',
          value: nivelActividad['texto'],
          valueColor: nivelActividad['color'],
        ),
      ],
    );
  }

  String _getHorasPico() {
    if (chartData == null || chartData!.isEmpty) return 'N/A';

    Map<int, int> cantidadPorHora = {};
    for (var data in chartData!) {
      cantidadPorHora[data.hora] =
          (cantidadPorHora[data.hora] ?? 0) + data.cantidad;
    }

    var sortedHours = cantidadPorHora.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedHours.length >= 2) {
      return '${sortedHours[0].key}h, ${sortedHours[1].key}h';
    } else if (sortedHours.length == 1) {
      return '${sortedHours[0].key}h';
    }

    return 'N/A';
  }

  String _getDiasPico() {
    if (chartData == null || chartData!.isEmpty) return 'N/A';

    Map<int, int> cantidadPorDia = {};
    for (var data in chartData!) {
      cantidadPorDia[data.diaSemana] =
          (cantidadPorDia[data.diaSemana] ?? 0) + data.cantidad;
    }

    final diasActivos =
        cantidadPorDia.values.where((cantidad) => cantidad > 0).length;
    return '$diasActivos/7';
  }

  Map<String, dynamic> _getNivelActividadGeneral() {
    if (chartData == null || chartData!.isEmpty) {
      return {'texto': 'Sin datos', 'color': AppTheme.textSecondary};
    }

    final intensidadPromedio =
        chartData!.map((data) => data.intensidad).reduce((a, b) => a + b) /
            chartData!.length;

    if (intensidadPromedio > 0.6) {
      return {'texto': 'Muy Alto', 'color': Colors.red};
    } else if (intensidadPromedio > 0.4) {
      return {'texto': 'Alto', 'color': Colors.orange};
    } else if (intensidadPromedio > 0.2) {
      return {'texto': 'Medio', 'color': Colors.yellow[700]};
    } else if (intensidadPromedio > 0.05) {
      return {'texto': 'Bajo', 'color': Colors.blue};
    } else {
      return {'texto': 'Muy Bajo', 'color': Colors.green};
    }
  }
}
