import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          title: const Text("Confirmar Cierre de Sesión"),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cerrar el diálogo sin cerrar sesión
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el diálogo antes de cerrar sesión
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
      icon: const Icon(Icons.account_circle, color: Colors.grey, size: 28),
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.blue),
              SizedBox(width: 10),
              Text("Manejar Cuenta"),
            ],
          ),
        ),
        const PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text("Cerrar Sesión"),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Función de manejo de cuenta no implementada")),
          );
        } else if (value == 2) {
          _showLogoutConfirmation(context); // Mostrar confirmación antes de cerrar sesión
        }
      },
    );
  }
}
