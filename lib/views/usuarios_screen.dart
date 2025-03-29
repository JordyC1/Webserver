import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  // 📌 Método para obtener los usuarios desde PHP
  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);

    final response =
        await http.get(Uri.parse("http://raspberrypi2.local/get_usuarios.php"));

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        usuarios = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print("Error al obtener los usuarios: \${response.statusCode}");
      }
    });
  }

  // 📌 Método para eliminar usuario
  Future<void> _deleteUsuario(String userId) async {
    final response = await http.post(
      Uri.parse("http://raspberrypi2.local/delete_usuario.php"),
      body: {"id": userId},
    );

    if (response.statusCode == 200) {
      _fetchUsuarios(); // Recargar datos tras eliminar usuario
    } else {
      print("Error al eliminar usuario: \${response.statusCode}");
    }
  }

  // 📌 Método para filtrar la lista de usuarios
  List<Map<String, dynamic>> _getFilteredUsuarios() {
    var filteredList = usuarios.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user["email"].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRole == null || user["rol"] == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();

    // Ordenar por ID de forma ascendente
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
                child:
                    _isLoading ? _buildLoadingIndicator() : _buildUserTable()),
            _buildAddUserButton(),
          ],
        ),
      ),
    );
  }

  // 📌 Indicador de carga
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // 📌 Barra de búsqueda y filtro por rol
  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Buscar por nombre o correo
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

        // Filtro por rol
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

  // 📌 Construcción de la tabla de usuarios
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
              DataCell(IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  _confirmDelete(usuario["id"]);
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // 📌 Botón para agregar usuario
  Widget _buildAddUserButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Implementar función de agregar usuario
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

  // 📌 Confirmar eliminación de usuario
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
