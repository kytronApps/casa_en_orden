// next_step_screen.dart
import 'package:flutter/material.dart';

class NextStepScreen extends StatelessWidget {
  final String option;

  const NextStepScreen({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siguiente paso')),
      body: Center(
        child: Text(
          'Has seleccionado: $option',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
