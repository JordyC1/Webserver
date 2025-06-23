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
  int _currentPage = 1;
  int _itemsPerPage = 9;
  String? _selectedSort;
  String? _selectedFilterDate;
  bool _isLoading = false;
  Timer? _timer;
  String lastUpdateTime = "";
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> _fetchLecturas() async {
    Future<void> delay = Future.delayed(const Duration(milliseconds: 500));
    final responseFuture =
        http.get(Uri.parse("http://raspberrypi2.local/get_lecturas.php"));
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
        title: Text("Lecturas por Detección", style: TextStyle(color: AppTheme.textPrimary)),
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
              children: [_buildFilterDropdown(), _buildSortDropdown()],
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
      items: ["Hoy", "Última Semana", "Último Mes"]
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      hint: Text("Ordenar", style: TextStyle(color: AppTheme.textSecondary)),
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
        "Cantidad Ascendente",
        "Cantidad Descendente"
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                  DataColumn(label: Text("ID Detección")),
                  DataColumn(label: Text("ID Captura")),
                  DataColumn(label: Text("Tipo de Insecto")),
                  DataColumn(label: Text("Cantidad")),
                  DataColumn(label: Text("Fecha")),
                ],
                rows: paginatedLecturas.map((lectura) {
                  return DataRow(cells: [
                    DataCell(Text(lectura["id"].toString(), overflow: TextOverflow.ellipsis)),
                    DataCell(Text(lectura["captura_id"].toString(), overflow: TextOverflow.ellipsis)),
                    DataCell(Text(lectura["tipo"], overflow: TextOverflow.ellipsis)),
                    DataCell(Text(lectura["cantidad"].toString(), overflow: TextOverflow.ellipsis)),
                    DataCell(Text(lectura["fecha"], overflow: TextOverflow.ellipsis)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
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

      if (_selectedFilterDate != null) {
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

      if (_selectedSort != null) {
        if (_selectedSort == "ID Ascendente") {
          filteredLecturas.sort((a, b) => a["id"].compareTo(b["id"]));
        } else if (_selectedSort == "ID Descendente") {
          filteredLecturas.sort((a, b) => b["id"].compareTo(a["id"]));
        } else if (_selectedSort == "Cantidad Ascendente") {
          filteredLecturas.sort((a, b) => a["cantidad"].compareTo(b["cantidad"]));
        } else if (_selectedSort == "Cantidad Descendente") {
          filteredLecturas.sort((a, b) => b["cantidad"].compareTo(a["cantidad"]));
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
