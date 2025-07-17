import 'package:flutter/material.dart';
import 'house_info_screen.dart';

class FamilyMembersScreen extends StatefulWidget {
  final int memberCount;

  const FamilyMembersScreen({super.key, required this.memberCount});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _emailControllers;
  final _formKey = GlobalKey<FormState>();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _nameControllers =
        List.generate(widget.memberCount, (_) => TextEditingController());
    _emailControllers =
        List.generate(widget.memberCount, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final members = List.generate(_nameControllers.length, (index) {
        return {
          'name': _nameControllers[index].text.trim(),
          'email': _emailControllers[index].text.trim(),
        };
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HouseInfoScreen()),
      );
    }
  }

  void _addMember() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Miembros de la familia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: List.generate(_nameControllers.length, (index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Miembro ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                hintText: 'Ingresa el nombre',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'Ingresa el correo electrónico',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un correo electrónico';
                                }
                                if (!_isValidEmail(value)) {
                                  return 'Por favor ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _addMember,
                    child: const Text('Agregar miembro'),
                  ),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}