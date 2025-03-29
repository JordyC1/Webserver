import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';

class AlertasScreen extends StatefulWidget {
  @override
  _AlertasScreenState createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Alerta> alertas = [];
  String lastUpdateTime = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarAlertas();
  }

  void _verificarAlertas() async {
    setState(() => _isLoading = true);

    final nuevasAlertas = await AlertService.verificarAlertas();

    setState(() {
      alertas = nuevasAlertas;
      _isLoading = false;
      lastUpdateTime =
          "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monitoreo de Alertas",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Última actualización: $lastUpdateTime",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
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
                                    color: _getSeverityColor(alerta.severidad),
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: _getSeverityColor(alerta.severidad),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        alerta.tipo,
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
                                        alerta.mensaje,
                                        style: TextStyle(
                                            color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Detectado: ${DateTime.parse(alerta.fecha).toLocal().toString().split('.')[0]}",
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
