import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlagaAlertsScreen extends StatefulWidget {
  @override
  _PlagaAlertsScreenState createState() => _PlagaAlertsScreenState();
}

class _PlagaAlertsScreenState extends State<PlagaAlertsScreen> {
  List<dynamic> alertas = [];
  List<dynamic> alertasFiltradas = [];
  bool isLoading = true;

  final tiposInsecto = ['Hormiga', 'Cucaracha', 'Polilla', 'Mosca', 'Lasioderma', 'Todos'];
  final tiposAlerta = ['Deteccion individual', 'Aumento sostenido', 'Presencia crítica'];

  String? filtroTipoInsecto;
  String? filtroTipoAlerta;

  @override
  void initState() {
    super.initState();
    fetchAlertas();
  }

  Future<void> fetchAlertas() async {
    final res = await http.get(Uri.parse('http://raspberrypi2.local/get_configuracion_plagas.php'));
    if (res.statusCode == 200) {
      setState(() {
        alertas = json.decode(res.body);
        aplicarFiltros();
        isLoading = false;
      });
    }
  }

  void aplicarFiltros() {
    setState(() {
      alertasFiltradas = alertas.where((a) {
        final coincideTipoInsecto = filtroTipoInsecto == null || a['tipo_insecto'] == filtroTipoInsecto;
        final coincideTipoAlerta = filtroTipoAlerta == null || a['tipo_alerta'] == filtroTipoAlerta;
        return coincideTipoInsecto && coincideTipoAlerta;
      }).toList();
    });
  }

