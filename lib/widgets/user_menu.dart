import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../views/login_screen.dart';

class UserMenu extends StatelessWidget {
  const UserMenu({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token"); // Borra el token de sesión

    // Redirigir al login y eliminar historial de navegación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // Método para mostrar el diálogo de confirmación
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text("Confirmar Cierre de Sesión",
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Text("¿Estás seguro de que deseas cerrar sesión?",
              style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Cerrar el diálogo sin cerrar sesión
              child: Text("No", style: TextStyle(color: AppTheme.primaryBlue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Cerrar el diálogo antes de cerrar sesión
                _logout(context); // Cerrar sesión
              },
              child: const Text("Sí", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.account_circle, color: AppTheme.primaryBlue, size: 28),
      color: AppTheme.cardBackground,
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.settings, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              Text("Manejar Cuenta",
                  style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 10),
              Text("Cerrar Sesión",
                  style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Función de manejo de cuenta no implementada")),
          );
        } else if (value == 2) {
          _showLogoutConfirmation(
              context); // Mostrar confirmación antes de cerrar sesión
        }
      },
    );
  }
}
