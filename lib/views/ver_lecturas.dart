import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import 'dart:async';

class VerLecturasScreen extends StatefulWidget {
  @override
  _VerLecturasScreenState createState() => _VerLecturasScreenState();
}

class _VerLecturasScreenState extends State<VerLecturasScreen> {
  List<Map<String, dynamic>> lecturas = [];
  List<String> tiposInsectos = [];
  String? _selectedTipoInsecto;
  int _currentPage = 1;
  int _itemsPerPage = 8;
  String? _selectedSort;
  String? _selectedFilterDate;
  bool _isLoading = false;
  Timer? _timer;
  String lastUpdateTime = "";
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTiposInsectos();
    _fetchLecturas();
    _updateTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchLecturas();
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      lastUpdateTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _fetchTiposInsectos() async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/get_tipos_insectos.php"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "ok") {
        setState(() {
          tiposInsectos = ["Todas", ...List<String>.from(data["tipos"])];
        });
      }
    }
  }

  Future<void> _fetchLecturas() async {
    Future<void> delay = Future.delayed(const Duration(milliseconds: 500));
    final responseFuture =
        http.get(Uri.parse("http://raspberrypi2.local/get_historial_incrementos.php"));
    await delay;
    final response = await responseFuture;

    if (mounted) {
      setState(() {
        if (response.statusCode == 200) {
          lecturas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _applyFilters();
        } else {
          print("Error al obtener las lecturas: ${response.statusCode}");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Lecturas por Incremento", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: "Actualizar datos",
            onPressed: _fetchLecturas,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Última actualización: $lastUpdateTime",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [_buildFilterDropdown(), _buildSortDropdown(), _buildTipoDropdown()],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading ? _buildLoadingIndicator() : _buildTable(),
            ),
            const SizedBox(height: 10),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildFilterDropdown() {
    return DropdownButton<String>(
      hint: Text("Filtrar por Fecha", style: TextStyle(color: AppTheme.textSecondary)),
      value: _selectedFilterDate,
      dropdownColor: AppTheme.cardBackground,
      style: TextStyle(color: AppTheme.textPrimary),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
      onChanged: (value) {
        setState(() {
          _selectedFilterDate = value;
          _applyFilters();
        });
      },
      items: ["Todas", "Hoy", "Última Semana", "Último Mes"]
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      hint: Text("Ordenar por", style: TextStyle(color: AppTheme.textSecondary)),
      value: _selectedSort,
      dropdownColor: AppTheme.cardBackground,
      style: TextStyle(color: AppTheme.textPrimary),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
      onChanged: (value) {
        setState(() {
          _selectedSort = value;
          _applyFilters();
        });
      },
      items: [
        "Cantidad Ascendente",
        "Cantidad Descendente"
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _buildTipoDropdown() {
    return DropdownButton<String>(
      hint: Text("Filtrar por Tipo", style: TextStyle(color: AppTheme.textSecondary)),
      value: _selectedTipoInsecto,
      dropdownColor: AppTheme.cardBackground,
      style: TextStyle(color: AppTheme.textPrimary),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
      onChanged: (value) {
        setState(() {
          _selectedTipoInsecto = value;
          _applyFilters();
        });
      },
      items: tiposInsectos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _buildTable() {
    List<Map<String, dynamic>> paginatedLecturas = _getPaginatedLecturas();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Card(
              elevation: 2,
              color: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text("ID Trampa")),
                  DataColumn(label: Text("Tipo de Insecto")),
                  DataColumn(label: Text("Incremento")),
                  DataColumn(label: Text("Fecha")),
                  DataColumn(label: Text("Mostrar Captura")),
                ],
                rows: paginatedLecturas.map((lectura) {
                  return DataRow(cells: [
                    DataCell(Text(lectura["trampa_id"].toString())),
                    DataCell(Text(lectura["tipo"])),
                    DataCell(Text(lectura["incremento"].toString())),
                    DataCell(Text(lectura["fecha"].toString())),
                    DataCell(IconButton(
                      icon: Icon(Icons.image_search, color: AppTheme.primaryBlue),
                      onPressed: () {
                        _mostrarCaptura(lectura["fecha"]);
                      },
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarCaptura(String fecha) async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/mostrar_imagen_por_fecha.php?fecha=$fecha"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "found") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Captura relacionada"),
            content: Image.network(data["url"]),
            actions: [
              TextButton(
                child: const Text("Cerrar"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Sin imagen"),
            content: const Text("No se encontró imagen relacionada a esa fecha."),
            actions: [
              TextButton(
                child: const Text("Cerrar"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("No se pudo obtener la imagen desde el servidor."),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPaginationControls() {
    int totalPages = (lecturas.length / _itemsPerPage).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text("Página $_currentPage de $totalPages"),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ir a...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(_pageController.text);
                if (page != null && page > 0 && page <= totalPages) {
                  setState(() => _currentPage = page);
                }
              },
              child: const Text("Ir"),
            ),
          ],
        ),
      ],
    );
  }

  void _applyFilters() {
    setState(() {
      var filteredLecturas = List<Map<String, dynamic>>.from(lecturas);

      if (_selectedFilterDate != null && _selectedFilterDate != "Todas") {
        DateTime now = DateTime.now();
        DateTime filterDate;

        if (_selectedFilterDate == "Hoy") {
          filterDate = DateTime(now.year, now.month, now.day);
        } else if (_selectedFilterDate == "Última Semana") {
          filterDate = now.subtract(const Duration(days: 7));
        } else {
          filterDate = now.subtract(const Duration(days: 30));
        }

        filteredLecturas = filteredLecturas.where((lectura) {
          try {
            DateTime lecturaDate = DateTime.parse(lectura["fecha"]);
            if (_selectedFilterDate == "Hoy") {
              return lecturaDate.year == now.year &&
                  lecturaDate.month == now.month &&
                  lecturaDate.day == now.day;
            }
            return lecturaDate.isAfter(filterDate);
          } catch (_) {
            return false;
          }
        }).toList();
      }

      if (_selectedTipoInsecto != null && _selectedTipoInsecto != "Todas") {
        filteredLecturas = filteredLecturas.where((lectura) => lectura["tipo"] == _selectedTipoInsecto).toList();
      }

      if (_selectedSort != null) {
        if (_selectedSort == "Cantidad Ascendente") {
          filteredLecturas.sort((a, b) => a["incremento"].compareTo(b["incremento"]));
        } else if (_selectedSort == "Cantidad Descendente") {
          filteredLecturas.sort((a, b) => b["incremento"].compareTo(a["incremento"]));
        }
      }

      lecturas = filteredLecturas;
    });
  }

  List<Map<String, dynamic>> _getPaginatedLecturas() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    return lecturas.sublist(startIndex, endIndex > lecturas.length ? lecturas.length : endIndex);
  }
}
