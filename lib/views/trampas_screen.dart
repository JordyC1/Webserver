import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class TrampasScreen extends StatefulWidget {
  @override
  _TrampasScreenState createState() => _TrampasScreenState();
}

class _TrampasScreenState extends State<TrampasScreen> {
  List<Map<String, dynamic>> trampas = [];
  String? filtroUbicacion = 'Todas';
  String? filtroEstado = 'Todas';
  String? filtroAdhesivo = 'Todas';

  final Map<String, String> estadoMap = {
    'Activa': 'active',
    'Inactiva': 'inactive',
  };

  @override
  void initState() {
    super.initState();
    cargarTrampas();
  }

  Future<void> cargarTrampas() async {
    final response = await http.get(Uri.parse('http://raspberrypi2.local/get_trampas.php'));
    if (response.statusCode == 200) {
      setState(() {
        trampas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }
  }

  Future<bool> tieneCapturas(int trampaId) async {
    final response = await http.get(Uri.parse('http://raspberrypi2.local/verificar_trampa_en_capturas.php?trampa_id=$trampaId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return int.parse(data['total'].toString()) > 0;
    }
    return true;
  }

  Future<void> eliminarTrampa(Map<String, dynamic> trampa) async {
    final confirmar = await _mostrarConfirmacion(trampa);
    if (!confirmar) return;

    final tiene = await tieneCapturas(int.parse(trampa['trampa_id'].toString()));
    if (tiene) {
      _mostrarDialogo("No se puede eliminar", "Esta trampa tiene capturas registradas.");
    } else {
      await http.post(
        Uri.parse('http://raspberrypi2.local/delete_trampa.php'),
        body: {'trampa_id': trampa['trampa_id'].toString()},
      );
      cargarTrampas();
    }
  }

  Future<bool> _mostrarConfirmacion(Map<String, dynamic> trampa) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de que deseas eliminar la trampa '${trampa['nombre'] ?? 'Sin nombre'}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Sí, eliminar"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _mostrarDialogo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Aceptar"))],
      ),
    );
  }

  void _mostrarFormularioTrampa({Map<String, dynamic>? trampa}) {
    final nombreController = TextEditingController(text: trampa?['nombre'] ?? '');
    final ubicacionController = TextEditingController(text: trampa?['ubicacion'] ?? '');
    final esEdicion = trampa != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? "Editar Trampa" : "Registrar Trampa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: InputDecoration(labelText: "Nombre o Alias")),
            TextField(controller: ubicacionController, decoration: InputDecoration(labelText: "Ubicación")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (esEdicion) {
                await http.post(Uri.parse('http://raspberrypi2.local/update_trampa.php'), body: {
                  'trampa_id': trampa!['trampa_id'].toString(),
                  'nombre': nombreController.text,
                  'ubicacion': ubicacionController.text,
                });
              } else {
                await http.post(Uri.parse('http://raspberrypi2.local/add_trampa.php'), body: {
                  'nombre': nombreController.text,
                  'ubicacion': ubicacionController.text,
                });
              }
              Navigator.pop(ctx);
              cargarTrampas();
            },
            child: Text(esEdicion ? "Guardar" : "Registrar"),
          )
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final ubicaciones = ['Todas', ...trampas.map((e) => e['ubicacion'].toString()).toSet()];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Ubicación'),
            value: filtroUbicacion,
            items: ubicaciones.map((zona) => DropdownMenuItem(value: zona, child: Text(zona))).toList(),
            onChanged: (val) => setState(() => filtroUbicacion = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Estado'),
            value: filtroEstado,
            items: ['Todas', 'Activa', 'Inactiva'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => filtroEstado = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Adhesivo'),
            value: filtroAdhesivo,
            items: ['Todas', 'Sí', 'No'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => filtroAdhesivo = val),
          ),
        ),
      ],
    );
  }

  Widget _buildTablaTrampas() {
    List<Map<String, dynamic>> trampasFiltradas = trampas.where((trampa) {
      if (filtroUbicacion != 'Todas' && trampa['ubicacion'] != filtroUbicacion) return false;
      if (filtroEstado != 'Todas' && trampa['status'] != estadoMap[filtroEstado]) return false;
      if (filtroAdhesivo != 'Todas' && (trampa['trampa_adhesiva'] == 1 ? 'Sí' : 'No') != filtroAdhesivo) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Ubicación')),
          DataColumn(label: Text('Adhesivo')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Última actividad')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: trampasFiltradas.map((trampa) => DataRow(cells: [
          DataCell(Text(trampa['trampa_id'].toString())),
          DataCell(Text(trampa['nombre'] ?? '')),
          DataCell(Text(trampa['ubicacion'] ?? '')),
            DataCell(
            Icon(
              int.parse(trampa['trampa_adhesiva'].toString()) == 1 ? Icons.check : Icons.close,
              color: int.parse(trampa['trampa_adhesiva'].toString()) == 1 ? Colors.green : Colors.red,
            )
          ),
          DataCell(Text(estadoEnEspanol(trampa['status']))),
          DataCell(Text(trampa['timestamp'].toString())),
          DataCell(Row(
            children: [
              IconButton(icon: Icon(Icons.edit, color: Colors.amber), onPressed: () => _mostrarFormularioTrampa(trampa: trampa)),
              IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => eliminarTrampa(trampa)),
            ],
          )),
        ])).toList(),
      ),
    );
  }

  String estadoEnEspanol(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'inactive':
        return 'Inactiva';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Gestión de Trampas", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioTrampa(),
        backgroundColor: AppTheme.primaryBlue,
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFiltros(),
            const SizedBox(height: 12),
            Expanded(child: _buildTablaTrampas()),
          ],
        ),
      ),
    );
  }
}
