import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../services/export_templates.dart';

class ExportarScreen extends StatefulWidget {
  @override
  _ExportarScreenState createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  bool _isLoading = false;
  String _lastExportTime = "";
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _formatoExportacion = 'json';
  VoidCallback? _accionPosteriorFormato;

  void _mostrarSeleccionFormato(VoidCallback onContinuar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Seleccionar formato de exportación",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text("JSON", style: TextStyle(color: AppTheme.textPrimary)),
                value: 'json',
                groupValue: _formatoExportacion,
                onChanged: (value) {
                  setState(() => _formatoExportacion = value!);
                },
              ),
              RadioListTile<String>(
                title: Text("CSV", style: TextStyle(color: AppTheme.textPrimary)),
                value: 'csv',
                groupValue: _formatoExportacion,
                onChanged: (value) {
                  setState(() => _formatoExportacion = value!);
                },
              ),
              RadioListTile<String>(
                title: Text("HTML", style: TextStyle(color: AppTheme.textPrimary)),
                value: 'html',
                groupValue: _formatoExportacion,
                onChanged: (value) {
                  setState(() => _formatoExportacion = value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancelar", style: TextStyle(color: AppTheme.primaryBlue)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.pop(context);
              if (_accionPosteriorFormato != null) {
                _accionPosteriorFormato!();
              }
            },
            child: Text("Continuar"),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltroExportacionLecturas() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text("Filtrar Exportación de Lecturas",
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                title: Text(
                  _fechaInicio == null
                      ? "Selecciona fecha y hora de inicio"
                      : "Inicio: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_fechaInicio!)}",
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(Duration(days: 1)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _fechaInicio = DateTime(
                            date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: AppTheme.primaryBlue),
                title: Text(
                  _fechaFin == null
                      ? "Selecciona fecha y hora de fin"
                      : "Fin: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_fechaFin!)}",
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _fechaFin = DateTime(
                            date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: TextStyle(color: AppTheme.primaryBlue)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: () {
                if (_fechaInicio == null || _fechaFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Debes seleccionar ambas fechas")),
                  );
                  return;
                }
                if (_fechaInicio!.isAfter(_fechaFin!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("La fecha de inicio no puede ser posterior a la de fin")),
                  );
                  return;
                }
                Navigator.pop(context);
                _exportarLecturasFiltradas();
              },
              child: Text("Exportar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarLecturasFiltradas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("http://raspberrypi2.local/get_lecturas.php"));
      if (response.statusCode == 200) {
        List<dynamic> lecturas = jsonDecode(response.body);
        if (_fechaInicio != null && _fechaFin != null) {
          lecturas = lecturas.where((lectura) {
            final fecha = DateTime.parse(lectura['fecha']);
            return fecha.isAfter(_fechaInicio!) && fecha.isBefore(_fechaFin!);
          }).toList();
        }
        final contenido = _formatearContenido(lecturas, "lecturas");
        _descargarArchivo(contenido, "lecturas_export.$_formatoExportacion");
        _actualizarTiempoExportacion();
      } else {
        throw Exception("Error al obtener lecturas");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al exportar lecturas: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _exportarAlertas() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("http://raspberrypi2.local/get_alertas_historial.php"));
      if (response.statusCode == 200) {
        List<dynamic> alertas = jsonDecode(response.body);
        final contenido = _formatoExportacion == 'html'
            ? generarPlantillaHTMLAlertas(alertas)
            : _formatearContenido(alertas, "alertas");
        _descargarArchivo(contenido, "alertas_export.$_formatoExportacion");
        _actualizarTiempoExportacion();
      } else {
        throw Exception("Error al obtener alertas");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al exportar alertas: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _exportarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("http://raspberrypi2.local/get_usuarios.php"));
      if (response.statusCode == 200) {
        final contenido = _formatearContenido(jsonDecode(response.body), "usuarios");
        _descargarArchivo(contenido, "usuarios_export.$_formatoExportacion");
        _actualizarTiempoExportacion();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al exportar usuarios: $e")));
    }
    setState(() => _isLoading = false);
  }

  void _descargarArchivo(String contenido, String nombreArchivo) {
    final bytes = utf8.encode(contenido);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", nombreArchivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  String _formatearContenido(List<dynamic> datos, String tipo) {
    if (_formatoExportacion == 'json') {
      return jsonEncode({tipo: datos});
    } else if (_formatoExportacion == 'csv') {
      if (datos.isEmpty) return '';
      final encabezados = (datos.first as Map<String, dynamic>).keys.join(',');
      final filas = datos.map((d) => (d as Map<String, dynamic>).values.join(',')).join('\n');
      return '$encabezados\n$filas';
    } else if (_formatoExportacion == 'html') {
      if (datos.isEmpty) return '<html><body><p>No hay datos disponibles</p></body></html>';
      if (tipo == "usuarios") {
        return plantillaUsuarios.replaceFirst("{{FILAS}}", _generarFilasHTML(datos));
      } else if (tipo == "lecturas") {
        return plantillaLecturas.replaceFirst("{{FILAS}}", _generarFilasHTML(datos));
      } else if (tipo == "alertas") {
        return plantillaAlertas.replaceFirst("{{FILAS}}", _generarFilasHTML(datos));
      }
    }
    return '';
  }

  String _generarFilasHTML(List<dynamic> datos) {
    return datos.map((d) =>
      '<tr>' +
      (d as Map<String, dynamic>).values.map((v) => '<td>${v.toString()}</td>').join() +
      '</tr>').join();
  }

  Future<List<Map<String, dynamic>>> _generarAlertas(String lecturasJson) async {
    List<Map<String, dynamic>> alertas = [];
    List<Map<String, dynamic>> lecturas = List<Map<String, dynamic>>.from(jsonDecode(lecturasJson));

    if (lecturas.isEmpty) {
      alertas.add({
        'tipo': 'Sin datos',
        'mensaje': 'No hay lecturas registradas en el sistema',
        'fecha': DateTime.now().toString(),
        'severidad': 'alta'
      });
      return alertas;
    }

    int maxCapturaId = lecturas.map((l) => int.parse(l['captura_id'].toString())).reduce((a, b) => a > b ? a : b);
    var lecturasUltimaCaptura = lecturas.where((l) => l['captura_id'].toString() == maxCapturaId.toString()).toList();
    int totalInsectos = lecturasUltimaCaptura.fold(0, (sum, l) => sum + int.parse(l['cantidad'].toString()));

    if (totalInsectos > 25) {
      alertas.add({
        'tipo': 'Alta cantidad de insectos',
        'mensaje': 'Se detectaron $totalInsectos insectos en la última captura',
        'fecha': DateTime.now().toString(),
        'severidad': 'alta'
      });
    }

    var ultimaLectura = lecturas.reduce((a, b) => DateTime.parse(a['fecha']).isAfter(DateTime.parse(b['fecha'])) ? a : b);
    var diferencia = DateTime.now().difference(DateTime.parse(ultimaLectura['fecha']));
    if (diferencia.inMinutes > 45) {
      alertas.add({
        'tipo': 'Sin lecturas recientes',
        'mensaje': 'No se han registrado lecturas en los últimos 45 minutos',
        'fecha': DateTime.now().toString(),
        'severidad': 'media'
      });
    }

    return alertas;
  }

  void _actualizarTiempoExportacion() {
    final now = DateTime.now();
    setState(() {
      _lastExportTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  Widget _buildExportCard(String titulo, String descripcion, IconData icono, {VoidCallback? onTap}) {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(descripcion, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Exportar Datos", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Selecciona los datos a exportar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    if (_lastExportTime.isNotEmpty)
                      Text("Última exportación: $_lastExportTime", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = (constraints.maxWidth / 250).floor();
                      return GridView.count(
                        crossAxisCount: crossAxisCount > 1 ? crossAxisCount : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildExportCard(
                            "Usuarios",
                            "Exportar lista de usuarios y sus roles",
                            Icons.people,
                            onTap: () {
                              _accionPosteriorFormato = _exportarUsuarios;
                              _mostrarSeleccionFormato(() {});
                            },
                          ),
                          _buildExportCard(
                            "Lecturas",
                            "Exportar historial de lecturas y detecciones",
                            Icons.analytics,
                            onTap: () {
                              _accionPosteriorFormato = _mostrarFiltroExportacionLecturas;
                              _mostrarSeleccionFormato(() {});
                            },
                          ),
                          _buildExportCard(
                            "Alertas",
                            "Exportar registro de alertas generadas",
                            Icons.warning,
                            onTap: () {
                              _accionPosteriorFormato = _exportarAlertas;
                              _mostrarSeleccionFormato(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
