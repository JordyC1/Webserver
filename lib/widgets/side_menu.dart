import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Function(int) onItemTapped;

  const SideMenu({super.key, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          // Encabezado del Menú
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report, size: 50, color: Colors.black),
                const SizedBox(height: 10),
                Text(
                  'SmartTrap',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Opciones del Menú
          _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
          _buildMenuItem(Icons.people, 'Usuarios', 1),
          _buildMenuItem(Icons.library_books, 'Ver Lecturas', 2),
          _buildMenuItem(Icons.notifications, 'Alertas', 3),
          _buildMenuItem(Icons.exit_to_app, 'Exportar', 4),
        ],
      ),
    );
  }

  // Método para construir un ítem del menú
  Widget _buildMenuItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        onItemTapped(index);
      },
    );
  }
}
