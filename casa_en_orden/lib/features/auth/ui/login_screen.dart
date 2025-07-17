import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'package:casa_en_orden/features/setup_house/ui/select_house_type_screen.dart';
import 'package:casa_en_orden/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:casa_en_orden/features/auth/ui/main_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor, completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().login(email: email, password: password);

    setState(() => _isLoading = false);


    if (result == null) {
      _showError('Error al iniciar sesión. Revisa tus credenciales.');
      return;
    }

    // Verifica si el usuario tiene perfiles
    final userId = result.user?.id;

    if (userId == null) {
      _showError('Error al obtener el ID del usuario');
      return;
    }

    final userProfiles = await Supabase.instance.client
        .from('cleaning_profiles')
        .select()
        .eq('user_id', userId);

    if (userProfiles != null && userProfiles.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectHouseTypeScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Casa en Orden',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Contraseña',
                    ),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Center(child: Text('Iniciar sesión')),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}