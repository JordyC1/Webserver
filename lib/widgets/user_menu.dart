import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../theme/app_theme.dart';
import '../views/login_screen.dart';
import '../views/change_username.dart';
import '../views/change_password.dart';

class UserMenu extends StatelessWidget {
  const UserMenu({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("email");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentEmail = prefs.getString("email");

    if (currentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el usuario actual")),
      );
      return;
    }

    final response = await http.get(Uri.parse("http://raspberrypi2.local/get_usuarios.php"));

    if (response.statusCode == 200) {
      List usuarios = jsonDecode(response.body);
      var currentUser = usuarios.firstWhere(
        (u) => u["email"] == currentEmail,
        orElse: () => null,
      );

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no encontrado")),
        );
        return;
      }

      final userId = currentUser["id"].toString();

      final deleteResponse = await http.post(
        Uri.parse("http://raspberrypi2.local/delete_usuario.php"),
        body: {"id": userId},
      );

      final deleteResult = jsonDecode(deleteResponse.body);

      if (deleteResult["success"] == true) {
        _logout(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${deleteResult["message"]}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al obtener los usuarios")),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Eliminar Cuenta",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text("Cancelar", style: TextStyle(color: AppTheme.primaryBlue)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
            },
          ),
        ],
      ),
    );
  }

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
              onPressed: () => Navigator.pop(context),
              child: Text("No", style: TextStyle(color: AppTheme.primaryBlue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              child: const Text("Sí", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAccountManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Fondo oscuro
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Manejar Cuenta",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryBlue),
              title: Text("Cambiar nombre de usuario",
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (_) =>  ChangeUsernameForm(),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.lock, color: AppTheme.primaryBlue),
              title: Text("Cambiar contraseña",
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (_) =>  ChangePasswordForm(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Eliminar cuenta",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child:
                Text("Cerrar", style: TextStyle(color: AppTheme.primaryBlue)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
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
          _showAccountManagementDialog(context);
        } else if (value == 2) {
          _showLogoutConfirmation(context);
        }
      },
    );
  }
}
