import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SideMenu extends StatelessWidget {
  final Function(int) onItemTapped;

  const SideMenu({super.key, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: <Widget>[
          // Encabezado del Menú
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bug_report, size: 50, color: AppTheme.primaryBlue),
                const SizedBox(height: 10),
                Text(
                  'SmartTrap',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
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
          _buildMenuItem(Icons.content_paste_search, 'Auditorias Imagenes', 5),
        ],
      ),
    );
  }

  // Método para construir un ítem del menú
  Widget _buildMenuItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title,
          style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
      onTap: () {
        onItemTapped(index);
      },
    );
  }
}
