import 'package:flutter/material.dart';
import 'views/login_screen.dart';
import 'views/main_screen.dart';
import 'views/splash_screen.dart'; // Nueva pantalla de carga

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartTrap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // La app inicia en la pantalla de carga
      routes: {
        '/': (context) => SplashScreen(), // Verifica sesión antes de cargar LoginScreen o MainScreen
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}
