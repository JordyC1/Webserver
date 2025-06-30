import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import 'dart:async';

class VerCapturasScreen extends StatefulWidget {
  @override
  _VerCapturasScreenState createState() => _VerCapturasScreenState();
}

class _VerCapturasScreenState extends State<VerCapturasScreen> {
  List<Map<String, dynamic>> capturas = [];
  List<int> trampasDisponibles = [];
  int _currentPage = 1;
  int _itemsPerPage = 8;
  String? _selectedSort;
  String? _selectedFilterDate;
  int? _selectedTrampaId;
  bool _isLoading = false;
  Timer? _timer;
  String lastUpdateTime = "";
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCapturas();
    _fetchTrampasDisponibles();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchCapturas();
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

  Future<void> _fetchCapturas() async {
    Future<void> delay = Future.delayed(const Duration(milliseconds: 500));
    final responseFuture =
        http.get(Uri.parse("http://raspberrypi2.local/get_capturas.php"));
    await delay;
    final response = await responseFuture;

    if (mounted) {
      setState(() {
        if (response.statusCode == 200) {
          capturas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _applyFilters();
        } else {
          print("Error al obtener las capturas: ${response.statusCode}");
        }
      });
    }
  }

  Future<void> _fetchTrampasDisponibles() async {
    final response = await http.get(Uri.parse("http://raspberrypi2.local/get_trampas_disponibles.php"));
    if (response.statusCode == 200) {
      setState(() {
        trampasDisponibles = List<int>.from(jsonDecode(response.body));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Lecturas por Captura", style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: "Actualizar datos",
            onPressed: () {
              _fetchCapturas();
              _fetchTrampasDisponibles();
            },
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
              children: [_buildFilterDropdown(), _buildTrampaDropdown(), _buildSortDropdown()],
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

  Widget _buildTrampaDropdown() {
    return DropdownButton<int?>(
      hint: Text("Filtrar por Trampa", style: TextStyle(color: AppTheme.textSecondary)),
      value: _selectedTrampaId,
      dropdownColor: AppTheme.cardBackground,
      style: TextStyle(color: AppTheme.textPrimary),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
      onChanged: (value) {
        setState(() {
          _selectedTrampaId = value;
          _applyFilters();
        });
      },
      items: [null, ...trampasDisponibles].map((id) {
        return DropdownMenuItem(
          value: id,
          child: Text(id == null ? "Todas" : "Trampa ID $id"),
        );
      }).toList(),
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
      items: ["Todos", "Hoy", "Última Semana", "Último Mes"]
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
        "ID Ascendente",
        "ID Descendente",
        "Total Insectos Ascendente",
        "Total Insectos Descendente",
        "Fecha Ascendente",
        "Fecha Descendente"
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _buildTable() {
    List<Map<String, dynamic>> paginatedCapturas = _getPaginatedCapturas();

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
                  DataColumn(label: Text("ID Captura")),
                  DataColumn(label: Text("ID Trampa")),
                  DataColumn(label: Text("Total Insectos")),
                  DataColumn(label: Text("Fecha")),
                  DataColumn(label: Text("Insectos Detallados")),
                  DataColumn(label: Text("Mostrar Captura")),
                ],
                rows: paginatedCapturas.map((captura) {
                  return DataRow(cells: [
                    DataCell(Text(captura["id"].toString())),
                    DataCell(Text(captura["trampa_id"].toString())),
                    DataCell(Text(captura["total_insectos"].toString())),
                    DataCell(Text(captura["fecha"].toString())),
                    DataCell(Text(_formatearInsectos(captura["insectos"]))),
                    DataCell(
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _mostrarImagenPorId(captura["id"]),
                          child: Text("Mostrar", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatearInsectos(dynamic insectos) {
    if (insectos == null || insectos is! List) return "-";
    return insectos.map((e) => "${e["tipo"]} (${e["cantidad"]})").join(", ");
  }

  void _mostrarImagenPorId(int capturaId) async {
    final url = Uri.parse("http://raspberrypi2.local/mostrar_imagenes_captura.php?captura_id=$capturaId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "found") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(content: Image.network(data["url"])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imagen no encontrada para esta captura")),
        );
      }
    }
  }

  Widget _buildPaginationControls() {
    int totalPages = (capturas.length / _itemsPerPage).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
        ),
        Text("Página $_currentPage de $totalPages"),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ir a...', isDense: true),
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
    );
  }

  void _applyFilters() {
    setState(() {
      var filtered = List<Map<String, dynamic>>.from(capturas);

      if (_selectedFilterDate != null && _selectedFilterDate != "Todos") {
        DateTime now = DateTime.now();
        DateTime filterDate;

        if (_selectedFilterDate == "Hoy") {
          filterDate = DateTime(now.year, now.month, now.day);
        } else if (_selectedFilterDate == "Última Semana") {
          filterDate = now.subtract(const Duration(days: 7));
        } else {
          filterDate = now.subtract(const Duration(days: 30));
        }

        filtered = filtered.where((c) {
          try {
            DateTime date = DateTime.parse(c["fecha"]);
            if (_selectedFilterDate == "Hoy") {
              return date.year == now.year && date.month == now.month && date.day == now.day;
            }
            return date.isAfter(filterDate);
          } catch (_) {
            return false;
          }
        }).toList();
      }

      if (_selectedTrampaId != null) {
        filtered = filtered.where((c) => c["trampa_id"] == _selectedTrampaId).toList();
      }

      if (_selectedSort != null) {
        switch (_selectedSort) {
          case "ID Ascendente":
            filtered.sort((a, b) => a["id"].compareTo(b["id"]));
            break;
          case "ID Descendente":
            filtered.sort((a, b) => b["id"].compareTo(a["id"]));
            break;
          case "Total Insectos Ascendente":
            filtered.sort((a, b) => a["total_insectos"].compareTo(b["total_insectos"]));
            break;
          case "Total Insectos Descendente":
            filtered.sort((a, b) => b["total_insectos"].compareTo(a["total_insectos"]));
            break;
          case "Fecha Ascendente":
            filtered.sort((a, b) => DateTime.parse(a["fecha"]).compareTo(DateTime.parse(b["fecha"])));
            break;
          case "Fecha Descendente":
            filtered.sort((a, b) => DateTime.parse(b["fecha"]).compareTo(DateTime.parse(a["fecha"])));
            break;
        }
      }

      capturas = filtered;
    });
  }

  List<Map<String, dynamic>> _getPaginatedCapturas() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    return capturas.sublist(startIndex, endIndex > capturas.length ? capturas.length : endIndex);
  }
}
