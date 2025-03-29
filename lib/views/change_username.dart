import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_scale_transition.dart';

class ChangeUsernameForm extends StatefulWidget {
  @override
  _ChangeUsernameFormState createState() => _ChangeUsernameFormState();
}

class _ChangeUsernameFormState extends State<ChangeUsernameForm> {
  final _formKey = GlobalKey<FormState>();
  String _nuevoNombre = "";
  bool _isLoading = false;

  Future<void> _cambiarNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("email");

    setState(() => _isLoading = true);
    final response = await http.post(
      Uri.parse("http://raspberrypi2.local/change_username.php"),
      body: {
        "email": email ?? "",
        "nuevo_nombre": _nuevoNombre,
      },
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200 && response.body.contains("success")) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nombre de usuario actualizado con éxito")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cambiar el nombre de usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeScaleTransitionWrapper(
      child: AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Cambiar Nombre de Usuario",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            decoration:
                InputDecoration(labelText: "Nuevo Nombre de Usuario"),
            onChanged: (value) => _nuevoNombre = value,
            validator: (value) => value == null || value.isEmpty
                ? "Este campo es obligatorio"
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      _cambiarNombre();
                    }
                  },
            child:
                _isLoading ? CircularProgressIndicator() : Text("Actualizar"),
          ),
        ],
      ),
    );
  }
}
