import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../theme/app_theme.dart';

class AuditoriaScreen extends StatefulWidget {
  @override
  _AuditoriaScreenState createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<String>> imagenesPorHora = {};
  String? horaSeleccionada;
  bool isLoading = false;
  int? imagenActualIndex;
  List<String> imagenesSeleccionadas = [];

  int imagenesPorPagina = 10;
  int paginaActual = 0;

  final String baseUrl = 'http://raspberrypi2.local/auditoria/auditoria';

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  Future<void> _cargarImagenes() async {
    setState(() {
      isLoading = true;
      horaSeleccionada = null;
      imagenesSeleccionadas = [];
      imagenesPorHora = {};
    });

    final fechaStr = _formatoFecha(selectedDate);

    try {
      final response = await http.get(Uri.parse("http://raspberrypi2.local/get_imagenes_auditoria.php?fecha=$fechaStr"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, List<String>> organizadas = {};

        for (var hora in data.keys) {
          List<String> lista = List<String>.from(data[hora]);
          organizadas[hora] = lista;
        }

        setState(() {
          imagenesPorHora = organizadas;
        });
      } else {
        print("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al conectar: $e");
    }

    setState(() => isLoading = false);
  }

  String _formatoFecha(DateTime fecha) => "${fecha.year}-${_twoDigits(fecha.month)}-${_twoDigits(fecha.day)}";

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        selectedDate = fecha;
      });
      await _cargarImagenes();
    }
  }

  void _abrirImagenModal(int index, List<String> imagenes) {
    imagenActualIndex = index;
    imagenesSeleccionadas = imagenes;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final nombreArchivo = imagenesSeleccionadas[imagenActualIndex!];
          final hora = horaSeleccionada!;
          final url = "$baseUrl/${_formatoFecha(selectedDate)}/$hora/$nombreArchivo";

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.black87,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * 0.95;
                final height = constraints.maxHeight * 0.95;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          width: width,
                          height: height,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: imagenActualIndex! > 0
                              ? () {
                                  setState(() => imagenActualIndex = imagenActualIndex! - 1);
                                }
                              : null,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final anchor = html.AnchorElement(href: url)
                              ..download = nombreArchivo
                              ..click();
                          },
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text("Descargar", style: TextStyle(color: Colors.white)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: imagenActualIndex! < imagenesSeleccionadas.length - 1
                              ? () {
                                  setState(() => imagenActualIndex = imagenActualIndex! + 1);
                                }
                              : null,
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<String> _obtenerPaginaActual(List<String> todas) {
    final inicio = paginaActual * imagenesPorPagina;
    final fin = (inicio + imagenesPorPagina).clamp(0, todas.length);
    return todas.sublist(inicio, fin);
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto = _formatoFecha(selectedDate);
    final horasDisponibles = imagenesPorHora.keys.toList();
    final imagenesMostrar = horaSeleccionada != null
        ? imagenesPorHora[horaSeleccionada]?.cast<String>() ?? []
        : [];
    final imagenesPagina = _obtenerPaginaActual(imagenesMostrar.cast<String>());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Auditoría de Imágenes", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
            onPressed: () => _seleccionarFecha(context),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : imagenesPorHora.isEmpty
              ? Center(
                  child: Text(
                    "No hay imágenes disponibles para esta fecha",
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("Fecha seleccionada: $fechaTexto",
                          style: TextStyle(color: AppTheme.textPrimary)),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: horasDisponibles.map((hora) {
                            final seleccionada = hora == horaSeleccionada;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text("Hora: $hora:00"),
                                selected: seleccionada,
                                selectedColor: AppTheme.primaryBlue,
                                onSelected: (_) => setState(() {
                                  horaSeleccionada = hora;
                                  paginaActual = 0;
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Mostrando ${imagenesPagina.length} de ${imagenesMostrar.length}",
                              style: TextStyle(color: AppTheme.textSecondary)),
                          DropdownButton<int>(
                            value: imagenesPorPagina,
                            dropdownColor: AppTheme.cardBackground,
                            items: [5, 10, 15]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text("$e por página",
                                          style: TextStyle(color: AppTheme.textPrimary)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                imagenesPorPagina = value!;
                                paginaActual = 0;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: imagenesPagina.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width ~/ 150,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.5,
                        ),
                        itemBuilder: (context, index) {
                          final nombre = imagenesPagina[index];
                          final hora = horaSeleccionada!;
                          final url = "$baseUrl/$fechaTexto/$hora/$nombre";
                          final horaTexto = nombre
                              .split("_")
                              .last
                              .replaceAll(".jpg", "")
                              .replaceAll("-", ":");

                          return InkWell(
                            onTap: () => _abrirImagenModal(index, imagenesPagina.cast<String>()),
                            hoverColor: Colors.transparent,
                            mouseCursor: SystemMouseCursors.click,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Container(
                                  color: Colors.black54,
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  child: Text(horaTexto,
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (imagenesMostrar.length > imagenesPorPagina)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                              onPressed: paginaActual > 0
                                  ? () => setState(() => paginaActual--)
                                  : null,
                            ),
                            Text(
                              "Página ${paginaActual + 1} de ${(imagenesMostrar.length / imagenesPorPagina).ceil()}",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward, color: AppTheme.primaryBlue),
                              onPressed: (paginaActual + 1) * imagenesPorPagina < imagenesMostrar.length
                                  ? () => setState(() => paginaActual++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
