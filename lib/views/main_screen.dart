import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/side_menu.dart';
import '../widgets/user_menu.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'ver_lecturas.dart';
import 'usuarios_screen.dart';
import 'alertas_screen.dart';
import 'historial_alertas_screen.dart';
import 'exportar_screen.dart';
import 'auditoriascreen.dart';
import 'ver_capturas.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isHovered = false;
  String _nombreUsuario = '';
  String _correoUsuario = '';

  final List<Widget> _pages = [
    DashboardScreen(),
    UsuariosScreen(),
    VerLecturasScreen(),
   // AlertasScreen(),
    HistorialAlertasScreen(),
    ExportarScreen(),
    AuditoriaScreen(),
    VerCapturasScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _correoUsuario = prefs.getString("email") ?? '';
      _nombreUsuario = prefs.getString("nombre") ??
          ''; // asegúrate de guardar esto al iniciar sesión
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    String saludo =
        "Bienvenido, ${_nombreUsuario.isNotEmpty ? _nombreUsuario : _correoUsuario}";

    return Scaffold(
      drawer: SideMenu(onItemTapped: _onItemTapped),
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SmartTrap", style: TextStyle(color: AppTheme.textPrimary)),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    saludo,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHovered
                          ? AppTheme.dividerColor
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: const UserMenu(),
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
    );
  }
}
