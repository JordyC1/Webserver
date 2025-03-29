import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/alert_service.dart'; // 👈 Importa el servicio de alertas

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

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchRecentDetections();
      fetchAlertCount(); // 👈 Actualizar alertas cada 10 segundos
      fetchWeeklyDetections();     // ✅ Se actualiza semanalmente
      fetchTrampasActivas();       // ✅ Se actualiza cantidad activa
      _updateTime();
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
      final fetchedAlertas = await AlertService.verificarAlertas();
      setState(() {
        alertasActivas = fetchedAlertas.length;
      });
    } catch (e) {
      print("Error al obtener alertas: $e");
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      lastUpdateTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 10),

            // 🧩 Tarjetas de resumen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Detectados Esta Semana",
                    "$totalInsectosSemana", Icons.bug_report),
                _buildSummaryCard("Alertas Activas", "$alertasActivas",
                    Icons.warning), // 👈 Aquí se actualiza
                _buildSummaryCard("Trampas Activas", "$trampasActivas",
                    Icons.sensors),
              ],
            ),
            SizedBox(height: 20),

            // Resto del contenido...
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gráfico
                  Expanded(
                    flex: 2,
                    child: _buildBarChartCard(),
                  ),
                  SizedBox(width: 16),
                  // Tabla detecciones
                  Expanded(
                    flex: 1,
                    child: _buildDetectionsTableCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
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
      ),
    );
  }

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

  Widget _buildDetectionsTableCard() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Detecciones Recientes",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
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
                )
              ],
            ),
            Text(
              "Última actualización: $lastUpdateTime",
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
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
                              "Cantidad: ${deteccion["cantidad"]} | Fecha: ${deteccion["fecha"]}",
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        );
                      },
                    ),
            ),
          ],
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
}
