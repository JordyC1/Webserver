import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isHovering = false; // ✅ Controlador para el hover

  Future<void> _login() async {
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://raspberrypi2.local/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse["success"]) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", jsonResponse["token"] ?? "");
          await prefs.setString("email", email);

          // ✅ También guarda el nombre si lo devuelve el backend
          if (jsonResponse.containsKey("nombre")) {
            await prefs.setString("nombre", jsonResponse["nombre"]);
          }

          Navigator.pushReplacementNamed(context, "/main");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Credenciales incorrectas. Por favor, verifica tu usuario y contraseña.",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Error de conexión con el servidor. Por favor, intenta más tarde.",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Credenciales incorrectas. Por favor, verifica tu usuario y contraseña.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bug_report,
                      size: 100, color: AppTheme.primaryBlue),
                  const SizedBox(height: 10),
                  Text(
                    "SmartTrap",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Usuario/Correo Electrónico", emailController, false),
                  const SizedBox(height: 15),
                  _buildTextField("Contraseña", passwordController, true),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 15),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Continuar",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Sección con hover en "Regístrate aquí"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("¿No tienes cuenta?",
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(width: 5),
                      MouseRegion(
                        onEnter: (_) => setState(() => isHovering = true),
                        onExit: (_) => setState(() => isHovering = false),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterScreen()),
                            );
                          },
                          child: Text(
                            "Regístrate aquí",
                            style: TextStyle(
                              color: isHovering
                                  ? AppTheme.primaryBlue.withOpacity(0.7)
                                  : AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              decoration:
                                  isHovering ? TextDecoration.underline : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ❌ Eliminado el texto "Olvidé mi contraseña"
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardBackground,
            hintText: isPassword ? "************" : "User@gmail.com",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}
