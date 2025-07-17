// lib/features/menu/ui/main_menu_screen.dart
import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
      ),
      body: const Center(
        child: Text('Aquí se mostrarán tus perfiles de limpieza'),
      ),
    );
  }
}