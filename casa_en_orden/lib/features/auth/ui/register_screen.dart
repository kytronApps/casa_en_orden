import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

final supabase = Supabase.instance.client;

  void _register() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;
  final confirm = _confirmController.text;

  if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
    _showError('Por favor, completa todos los campos');
    return;
  }

  if (password != confirm) {
    _showError('Las contraseñas no coinciden');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      debugPrint('✅ Usuario registrado: ${response.user!.email}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cuenta creada. Revisa tu correo para verificar.'),
      ));
      Navigator.pop(context); // Vuelve al login
    } else {
      _showError('No se pudo crear la cuenta. Intenta nuevamente.');
    }
  } on AuthException catch (e) {
    _showError('Error: ${e.message}');
  } catch (e) {
    _showError('Error inesperado: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirmar contraseña',
                    ),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Center(child: Text('Crear cuenta')),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Vuelve al login
                    },
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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