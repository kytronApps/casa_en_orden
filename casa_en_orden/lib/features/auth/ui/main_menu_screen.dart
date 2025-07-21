import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:casa_en_orden/features/setup_house/ui/house_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _profiles = [];
  Map<String, dynamic>? _pinnedProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('cleaning_profiles')
        .select()
        .eq('user_id', user!.id);

    debugPrint('Fetched profiles: $response');

    final prefs = await SharedPreferences.getInstance();
    final pinnedProfileId = prefs.getString('pinned_profile_id');

    final profiles = List<Map<String, dynamic>>.from(response);
    final pinned = profiles.firstWhere(
      (profile) => profile['id'] == pinnedProfileId,
      orElse: () => {},
    );

    setState(() {
      _profiles = profiles;
      _pinnedProfile = pinned.isNotEmpty ? pinned : null;
      _isLoading = false;
    });
  }

  void _createNewProfile() {
    // Navegar a la pantalla de creación
    // Navigator.push(...);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseInfoScreen()),
              );
            },
          )
        ],
      ),
      drawer: _profiles.length > 1
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.teal),
                    child: Text('Tus perfiles'),
                  ),
                  ..._profiles.map((profile) => ListTile(
                        title: Text(profile['name'] ?? 'Perfil sin nombre'),
                        trailing: IconButton(
                          icon: const Icon(Icons.push_pin_outlined),
                          tooltip: 'Anclar perfil',
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('pinned_profile_id', profile['id']);
                            _fetchProfiles();
                          },
                        ),
                        onTap: () {
                          // Acción al seleccionar perfil
                        },
                      )),
                ],
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? const Center(child: Text('No tienes perfiles de limpieza'))
              : _pinnedProfile != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ListTile(
                          title: Text(_pinnedProfile!['name'] ?? 'Perfil sin nombre'),
                          subtitle: const Text('Perfil anclado. Haz clic para ver detalles'),
                          onTap: () {
                            // Acción al seleccionar perfil anclado
                          },
                        )
                      ],
                    )
                  : const Center(
                      child: Text('Selecciona un perfil desde el menú lateral'),
                    ),
    );
  }
}