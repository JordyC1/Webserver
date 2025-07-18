import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/alert_service.dart';
import '../services/chart_data_service.dart';
// 📊 Importar todas las gráficas implementadas
import '../widgets/charts/daily_trend_chart.dart';
import '../widgets/charts/insect_distribution_pie_chart.dart';
import '../widgets/charts/stacked_bar_chart.dart';
import '../widgets/charts/alerts_severity_chart.dart';
import '../widgets/charts/average_time_indicator.dart' as widgets;
import '../widgets/charts/weekly_cumulative_area_chart.dart';
// ✅ Heatmap ACTIVADO - Import directo
import '../widgets/charts/hourly_heatmap_chart.dart';
// Los widgets de indicadores de insectos se movieron al Panel de Plagas

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<int> weeklyData = [];
  List<Map<String, dynamic>> detecciones = [];
  int totalInsectosSemana = 0;
  int trampasActivas = 0;
  int alertasActivas = 0; // 👈 Nuevo: cantidad de alertas
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  String lastUpdateTime = "";

  // 📊 Variables para el selector de período y control de gráficas
  String selectedTimePeriod = "Últimos 7 días";
  Map<String, bool> chartLoadingStates = {};
  Map<String, String?> chartErrors = {};

  // Las variables de indicadores de insectos se movieron al Panel de Plagas

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);

    _updateTime();

    fetchWeeklyDetections();
    fetchRecentDetections();
    fetchTrampasActivas();
    fetchAlertCount(); // 👈 Obtener la cantidad de alertas al iniciar
    // Los indicadores de insectos se cargan en el Panel de Plagas

    // 🔄 Cambiar timer a 30 segundos para todas las gráficas
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchRecentDetections();
      fetchAlertCount();
      fetchWeeklyDetections();
      fetchTrampasActivas();
      _updateTime();
      // Los indicadores de insectos se actualizan en el Panel de Plagas
      _refreshAllCharts(); // 📊 Actualizar todas las gráficas
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchTrampasActivas() async {
    final response = await http
        .get(Uri.parse("http://raspberrypi2.local/get_trampas_activas.php"));

    if (response.statusCode == 200) {
      setState(() {
        trampasActivas =
            int.parse(jsonDecode(response.body)["trampas_activas"]);
      });
    } else {
      print("Error al obtener trampas activas: ${response.statusCode}");
    }
  }

  Future<void> fetchWeeklyDetections() async {
    final response = await http
        .get(Uri.parse("http://raspberrypi2.local/get_weekly_detections.php"));

    if (response.statusCode == 200) {
      List<int> valores = response.body
          .split(",")
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      setState(() {
        weeklyData = valores;
        totalInsectosSemana = valores.reduce((a, b) => a + b);
      });
    } else {
      print("Error al obtener los datos de la gráfica: ${response.statusCode}");
    }
  }

  Future<void> fetchRecentDetections() async {
    try {
      final response = await http
          .get(Uri.parse("http://raspberrypi2.local/get_detections.php"));

      if (response.statusCode == 200 && mounted) {
        setState(() {
          detecciones =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      print("Error al obtener las detecciones recientes: $e");
    }
  }

  // 👇 Nuevo: obtener la cantidad de alertas activas desde el servicio
Future<void> fetchAlertCount() async {
  try {
    final response = await http.get(Uri.parse('http://raspberrypi2.local/get_alertas_historial.php'));

    if (response.statusCode == 200) {
      final body = response.body;

      final List<dynamic> data = jsonDecode(body);

      int total = 0;

      for (var alerta in data) {
        final estado = alerta['estado']?.toString().toLowerCase();

        if (estado == 'activa') {
          total++;
        }
      }


      setState(() {
        alertasActivas = total;
      });
    } else {
      print("Error HTTP al obtener alertas: ${response.statusCode}");
    }
  } catch (e) {
    print("Error al obtener alertas: $e");
  }
}


  // La función de carga de indicadores de insectos se movió al Panel de Plagas


  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      lastUpdateTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  // 🔄 Método para actualizar todas las gráficas
  void _refreshAllCharts() {
    setState(() {
      // Esto forzará la actualización de todas las gráficas
      // Las gráficas individuales manejan su propia carga de datos
    });
  }

  // Método para actualizar todos los datos del dashboard
  Future<void> _refreshAllData() async {
    await Future.wait([
      fetchRecentDetections(),
      fetchAlertCount(),
      fetchWeeklyDetections(),
      fetchTrampasActivas(),
    ]);
    _updateTime();
    _refreshAllCharts();
  }

  // 📊 Método para obtener el número de días según el período seleccionado
  int _getDaysFromPeriod() {
    switch (selectedTimePeriod) {
      case "Último día":
        return 1;
      case "Últimos 7 días":
        return 7;
      case "Último mes":
        return 30;
      default:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 📱 Detectar el tipo de dispositivo
          final isDesktop = constraints.maxWidth > 1200;
          final isTablet =
              constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
          final isMobile = constraints.maxWidth <= 768;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📱 Header con título y selector de período
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Dashboard",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    _buildTimePeriodSelector(),
                  ],
                ),
                const SizedBox(height: 10),

                // ⏰ Indicador de última actualización
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      "Última actualización: $lastUpdateTime",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue
                                    .withOpacity(0.5 * _pulseAnimation.value),
                                blurRadius: 4.0 * _pulseAnimation.value,
                                spreadRadius: 1.0 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🧩 1. Tarjetas de resumen (mantener las actuales) - RESPONSIVO
                _buildResponsiveSummaryCards(isDesktop, isTablet, isMobile),
                const SizedBox(height: 24),

                // Las cards de insectos se movieron al Panel de Plagas

                // 📊 3. Fila 1: Tendencia diaria + Distribución por tipo - RESPONSIVO
                _buildResponsiveRow1(isDesktop, isTablet, isMobile),
                const SizedBox(height: 16),

                // 📊 4. Fila 2: Barras apiladas + Alertas por severidad - RESPONSIVO
                _buildResponsiveRow2(isDesktop, isTablet, isMobile),
                const SizedBox(height: 16),

                // 🔥 5. Fila 3: Actividad por hora (heatmap - ancho completo) - RESPONSIVO
                _buildResponsiveHeatmapRow(isDesktop, isTablet, isMobile),
                const SizedBox(height: 16),

                // 📈 6. Fila 4: Acumulación semanal + Indicador tiempo promedio - RESPONSIVO
                _buildResponsiveRow4(isDesktop, isTablet, isMobile),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📊 Selector de período de tiempo
  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTimePeriod,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          dropdownColor: AppTheme.cardBackground,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
          items: ["Último día", "Últimos 7 días", "Último mes"]
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedTimePeriod = newValue;
                _refreshAllCharts(); // Actualizar gráficas con nuevo período
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryBlue),
            SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }

  // 📊 Mantener el gráfico de barras original (usado en la tabla)
  Widget _buildBarChartCard() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: weeklyData.isNotEmpty
                ? weeklyData.reduce((a, b) => a > b ? a : b).toDouble() + 10
                : 100,
            barGroups: _getBarGroups(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = [
                      "Lun",
                      "Mar",
                      "Mié",
                      "Jue",
                      "Vie",
                      "Sáb",
                      "Dom"
                    ];
                    return Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(days[value.toInt() % days.length],
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
              getDrawingVerticalLine: (_) =>
                  FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
            ),
            backgroundColor: AppTheme.cardBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionsTableCard({double? height}) {
    return SizedBox(
      height: height,
      child: Card(
        color: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detecciones Recientes",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Expanded(
                child: detecciones.isEmpty
                    ? Center(
                        child: Text("No hay datos aún...",
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        itemCount: detecciones.length,
                        itemBuilder: (context, index) {
                          final deteccion = detecciones[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 0),
                            dense: true,
                            leading: Icon(Icons.bug_report,
                                color: AppTheme.primaryBlue, size: 20),
                            title: Text(deteccion["tipo"],
                                style: TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14)),
                              subtitle: Text(
                                "Cantidad: ${deteccion["cantidad"]} | Fecha: ${deteccion["fecha"]} | Trampa ID: ${deteccion["trampa_id"]}",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(weeklyData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[index].toDouble(),
            color: AppTheme.primaryBlue,
            width: 16,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  // 🧩 Tarjetas de resumen responsivas (Fase 4: Incluye resumen de insectos)
  Widget _buildResponsiveSummaryCards(
      bool isDesktop, bool isTablet, bool isMobile) {
    if (isMobile) {
      // Móvil: 1 columna
      return Column(
        children: [
          _buildSummaryCard("Detectados Esta Semana", "$totalInsectosSemana",
              Icons.bug_report),
          const SizedBox(height: 12),
          _buildSummaryCard(
              "Alertas Activas", "$alertasActivas", Icons.warning),
          const SizedBox(height: 12),
          _buildSummaryCard(
              "Trampas Activas", "$trampasActivas", Icons.sensors),
        ],
      );
    } else if (isTablet) {
      // Tablet: 2 filas de 2 columnas
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard("Detectados Esta Semana",
                    "$totalInsectosSemana", Icons.bug_report),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                    "Alertas Activas", "$alertasActivas", Icons.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                    "Trampas Activas", "$trampasActivas", Icons.sensors),
              ),

            ],
          ),
        ],
      );
    } else {
      // Desktop: 4 columnas
      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard("Detectados Esta Semana",
                "$totalInsectosSemana", Icons.bug_report),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
                "Alertas Activas", "$alertasActivas", Icons.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
                "Trampas Activas", "$trampasActivas", Icons.sensors),
          ),

        ],
      );
    }
  }

  // Las funciones de indicadores de insectos se movieron al Panel de Plagas

  // 📈 Fila 1: Tendencia diaria + Distribución por tipo
  Widget _buildResponsiveRow1(bool isDesktop, bool isTablet, bool isMobile) {
    if (isMobile) {
      // Móvil: columnas apiladas - alturas aumentadas
      return Column(
        children: [
          DailyTrendChart(days: _getDaysFromPeriod(), height: 380),
          const SizedBox(height: 16),
          InsectDistributionPieChart(days: _getDaysFromPeriod(), height: 380),
        ],
      );
    } else {
      // Tablet y Desktop: 2 columnas - alturas aumentadas
      double chartHeight = isDesktop ? 380 : 360;
      return Row(
        children: [
          Expanded(
            child: DailyTrendChart(
                days: _getDaysFromPeriod(), height: chartHeight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InsectDistributionPieChart(
                days: _getDaysFromPeriod(), height: chartHeight),
          ),
        ],
      );
    }
  }

  // 📊 Fila 2: Barras apiladas + Alertas por severidad
  Widget _buildResponsiveRow2(bool isDesktop, bool isTablet, bool isMobile) {
    if (isMobile) {
      // Móvil: columnas apiladas - alturas aumentadas
      return Column(
        children: [
          StackedBarChart(days: _getDaysFromPeriod(), height: 400),
          const SizedBox(height: 16),
          AlertsSeverityChart(height: 380),
        ],
      );
    } else {
      // Tablet y Desktop: 2 columnas - alturas aumentadas
      double chartHeight = isDesktop ? 380 : 360;
      return Row(
        children: [
          Expanded(
            child: StackedBarChart(
                days: _getDaysFromPeriod(), height: chartHeight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AlertsSeverityChart(height: chartHeight),
          ),
        ],
      );
    }
  }

  // 🔥 Fila 3: Heatmap (ancho completo) - ACTIVADO Y FUNCIONANDO
  Widget _buildResponsiveHeatmapRow(
      bool isDesktop, bool isTablet, bool isMobile) {
    double heatmapHeight = isDesktop
        ? 550
        : isTablet
            ? 500
            : 450;

    return HourlyHeatmapChart(
      days: _getDaysFromPeriod(),
      height: heatmapHeight,
      showLabels: true,
    );
  }

  // 📈 Fila 4: Acumulación semanal + Indicador tiempo promedio
  Widget _buildResponsiveRow4(bool isDesktop, bool isTablet, bool isMobile) {
    if (isMobile) {
      // Móvil: columnas apiladas - alturas aumentadas (+50px tiempo promedio)
      return Column(
        children: [
          WeeklyCumulativeAreaChart(days: _getDaysFromPeriod(), height: 380),
          const SizedBox(height: 16),
          widgets.AverageTimeIndicator(days: _getDaysFromPeriod(), height: 330),
          const SizedBox(height: 16),
          _buildDetectionsTableCard(height: 320),
        ],
      );
    } else if (isTablet) {
      // Tablet: 2 columnas, tabla abajo - alturas aumentadas (+50px tiempo promedio)
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: WeeklyCumulativeAreaChart(
                    days: _getDaysFromPeriod(), height: 400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: widgets.AverageTimeIndicator(
                    days: _getDaysFromPeriod(), height: 450),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetectionsTableCard(height: 280),
        ],
      );
    } else {
      // Desktop: acumulación semanal arriba, indicador + tabla abajo - alturas aumentadas (+50px tiempo promedio)
      return Column(
        children: [
          WeeklyCumulativeAreaChart(days: _getDaysFromPeriod(), height: 400),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: widgets.AverageTimeIndicator(
                    days: _getDaysFromPeriod(), height: 370),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildDetectionsTableCard(height: 320),
              ),
            ],
          ),
        ],
      );
    }
  }
}