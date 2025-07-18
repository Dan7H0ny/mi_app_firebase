import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth + API Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthExample(),
    );
  }
}

class AuthExample extends StatefulWidget {
  const AuthExample({super.key});

  @override
  AuthExampleState createState() => AuthExampleState();
}

class AuthExampleState extends State<AuthExample> {
  String status = "No autenticado";
  String apiMessage = "";
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  void checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        isAuthenticated = user != null;
        if (user != null) {
          status = "Autenticado: ${user.uid}";
        } else {
          status = "No autenticado";
          apiMessage = "";
        }
      });
    });
  }

  void signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        status = "Iniciando sesión...";
      });
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      apiMessage = "";
    });
  }

  void consumeAPI() async {
    if (!isAuthenticated) {
      setState(() {
        apiMessage = "Debes autenticarte primero";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/mensaje-autenticado'), // IP para emulador Android
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          apiMessage = data['mensaje'];
        });
      } else {
        setState(() {
          apiMessage = "Error al consumir API: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        apiMessage = "Error de conexión: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase Auth + API"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Estado de Autenticación",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: isAuthenticated ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!isAuthenticated)
              ElevatedButton(
                onPressed: signInAnonymously,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Login Anónimo"),
              )
            else
              ElevatedButton(
                onPressed: signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Cerrar Sesión"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: consumeAPI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Consumir API"),
            ),
            const SizedBox(height: 20),
            if (apiMessage.isNotEmpty)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Respuesta de la API:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        apiMessage,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}