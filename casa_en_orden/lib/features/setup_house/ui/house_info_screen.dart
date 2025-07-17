import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'calendar_generation_screen.dart';

class HouseInfoScreen extends StatefulWidget {
  const HouseInfoScreen({super.key});

  @override
  State<HouseInfoScreen> createState() => _HouseInfoScreenState();
}

class _HouseInfoScreenState extends State<HouseInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _sizeController = TextEditingController();
  final _specialZonesController = TextEditingController();
  final _floorTypeController = TextEditingController();
  final _houseNameController = TextEditingController();
  bool _hasGarden = false;
  bool _hasPets = false;
  bool _isLoading = false;

  // Agrega esto en tu _submit()
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Insertar casa con user_id
    final houseResponse = await Supabase.instance.client
        .from('houses')
        .insert({
          'name': _houseNameController.text.trim(),
          'type': 'casa',
          'rooms': int.parse(_roomsController.text),
          'bathrooms': int.parse(_bathroomsController.text),
          'floors': int.parse(_floorsController.text),
          'has_garden': _hasGarden,
          'has_pets': _hasPets,
          'size': int.tryParse(_sizeController.text) ?? 0,
          'special_zones': _specialZonesController.text.trim(),
          'floor_type': _floorTypeController.text.trim(),
          'user_id': user.id, // <- este es nuevo
          'created_at': DateTime.now().toIso8601String()
        })
        .select()
        .single();

    // Insertar residente principal (dueño)
    await Supabase.instance.client
        .from('residents')
        .insert({
          'house_id': houseResponse['id'],
          'name': 'Tú',
          'user_id': user.id,
          'is_owner': true,
          'accepted': true,
          'created_at': DateTime.now().toIso8601String(),
        });

    // Crear perfil de limpieza
    await Supabase.instance.client.from('cleaning_profiles').insert({
      'user_id': user.id,
      'house_id': houseResponse['id'],
      'name': _houseNameController.text.trim(),
    });

    // Redirigir al calendario
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CalendarGenerationScreen()),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}





  @override
  void dispose() {
    _roomsController.dispose();
    _bathroomsController.dispose();
    _floorsController.dispose();
    _sizeController.dispose();
    _specialZonesController.dispose();
    _floorTypeController.dispose();
    _houseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de la vivienda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.teal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _houseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la vivienda*',
                    hintText: 'Ej. Casa de la playa, Piso centro...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de habitaciones*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el número de habitaciones';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de baños*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el número de baños';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('¿Tiene jardín?'),
                  value: _hasGarden,
                  onChanged: (value) => setState(() => _hasGarden = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _floorsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de plantas*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el número de plantas';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño aproximado (m²)*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el tamaño';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('¿Hay mascotas en la vivienda?'),
                  value: _hasPets,
                  onChanged: (value) => setState(() => _hasPets = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specialZonesController,
                  decoration: const InputDecoration(
                    labelText: 'Zonas especiales',
                    hintText: 'Ej. despacho, trastero...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _floorTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de suelo predominante*',
                    hintText: 'Parquet, baldosa, moqueta, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el tipo de suelo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Siguiente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}