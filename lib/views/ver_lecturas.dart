import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLecturas();
  }

  // 📌 Método para obtener las lecturas desde PHP
  Future<void> _fetchLecturas() async {
    setState(() => _isLoading = true);

    final response =
        await http.get(Uri.parse("http://raspberrypi2.local/get_lecturas.php"));

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        lecturas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print("Error al obtener las lecturas: ${response.statusCode}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title:
            Text("Ver Lecturas", style: TextStyle(color: AppTheme.textPrimary)),
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
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(
                child: _isLoading ? _buildLoadingIndicator() : _buildTable()),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  // 📌 Indicador de carga mientras se actualizan los datos
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // 📌 Barra de filtros
  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Filtro por fecha
        DropdownButton<String>(
          hint: Text("Filtrar por Fecha",
              style: TextStyle(color: AppTheme.textSecondary)),
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
        ),

        // Ordenar por ID o cantidad
        DropdownButton<String>(
          hint:
              Text("Ordenar", style: TextStyle(color: AppTheme.textSecondary)),
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
        ),
      ],
    );
  }

  // 📌 Construcción de la tabla de lecturas con fecha
  Widget _buildTable() {
    List<Map<String, dynamic>> paginatedLecturas = _getPaginatedLecturas();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // Adaptación responsiva
        child: Card(
          elevation: 2,
          color: AppTheme.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text("ID Detección")),
              DataColumn(label: Text("ID Captura")),
              DataColumn(label: Text("Tipo de Insecto")),
              DataColumn(label: Text("Cantidad")),
              DataColumn(label: Text("Fecha")), // Nueva columna de fecha
            ],
            rows: paginatedLecturas.map((lectura) {
              return DataRow(cells: [
                DataCell(Text(lectura["id"].toString())),
                DataCell(Text(lectura["captura_id"].toString())),
                DataCell(Text(lectura["tipo"])),
                DataCell(Text(lectura["cantidad"].toString())),
                DataCell(Text(lectura["fecha"])), // Muestra la fecha
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 📌 Controles de paginación
  Widget _buildPaginationControls() {
    int totalPages = (lecturas.length / _itemsPerPage).ceil();

    return Row(
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
      ],
    );
  }

  // 📌 Método para filtrar y ordenar los datos antes de mostrarlos
  void _applyFilters() {
    setState(() {
      // Filtrar por fecha
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

        lecturas = lecturas.where((lectura) {
          DateTime lecturaDate = DateTime.parse(lectura["fecha"]);
          return lecturaDate.isAfter(filterDate);
        }).toList();
      }

      // Ordenar por ID o cantidad
      if (_selectedSort != null) {
        if (_selectedSort == "ID Ascendente") {
          lecturas.sort((a, b) => a["id"].compareTo(b["id"]));
        } else if (_selectedSort == "ID Descendente") {
          lecturas.sort((a, b) => b["id"].compareTo(a["id"]));
        } else if (_selectedSort == "Cantidad Ascendente") {
          lecturas.sort((a, b) => a["cantidad"].compareTo(b["cantidad"]));
        } else if (_selectedSort == "Cantidad Descendente") {
          lecturas.sort((a, b) => b["cantidad"].compareTo(a["cantidad"]));
        }
      }
    });
  }

  // 📌 Método para obtener los datos paginados
  List<Map<String, dynamic>> _getPaginatedLecturas() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    return lecturas.sublist(
        startIndex, endIndex > lecturas.length ? lecturas.length : endIndex);
  }
}
