import 'package:flutter/material.dart';
import 'family_members_screen.dart'; // siguiente paso si dice que sí
import 'house_info_screen.dart'; // si dice que no

class IncludeChildrenTasksScreen extends StatelessWidget {
  const IncludeChildrenTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas del hogar'),
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
              '¿Quieres incluir a tus hijos en las tareas del hogar?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FamilyMembersScreen(memberCount: 0),
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
                    builder: (_) => const HouseInfoScreen(),
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