import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class MantenimientoFisicoScreen extends StatefulWidget {
  @override
  _MantenimientoFisicoScreenState createState() => _MantenimientoFisicoScreenState();
}

class _MantenimientoFisicoScreenState extends State<MantenimientoFisicoScreen> {
  String? selectedTrampa;
  String? selectedTipo;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _notasController = TextEditingController();

  List<Map<String, dynamic>> mantenimientos = [];
  final List<String> tiposMantenimiento = [
    "Cambio de trampa",
    "Limpieza",
    "Nota de observación",
    "Inspección general"
  ];

  List<String> trampasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _fetchMantenimientos();
    _fetchTrampasDisponibles();
  }

  Future<void> _fetchMantenimientos() async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/mantenimiento_fisico.php"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        mantenimientos = data.map((e) => {
          "id": int.tryParse(e["id"].toString()) ?? 0,
          "trampa": e["nombre_trampa"] ?? "Trampa ID ${e["trampa_id"]}",
          "tipo": e["tipo_mantenimiento"],
          "fecha": e["fecha"],
          "notas": e["notas"] ?? ""
        }).toList();
      });
    }
  }

  Future<void> _fetchTrampasDisponibles() async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/get_trampas_disponibles.php"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        trampasDisponibles = data.map((e) => e.toString()).toList();
      });
    }
  }

  Future<void> _registrarMantenimiento() async {
    if (selectedTrampa != null && selectedTipo != null) {
      final response = await http.post(
        Uri.parse("http://raspberrypi2.local/mantenimiento_fisico.php"),
        body: {
          "action": "insertar",
          "trampa_id": selectedTrampa,
          "tipo_mantenimiento": selectedTipo,
          "notas": _notasController.text,
          "fecha": selectedDate.toIso8601String(),
        },
      );
      if (response.statusCode == 200) {
        _fetchMantenimientos();
        setState(() {
          selectedTrampa = null;
          selectedTipo = null;
          _notasController.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor completa todos los campos obligatorios.")),
      );
    }
  }

  Future<void> _confirmarEliminar(int id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Eliminar mantenimiento?"),
        content: Text("¿Estás seguro de que deseas eliminar este mantenimiento?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Eliminar"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _eliminarMantenimiento(id);
    }
  }

  Future<void> _eliminarMantenimiento(int id) async {
    final response = await http.post(
      Uri.parse("http://raspberrypi2.local/mantenimiento_fisico.php"),
      body: {
        "action": "eliminar",
        "id": id.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          mantenimientos.removeWhere((m) => m["id"] == id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar el mantenimiento.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Mantenimiento Físico", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Registrar mantenimiento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedTrampa,
                      hint: Text("Seleccionar Trampa"),
                      items: trampasDisponibles
                          .map((id) => DropdownMenuItem(value: id, child: Text("Trampa ID $id")))
                          .toList(),
                      onChanged: (val) => setState(() => selectedTrampa = val),
                    ),
                    DropdownButton<String>(
                      value: selectedTipo,
                      hint: Text("Tipo de Mantenimiento"),
                      items: tiposMantenimiento
                          .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedTipo = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notasController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Notas u observaciones",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Fecha: ${selectedDate.toLocal().toString().split(' ')[0]}", style: TextStyle(color: AppTheme.textSecondary)),
                        Spacer(),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Text("Cambiar fecha"),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _registrarMantenimiento,
                      child: Text("Registrar"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Historial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: mantenimientos.length,
                itemBuilder: (context, index) {
                  final item = mantenimientos[index];
                  return Card(
                    color: AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.build, color: AppTheme.primaryBlue),
                      title: Text("${item["tipo"]} en ${item["trampa"]}"),
                      subtitle: Text("${item["fecha"]}\n${item["notas"]}"),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final id = item["id"];
                          if (id is int) {
                            _confirmarEliminar(id);
                          } else {
                            print("ID inválido: $id");
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
