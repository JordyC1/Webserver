import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SideMenu extends StatelessWidget {
  final Function(int) onItemTapped;

  const SideMenu({super.key, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
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

          // Menú principal
          _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
         // _buildMenuItem(Icons.people, 'Usuarios', 1),

          // Nuevo apartado: Panel de Plagas
          _buildMenuItem(Icons.pest_control, 'Panel de Plagas', 7),

          // Menú expandible de Lecturas
            ExpansionTile(
              leading: Icon(Icons.library_books, color: AppTheme.primaryBlue),
              title: Text('Lecturas', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
              children: [
                ListTile(
                  leading: Icon(Icons.bug_report_outlined, color: AppTheme.primaryBlue),
                  contentPadding: const EdgeInsets.only(left: 40.0),
                  title: Text('Por Detección', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  onTap: () => onItemTapped(1),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: AppTheme.primaryBlue),
                  contentPadding: const EdgeInsets.only(left: 40.0),
                  title: Text('Por Captura', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  onTap: () => onItemTapped(5),
                ),
              ],
            ),

          _buildMenuItem(Icons.notifications, 'Historial de Alertas', 2),
          _buildMenuItem(Icons.exit_to_app, 'Exportar', 3),
          _buildMenuItem(Icons.content_paste_search, 'Auditorias Imagenes', 4),
          //_buildMenuItem(Icons.settings, 'Configuración de Indicadores', 7),
          _buildMenuItem(Icons.build, 'Mantenimiento', 6),
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
