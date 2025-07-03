import 'package:flutter/material.dart';
import 'usuarios_screen.dart';
import '../theme/app_theme.dart';
import 'trampas_screen.dart';

class MantenimientoScreen extends StatelessWidget {
  const MantenimientoScreen({super.key});

  Widget _buildCard(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppTheme.primaryBlue),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Panel de Mantenimiento", style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 250).floor();
            return GridView.count(
              crossAxisCount: crossAxisCount > 1 ? crossAxisCount : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildCard("Usuarios", "Gestionar cuentas de acceso", Icons.person, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UsuariosScreen()),
                  );
                }),
                _buildCard("Trampas", "Editar o registrar trampas", Icons.wifi, () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TrampasScreen()),
                  );
                }),
                _buildCard("Lecturas", "Ver y administrar capturas", Icons.analytics_outlined, () {
                  // Navegar a pantalla de lecturas
                }),
                _buildCard("Alertas", "Revisar historial y estados", Icons.warning_amber, () {
                  // Navegar a pantalla de alertas
                }),
                _buildCard("Ubicaciones", "Zonas o sectores monitoreados", Icons.map_outlined, () {
                  // Navegar a zonas
                }),
                _buildCard("Mantenimiento físico", "Cambios de trampa, limpieza, notas", Icons.build, () {
                  // Navegar a historial de mantenimiento
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
