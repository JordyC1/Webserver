import 'package:flutter/material.dart';
import '../widgets/side_menu.dart';
import '../widgets/user_menu.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'ver_lecturas.dart';
import 'usuarios_screen.dart'; // ✅ Importamos la nueva pantalla
import 'alertas_screen.dart'; // Importar la nueva pantalla

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isHovered = false; // Controla el efecto hover

  final List<Widget> _pages = [
    DashboardScreen(),
    UsuariosScreen(), // ✅ Se agregó la pantalla de administración de usuarios
    VerLecturasScreen(),
    AlertasScreen(), // Agregar la pantalla de alertas
    const Center(child: Text("Exportar", style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(
          context); // Cierra el Drawer después de seleccionar una opción
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(onItemTapped: _onItemTapped),
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SmartTrap", style: TextStyle(color: AppTheme.textPrimary)),

            // Efecto hover en el icono de usuario
            MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered ? AppTheme.dividerColor : Colors.transparent,
                ),
                padding: const EdgeInsets.all(5),
                child: const UserMenu(), // Usa el menú emergente de usuario
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
    );
  }
}
