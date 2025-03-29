import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_scale_transition.dart';

class ChangePasswordForm extends StatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String _actual = "";
  String _nueva = "";
  String _confirmacion = "";
  bool _isLoading = false;

  Future<void> _cambiarPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("email");

    setState(() => _isLoading = true);
    final response = await http.post(
      Uri.parse("http://raspberrypi2.local/change_password.php"),
      body: {
        "email": email ?? "",
        "actual": _actual,
        "nueva": _nueva,
      },
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200 && response.body.contains("success")) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contraseña actualizada con éxito")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cambiar la contraseña")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeScaleTransitionWrapper(
      child: AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text("Cambiar Contraseña",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: "Contraseña Actual"),
                onChanged: (value) => _actual = value,
                validator: (value) =>
                    value == null || value.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: "Nueva Contraseña"),
                onChanged: (value) => _nueva = value,
                validator: (value) => value == null || value.length < 6
                    ? "Mínimo 6 caracteres"
                    : null,
              ),
              TextFormField(
                obscureText: true,
                decoration:
                    InputDecoration(labelText: "Confirmar Contraseña"),
                onChanged: (value) => _confirmacion = value,
                validator: (value) => value != _nueva ? "No coincide" : null,
              ),
            ],
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
                      _cambiarPassword();
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
