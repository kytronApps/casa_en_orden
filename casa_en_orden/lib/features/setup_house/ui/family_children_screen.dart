import 'package:flutter/material.dart';
import 'package:casa_en_orden/features/setup_house/ui/house_info_screen.dart';

class FamilyChildrenScreen extends StatefulWidget {
  const FamilyChildrenScreen({super.key});

  @override
  State<FamilyChildrenScreen> createState() => _FamilyChildrenScreenState();
}

class _FamilyChildrenScreenState extends State<FamilyChildrenScreen> {
  final _familySizeController = TextEditingController();
  bool? _includeChildren;

  void _continueFlow() {
    final familySize = int.tryParse(_familySizeController.text);
    if (familySize == null || familySize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un número válido de integrantes.')),
      );
      return;
    }

    if (_includeChildren == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona si deseas incluir a los hijos en las tareas.')),
      );
      return;
    }

    // Si se incluyen hijos, pedir sus datos; si no, continuar a HouseInfoScreen
    if (_includeChildren == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyMembersScreen(totalMembers: familySize),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HouseInfoScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Miembros de la familia')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cuántos integrantes hay en tu familia?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _familySizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ejemplo: 4'),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Deseas incluir a los hijos en las tareas del hogar?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _includeChildren = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _includeChildren == true ? Colors.teal : Colors.grey,
                    ),
                    child: const Text('Sí'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _includeChildren = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _includeChildren == false ? Colors.teal : Colors.grey,
                    ),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _continueFlow,
                child: const Text('Siguiente'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FamilyMembersScreen extends StatelessWidget {
  final int totalMembers;

  const FamilyMembersScreen({super.key, required this.totalMembers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participantes')),
      body: Center(
        child: Text('Aquí se solicitarán correos y nombres de $totalMembers miembros'),
      ),
    );
  }
}