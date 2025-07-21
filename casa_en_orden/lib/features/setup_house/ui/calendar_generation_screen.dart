import 'package:flutter/material.dart';
import 'package:casa_en_orden/features/auth/ui/main_menu_screen.dart';


class CalendarGenerationScreen extends StatelessWidget {
  const CalendarGenerationScreen({super.key});

  void _finalStep(BuildContext context, bool addToMobile) {
    if (addToMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendario añadido al móvil')), 
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendario creado en tu perfil')), 
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar calendario'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.teal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Creando horario de limpieza con la información proporcionada...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Creando calendario de limpieza...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Añadir al calendario del móvil'),
              onPressed: () => _finalStep(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
OutlinedButton(
  onPressed: () {
    _finalStep(context, false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      (route) => false,
    );
  },
  child: const Text('No añadir al calendario del móvil'),
)
          ],
        ),
      ),
    );
  }
}