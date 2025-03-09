import 'package:flutter/material.dart';
import '../widgets/side_menu.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Definir las diferentes páginas del menú
  final List<Widget> _pages = [
    DashboardScreen(),  // Ahora el Dashboard será la pantalla principal
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
      drawer: SideMenu(onItemTapped: _onItemTapped), // Menú lateral
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SmartTrap", style: TextStyle(color: Colors.black)),
            Icon(Icons.account_circle, color: Colors.grey.shade700, size: 28),
          ],
        ),
        elevation: 0,
      ),
      body: _pages[_selectedIndex], // Muestra la pantalla seleccionada
    );
  }
}
