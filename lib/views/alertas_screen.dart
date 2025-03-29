import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';

class AlertasScreen extends StatefulWidget {
  @override
  _AlertasScreenState createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Map<String, dynamic>> alertas = [];
  Timer? _timer;
  bool _isLoading = false;
  String lastUpdateTime = "";

  @override
  void initState() {
    super.initState();
    _verificarAlertas();
    _updateTime();

    // Configurar timer para actualizar cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _verificarAlertas();
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      lastUpdateTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _verificarAlertas() async {
    try {
      // Obtener las lecturas
      final response = await http.get(
        Uri.parse("http://raspberrypi2.local/get_lecturas.php"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> lecturas =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
        List<Map<String, dynamic>> nuevasAlertas = [];

        // Verificar si hay lecturas
        if (lecturas.isEmpty) {
          nuevasAlertas.add({
            'tipo': 'Sin datos',
            'mensaje': 'No hay lecturas registradas en el sistema',
            'fecha': DateTime.now().toString(),
            'severidad': 'alta'
          });
        } else {
          // Obtener la última captura (ID más alto)
          int maxCapturaId = lecturas
              .map((l) => int.parse(l['captura_id'].toString()))
              .reduce((a, b) => a > b ? a : b);

          // Filtrar lecturas de la última captura
          var lecturasUltimaCaptura = lecturas
              .where(
                  (l) => l['captura_id'].toString() == maxCapturaId.toString())
              .toList();

          // Verificar cantidad total de insectos en la última captura
          int totalInsectos = lecturasUltimaCaptura.fold(
              0,
              (sum, lectura) =>
                  sum + (int.parse(lectura['cantidad'].toString())));
          if (totalInsectos > 25) {
            nuevasAlertas.add({
              'tipo': 'Alta cantidad de insectos',
              'mensaje':
                  'Se detectaron $totalInsectos insectos en la última captura',
              'fecha': DateTime.now().toString(),
              'severidad': 'alta'
            });
          }

          // Verificar última lectura (45 minutos)
          var ultimaLectura = lecturas.reduce((a, b) =>
              DateTime.parse(a['fecha']).isAfter(DateTime.parse(b['fecha']))
                  ? a
                  : b);
          var diferencia =
              DateTime.now().difference(DateTime.parse(ultimaLectura['fecha']));
          if (diferencia.inMinutes > 45) {
            nuevasAlertas.add({
              'tipo': 'Sin lecturas recientes',
              'mensaje':
                  'No se han registrado lecturas en los últimos 45 minutos',
              'fecha': DateTime.now().toString(),
              'severidad': 'media'
            });
          }

          // Verificar capturas sin detección
          var capturasUnicas =
              lecturas.map((l) => l['captura_id']).toSet().toList();
          for (var capturaId in capturasUnicas) {
            var lecturasCaptura =
                lecturas.where((l) => l['captura_id'] == capturaId).toList();
            if (lecturasCaptura.isEmpty) {
              nuevasAlertas.add({
                'tipo': 'Captura sin detección',
                'mensaje':
                    'La captura ID $capturaId no tiene detecciones registradas',
                'fecha': DateTime.now().toString(),
                'severidad': 'baja'
              });
            }
          }
        }

        setState(() {
          alertas = nuevasAlertas;
        });
      } else {
        setState(() {
          alertas = [
            {
              'tipo': 'Error de conexión',
              'mensaje':
                  'Error al conectar con el servidor: ${response.statusCode}',
              'fecha': DateTime.now().toString(),
              'severidad': 'alta'
            }
          ];
        });
      }
    } catch (e) {
      setState(() {
        alertas = [
          {
            'tipo': 'Error',
            'mensaje': 'Error al procesar las alertas: $e',
            'fecha': DateTime.now().toString(),
            'severidad': 'alta'
          }
        ];
      });
    }
  }

  Color _getSeverityColor(String severidad) {
    switch (severidad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Alertas", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: "Actualizar alertas",
            onPressed: _verificarAlertas,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Monitoreo de Alertas",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  "Última actualización: $lastUpdateTime",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: alertas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: AppTheme.primaryBlue),
                          const SizedBox(height: 16),
                          Text(
                            "No hay alertas activas",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: alertas.length,
                      itemBuilder: (context, index) {
                        final alerta = alertas[index];
                        return Card(
                          color: AppTheme.cardBackground,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _getSeverityColor(alerta['severidad']),
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: _getSeverityColor(alerta['severidad']),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  alerta['tipo'],
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  alerta['mensaje'],
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Detectado: ${DateTime.parse(alerta['fecha']).toLocal().toString().split('.')[0]}",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
