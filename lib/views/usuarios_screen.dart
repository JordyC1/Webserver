import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class UsuariosScreen extends StatefulWidget {
  @override
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> usuarios = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String? _selectedRole;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadEmailAndFetchUsuarios();
  }

  Future<void> _loadEmailAndFetchUsuarios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentEmail = prefs.getString("email");
    await _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);

    final response =
        await http.get(Uri.parse("http://raspberrypi2.local/get_usuarios.php"));

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        usuarios = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print("Error al obtener los usuarios: ${response.statusCode}");
      }
    });
  }

  Future<void> _deleteUsuario(String userId) async {
    final response = await http.post(
      Uri.parse("http://raspberrypi2.local/delete_usuario.php"),
      body: {"id": userId},
    );

    if (response.statusCode == 200) {
      _fetchUsuarios();
    } else {
      print("Error al eliminar usuario: ${response.statusCode}");
    }
  }

  List<Map<String, dynamic>> _getFilteredUsuarios() {
    var filteredList = usuarios.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user["email"].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRole == null || user["rol"] == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();

    filteredList.sort((a, b) => a["id"].compareTo(b["id"]));
    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Administración de Usuarios",
            style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: "Actualizar datos",
            onPressed: _fetchUsuarios,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchAndFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading ? _buildLoadingIndicator() : _buildUserTable(),
            ),
            if (_currentEmail == "admin@admin.com") _buildAddUserButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Buscar por nombre o correo",
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          hint: Text("Filtrar por rol",
              style: TextStyle(color: AppTheme.textSecondary)),
          value: _selectedRole,
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
          items: [
            DropdownMenuItem(
              value: null,
              child: Text("Sin filtro",
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ...["Admin", "Usuario"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTable() {
    List<Map<String, dynamic>> filteredUsuarios = _getFilteredUsuarios();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text("ID")),
            DataColumn(label: Text("Correo Electrónico")),
            DataColumn(label: Text("Rol")),
            DataColumn(label: Text("Acciones")),
          ],
          rows: filteredUsuarios.map((usuario) {
            return DataRow(cells: [
              DataCell(Text(usuario["id"].toString())),
              DataCell(Text(usuario["email"])),
              DataCell(Text(usuario["rol"])),
              DataCell(
                _currentEmail == "admin@admin.com"
                    ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          _confirmDelete(usuario["id"]);
                        },
                      )
                    : const SizedBox(),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAddUserButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Funcionalidad para agregar usuario
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Agregar Usuario",
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Usuario"),
        content:
            const Text("¿Estás seguro de que deseas eliminar este usuario?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUsuario(userId);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
