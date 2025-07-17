import 'package:flutter/material.dart';
import 'include_children_task_screen.dart'; // siguiente paso si dice que sí
import 'house_info_screen.dart'; 

class HasChildrenScreen extends StatelessWidget {
  const HasChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información familiar'),
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
              '¿Tienes hijos?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncludeChildrenTasksScreen(),
                  ),
                );
              },
              style: _buttonStyle(),
              child: const Text('Sí'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HouseInfoScreen(), // siguiente paso directo
                  ),
                );
              },
              style: _buttonStyle(),
              child: const Text('No'),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}