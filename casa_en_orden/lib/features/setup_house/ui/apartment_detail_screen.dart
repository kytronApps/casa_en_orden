// apartment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:casa_en_orden/features/setup_house/ui/next_step_screen.dart';

class ApartmentDetailScreen extends StatelessWidget {
  const ApartmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Piso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cómo vives en este piso?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NextStepScreen(option: 'solo')),
                );
              },
              child: const Text('Solo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NextStepScreen(option: 'compartido')),
                );
              },
              child: const Text('Compartido'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NextStepScreen(option: 'familia/pareja')),
                );
              },
              child: const Text('Familiar / Pareja'),
            ),
          ],
        ),
      ),
    );
  }
}
