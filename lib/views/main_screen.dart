import 'package:flutter/material.dart';
import '../widgets/side_menu.dart';
import '../widgets/user_menu.dart'; // Importamos el nuevo menú
import 'dashboard_screen.dart';

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
    const Center(child: Text("Usuarios", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Mantenimiento", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Alertas", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Exportar", style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer después de seleccionar una opción
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(onItemTapped: _onItemTapped),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SmartTrap", style: TextStyle(color: Colors.black)),

            // Efecto hover en el icono de usuario
            MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered ? Colors.grey.shade300 : Colors.transparent,
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
