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
  Map<String, dynamic>? _selectedProfile;
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

    final houseIds = profiles.map((p) => p['house_id'] as String).toList();

    final housesResponse = await Supabase.instance.client
        .from('houses')
        .select()
        .inFilter('id', houseIds);

    final houses = List<Map<String, dynamic>>.from(housesResponse);

    for (final profile in profiles) {
      profile['house'] = houses.firstWhere(
        (house) => house['id'] == profile['house_id'],
        orElse: () => {},
      );
    }

    final pinned = profiles.firstWhere(
      (profile) => profile['id'] == pinnedProfileId,
      orElse: () => {},
    );

    setState(() {
      _profiles = profiles;
      _pinnedProfile = pinned.isNotEmpty ? pinned : null;
      _isLoading = false;
      _selectedProfile = pinned.isNotEmpty ? pinned : (profiles.isNotEmpty ? profiles.first : null);
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
                          setState(() {
                            _pinnedProfile = null;
                            _selectedProfile = profile;
                          });
                          Navigator.pop(context);
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
              : (_pinnedProfile != null || _selectedProfile != null)
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ListTile(
                          title: Text(
                            (_pinnedProfile ?? _selectedProfile)!['name'] ?? 'Perfil sin nombre',
                          ),
                          subtitle: Text(
                            _pinnedProfile != null
                                ? 'Perfil anclado. Haz clic para ver detalles'
                                : 'Perfil seleccionado. Haz clic para ver detalles',
                          ),
                          onTap: () {
                            // Acción al hacer clic en el perfil mostrado
                          },
                        ),
                        // Aquí puedes añadir más detalles del perfil
                        const SizedBox(height: 16),
                        Text("Detalles del perfil:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Builder(
                          builder: (context) {
                            final profile = (_pinnedProfile ?? _selectedProfile);
                            final house = profile?['house'] ?? {};
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Habitaciones: ${house['rooms'] ?? 'N/A'}"),
                                Text("Baños: ${house['bathrooms'] ?? 'N/A'}"),
                                Text("Tamaño: ${house['size'] ?? 'N/A'} m²"),
                                Text("Zonas especiales: ${house['special_zones'] ?? 'N/A'}"),
                                Text("Tipo de suelo: ${house['floor_type'] ?? 'N/A'}"),
                                Text("¿Tiene integrantes?: ${(house['has_members'] ?? false) ? 'Sí' : 'No'}"),
                                const SizedBox(height: 16),
                                // Aquí podrías añadir información del calendario si se desea incluir luego.
                                // Por ejemplo, consultar una tabla 'calendars' asociada y mostrar eventos.
                                if (profile?['user_id'] == user?.id)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Navegar a la pantalla de edición del perfil
                                      // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)));
                                    },
                                    icon: Icon(Icons.edit),
                                    label: Text('Editar perfil'),
                                  ),
                                if (profile?['user_id'] == user?.id)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Navegar a la pantalla de gestión de integrantes
                                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMembersScreen(profileId: profile['id'])));
                                    },
                                    icon: Icon(Icons.group),
                                    label: Text('Gestionar integrantes'),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  : const Center(
                      child: Text('Selecciona un perfil desde el menú lateral'),
                    ),
    );
  }
}