  Future<void> eliminarAlertaConfirmada(dynamic id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("¿Eliminar configuración?"),
        content: Text("¿Estás seguro de que deseas eliminar esta alerta de plaga? Esta acción no se puede deshacer."),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: Text("Eliminar"), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmar == true) {
      final res = await http.post(
        Uri.parse('http://raspberrypi2.local/delete_configuracion_plaga.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'id': id}),
      );
      if (res.statusCode == 200) {
        fetchAlertas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Configuración eliminada correctamente")),
        );
      }
    }
  }

  Future<void> cambiarEstado(dynamic id, String nuevoEstado) async {
    final res = await http.post(
      Uri.parse('http://raspberrypi2.local/update_configuracion_plagas.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id.toString(), 'estado': nuevoEstado}),
    );
    if (res.statusCode == 200) fetchAlertas();
  }

  void verMas(Map<String, dynamic> alerta) {
    final tipo = alerta['tipo_alerta'];
    final tipoInsecto = alerta['tipo_insecto'];
    final intervalo = alerta['intervalo_minutos'];
    final descripcion = alerta['descripcion'] ?? '';
    final umbral = alerta['umbral_promedio'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Detalle de configuración"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tipo de alerta: $tipo"),
            SizedBox(height: 8),
            Text("Insecto: $tipoInsecto"),
            if (tipo == "Aumento sostenido") ...[
              SizedBox(height: 8),
              Text("Intervalo (días): $intervalo"),
              SizedBox(height: 8),
              Text("Descripción: $descripcion"),
            ],
            if (tipo == "Deteccion individual") ...[
              SizedBox(height: 8),
              Text("Umbral promedio: $umbral"),
              SizedBox(height: 8),
              Text("Intervalo (minutos): $intervalo"),
            ],
            if (tipo == "Presencia crítica") ...[
              SizedBox(height: 8),
              Text("Descripción: $descripcion"),
            ],
          ],
        ),
        actions: [
          TextButton(child: Text("Cerrar"), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  bool esConfiguracionDuplicada(String tipo, String insecto, int intervalo, int umbral) {
    for (var alerta in alertas) {
      if (alerta['tipo_alerta'] != tipo) continue;

      if (tipo == 'Presencia crítica') {
        if (alerta['tipo_insecto'] == insecto) return true;
      } else if (tipo == 'Aumento sostenido') {
        if (alerta['tipo_insecto'] == insecto &&
            alerta['intervalo_minutos'].toString() == intervalo.toString()) {
          return true;
        }
      } else if (tipo == 'Deteccion individual') {
        if (alerta['tipo_insecto'] == insecto &&
            alerta['intervalo_minutos'].toString() == intervalo.toString() &&
            alerta['umbral_promedio'].toString() == umbral.toString()) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> agregarOEditarAlerta() async {
    String? tipoInsecto;
    String? tipoAlerta;
    String estado = 'activo';
    String descripcion = '';
    int umbral = 0;
    int intervalo = 1;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Agregar alerta'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: tipoAlerta,
                    decoration: InputDecoration(labelText: 'Tipo de Alerta'),
                    items: tiposAlerta.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setModalState(() => tipoAlerta = val),
                  ),
                  if (tipoAlerta != null)
                    DropdownButtonFormField<String>(
                      value: tipoInsecto,
                      decoration: InputDecoration(labelText: 'Tipo de Insecto'),
                      items: tiposInsecto
                          .where((t) => tipoAlerta != 'Presencia crítica' || t != 'Todos')
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setModalState(() => tipoInsecto = val),
                    ),
                  if (tipoAlerta == 'Deteccion individual')
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Umbral promedio'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => umbral = int.tryParse(val) ?? 0,
                    ),
                  if (tipoAlerta == 'Deteccion individual' || tipoAlerta == 'Aumento sostenido')
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: tipoAlerta == 'Aumento sostenido' ? 'Intervalo (días)' : 'Intervalo (minutos)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => intervalo = int.tryParse(val) ?? 1,
                    ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Descripción'),
                    onChanged: (val) => descripcion = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  if (tipoInsecto == null || tipoInsecto!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Debes seleccionar un tipo de insecto')),
                    );
                    return;
                  }

                  if ((tipoAlerta == 'Deteccion individual' || tipoAlerta == 'Aumento sostenido') &&
                      (intervalo <= 0 || (tipoAlerta == 'Deteccion individual' && umbral <= 0))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Umbral e intervalo deben ser mayores a 0')),
                    );
                    return;
                  }

                  if (esConfiguracionDuplicada(tipoAlerta!, tipoInsecto!, intervalo, umbral)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ya existe una configuración similar')),
                    );
                    return;
                  }

                  final body = {
                    'tipo_insecto': tipoInsecto,
                    'tipo_alerta': tipoAlerta ?? '',
                    'umbral_promedio': (tipoAlerta == 'Presencia crítica') ? '0' : umbral.toString(),
                    'intervalo_minutos': (tipoAlerta == 'Presencia crítica') ? '0' : intervalo.toString(),
                    'aplicar_por_trampa': '1',
                    'estado': estado,
                    'descripcion': descripcion
                  };

                  final response = await http.post(
                    Uri.parse('http://raspberrypi2.local/add_configuracion_plagas.php'),
                    body: body,
                  );

                  if (response.statusCode == 200) {
                    fetchAlertas();
                    Navigator.pop(context);
                  }
                },
                child: Text("Guardar"),
              ),
            ],
          );
        });
      },
    );
  }

  Widget buildAlertaItem(Map<String, dynamic> alerta) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        title: Text("${alerta['tipo_alerta']} - ${alerta['tipo_insecto']}"),
        subtitle: Text(alerta['descripcion'] ?? 'Sin descripción'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.power_settings_new,
                color: alerta['estado'] == 'activo' ? Colors.green : Colors.grey,
              ),
              tooltip: alerta['estado'] == 'activo' ? 'Desactivar' : 'Activar',
              onPressed: () {
                final nuevoEstado = alerta['estado'] == 'activo' ? 'inactivo' : 'activo';
                setState(() => alerta['estado'] = nuevoEstado);
                cambiarEstado(alerta['id'], nuevoEstado);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(nuevoEstado == 'activo' ? 'Alerta activada' : 'Alerta desactivada')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Ver más',
              onPressed: () => verMas(alerta),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar',
              onPressed: () => eliminarAlertaConfirmada(alerta['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mantenimiento de Alertas de Plaga"),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: () => agregarOEditarAlerta()),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filtroTipoAlerta,
                    hint: Text("Filtrar por tipo de alerta"),
                    items: [null, ...tiposAlerta].map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Text(e ?? 'Todos'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        filtroTipoAlerta = val;
                        aplicarFiltros();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filtroTipoInsecto,
                    hint: Text("Filtrar por insecto"),
                    items: [null, ...tiposInsecto].map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Text(e ?? 'Todos'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        filtroTipoInsecto = val;
                        aplicarFiltros();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : alertasFiltradas.isEmpty
              ? Center(child: Text("No hay alertas configuradas"))
              : ListView.builder(
                  itemCount: alertasFiltradas.length,
                  itemBuilder: (context, index) => buildAlertaItem(alertasFiltradas[index]),
                ),
    );
  }
}
