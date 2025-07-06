import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class LecturasPorDeteccionScreen extends StatefulWidget {
  const LecturasPorDeteccionScreen({super.key});

  @override
  State<LecturasPorDeteccionScreen> createState() => _LecturasPorDeteccionScreenState();
}

class _LecturasPorDeteccionScreenState extends State<LecturasPorDeteccionScreen> {
  List<Map<String, dynamic>> lecturas = [];
  List<Map<String, dynamic>> filtradas = [];
  List<String> tiposInsectos = [];
  String? filtroTipo = "Todas";
  String filtroCaptura = '';
  String filtroFecha = '';
  int paginaActual = 1;
  int elementosPorPagina = 8;
  final TextEditingController pageController = TextEditingController();
  final TextEditingController capturaController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarLecturas();
  }

  Future<void> cargarLecturas() async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/get_lecturas.php"));
    if (response.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      setState(() {
        lecturas = data;
        tiposInsectos = ["Todas", ...{
          for (var l in data) l['tipo'].toString()
        }];
        filtradas = data;
        aplicarFiltros();
      });
    }
  }

  void aplicarFiltros() {
    setState(() {
      filtradas = lecturas.where((l) {
        final tipoMatch = filtroTipo == "Todas" || l['tipo'] == filtroTipo;
        final capturaMatch = filtroCaptura.isEmpty || l['captura_id'].toString().contains(filtroCaptura);
        final fechaMatch = filtroFecha.isEmpty || l['fecha'].toString().contains(filtroFecha);
        return tipoMatch && capturaMatch && fechaMatch;
      }).toList();
      paginaActual = 1;
    });
  }

  Future<void> eliminarLectura(int id, int capturaId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Desea eliminar esta detección?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar")),
        ],
      ),
    );
    if (confirm == true) {
      await http.post(Uri.parse("http://raspberrypi2.local/delete_lectura.php"),
        body: {'id': id.toString(), 'captura_id': capturaId.toString()},
      );
      cargarLecturas();
    }
  }

  Future<void> editarLectura(Map<String, dynamic> lectura) async {
    final TextEditingController tipoController = TextEditingController(text: lectura['tipo']);
    final TextEditingController cantidadController = TextEditingController(text: lectura['cantidad'].toString());

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Lectura"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tipoController,
              decoration: const InputDecoration(labelText: "Tipo de insecto"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cantidad"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Guardar")),
        ],
      ),
    );

    if (confirm == true) {
      await http.post(Uri.parse("http://raspberrypi2.local/editar_lectura.php"), body: {
        'id': lectura['id'].toString(),
        'tipo': tipoController.text,
        'cantidad': cantidadController.text
      });
      cargarLecturas();
    }
  }

  Future<void> mostrarDetalles(int id) async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/ver_detalle_lectura.php"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final lectura = data.firstWhere((l) => l["id"].toString() == id.toString(), orElse: () => null);

      if (lectura != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Detalles de la Detección"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tipo: ${lectura["tipo"]}"),
                Text("Proveniente de Trampa: ${lectura["nombre_trampa"]}"),
                Text("Cantidad: ${lectura["cantidad"]}"),
                Text("ID de Detección: ${lectura["id"]}"),
                Text("ID de Captura: ${lectura["captura_id"]}"),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))
            ],
          ),
        );
      }
    }
  }

  Widget _buildFiltros() {
    return Wrap(
      spacing: 20,
      children: [
        DropdownButton<String>(
          value: filtroTipo,
          hint: const Text("Filtrar por Insecto"),
          dropdownColor: AppTheme.cardBackground,
          style: TextStyle(color: AppTheme.textPrimary),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
          items: tiposInsectos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
          onChanged: (val) {
            setState(() {
              filtroTipo = val;
              aplicarFiltros();
            });
          },
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: capturaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Filtrar por ID Captura"),
            onChanged: (val) {
              setState(() {
                filtroCaptura = val;
                aplicarFiltros();
              });
            },
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: fechaController,
            decoration: const InputDecoration(labelText: "Filtrar por Fecha"),
            onChanged: (val) {
              setState(() {
                filtroFecha = val;
                aplicarFiltros();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabla() {
    final totalPaginas = (filtradas.length / elementosPorPagina).ceil();
    final inicio = (paginaActual - 1) * elementosPorPagina;
    final fin = (inicio + elementosPorPagina > filtradas.length) ? filtradas.length : inicio + elementosPorPagina;
    final visibles = filtradas.sublist(inicio, fin);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("ID Captura")),
              DataColumn(label: Text("Tipo")),
              DataColumn(label: Text("Cantidad")),
              DataColumn(label: Text("Fecha")),
              DataColumn(label: Text("Acciones")),
            ],
            rows: visibles.map((l) => DataRow(cells: [
              DataCell(Text(l['id'].toString())),
              DataCell(Text(l['captura_id'].toString())),
              DataCell(Text(l['tipo'])),
              DataCell(Text(l['cantidad'].toString())),
              DataCell(Text(l['fecha'].toString())),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info, color: Colors.blue),
                    onPressed: () => mostrarDetalles(int.parse(l["id"].toString())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber),
                    onPressed: () => editarLectura(l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => eliminarLectura(
                      int.parse(l['id'].toString()),
                      int.parse(l['captura_id'].toString()),
                    ),
                  ),
                ],
              )),
            ])).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginacion() {
    final totalPaginas = (filtradas.length / elementosPorPagina).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: paginaActual > 1 ? () => setState(() => paginaActual--) : null,
        ),
        Text("Página $paginaActual de $totalPaginas"),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: paginaActual < totalPaginas ? () => setState(() => paginaActual++) : null,
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 80,
          child: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ir a...', isDense: true),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            final p = int.tryParse(pageController.text);
            if (p != null && p > 0 && p <= totalPaginas) {
              setState(() => paginaActual = p);
            }
          },
          child: const Text("Ir"),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: const Text("Lecturas por Detección"),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFiltros(),
            const SizedBox(height: 10),
            Expanded(child: _buildTabla()),
            const SizedBox(height: 10),
            _buildPaginacion(),
          ],
        ),
      ),
    );
  }
}
