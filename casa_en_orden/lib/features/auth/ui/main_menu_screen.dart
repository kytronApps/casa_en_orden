import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:casa_en_orden/features/setup_house/ui/house_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casa_en_orden/services/avatar_service.dart';
import 'package:casa_en_orden/features/auth/ui/calendar_screen.dart';



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



  late final AvatarService _avatarSvc = AvatarService(Supabase.instance.client);
final Map<String, String?> _avatarUrls = {};

  // Controllers used in the edit bottom sheet
  final _nameCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _bathsCtrl = TextEditingController();
  final _floorsCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _zonesCtrl = TextEditingController();
  final _floorTypeCtrl = TextEditingController();
  bool _hasGardenTmp = false;
  bool _hasPetsTmp = false;
  bool _hasMembersTmp = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchProfiles();
    await _preloadAvatars();
  }

  Future<void> _preloadAvatars() async {
    if (user == null) return;
    final Map<String, String?> next = {};
    for (final p in _profiles) {
      final id = p['id'] as String;
      final url = await _avatarSvc.signedUrlForProfile(id);
      next[id] = url;
    }
    if (!mounted) return;
    setState(() {
      _avatarUrls
        ..clear()
        ..addAll(next);
    });
  }


Future<void> _changeAvatarFor(String profileId) async {
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) return;
  try {
    final url = await _avatarSvc.pickAndUploadForProfile(userId: u.id, profileId: profileId);
    if (mounted && url != null) {
      setState(() => _avatarUrls[profileId] = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar actualizado')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el avatar: $e')),
      );
    }
  }
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

  Future<void> _openEditProfileSheet(Map<String, dynamic> profile) async {
    final house = Map<String, dynamic>.from(profile['house'] ?? {});

    _nameCtrl.text = profile['name'] ?? '';
    _roomsCtrl.text = (house['rooms'] ?? '').toString();
    _bathsCtrl.text = (house['bathrooms'] ?? '').toString();
    _floorsCtrl.text = (house['floors'] ?? '').toString();
    _sizeCtrl.text = (house['size'] ?? '').toString();
    _zonesCtrl.text = (house['special_zones'] ?? '').toString();
    _floorTypeCtrl.text = (house['floor_type'] ?? '').toString();
    _hasGardenTmp = (house['has_garden'] ?? false) as bool;
    _hasPetsTmp = (house['has_pets'] ?? false) as bool;
    _hasMembersTmp = (house['has_members'] ?? false) as bool;

    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Editar perfil', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del perfil'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _roomsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Habitaciones'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _bathsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Baños'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _floorsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Plantas'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _sizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tamaño (m²)'))),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _zonesCtrl,
                  decoration: const InputDecoration(labelText: 'Zonas especiales'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _floorTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo de suelo'),
                ),
                const SizedBox(height: 8),
               SwitchListTile(
  value: _hasGardenTmp,
  onChanged: (v) => setState(() => _hasGardenTmp = v),
  title: const Text('¿Tiene jardín?'),
  contentPadding: EdgeInsets.zero,
),
                SwitchListTile(
                  value: _hasPetsTmp,
                  onChanged: (v) => setState(() => _hasPetsTmp = v),
                  title: const Text('¿Hay mascotas?'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _hasMembersTmp,
                  onChanged: (v) => setState(() => _hasMembersTmp = v),
                  title: const Text('¿Tiene integrantes?'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Guardar cambios
                          try {
                            await Supabase.instance.client
                                .from('houses')
                                .update({
                                  'rooms': int.tryParse(_roomsCtrl.text) ?? house['rooms'],
                                  'bathrooms': int.tryParse(_bathsCtrl.text) ?? house['bathrooms'],
                                  'floors': int.tryParse(_floorsCtrl.text) ?? house['floors'],
                                  'size': int.tryParse(_sizeCtrl.text) ?? house['size'],
                                  'special_zones': _zonesCtrl.text.trim(),
                                  'floor_type': _floorTypeCtrl.text.trim(),
                                  'has_garden': _hasGardenTmp,
                                  'has_pets': _hasPetsTmp,
                                  'has_members': _hasMembersTmp,
                                })
                                .eq('id', profile['house_id']);

                            await Supabase.instance.client
                                .from('cleaning_profiles')
                                .update({'name': _nameCtrl.text.trim()})
                                .eq('id', profile['id']);

                            if (mounted) Navigator.pop(ctx);
                            await _fetchProfiles();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil actualizado')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al actualizar: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Eliminar perfil'),
                            content: const Text('Esta acción eliminará el perfil y su casa asociada. ¿Continuar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Eliminar')),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        try {
                          await Supabase.instance.client
                              .from('cleaning_profiles')
                              .delete()
                              .eq('id', profile['id']);
                          await Supabase.instance.client
                              .from('houses')
                              .delete()
                              .eq('id', profile['house_id']);
                          if (mounted) Navigator.pop(ctx);
                          await _fetchProfiles();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al eliminar: $e')),
                            );
                          }
                        }
                      },
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomsCtrl.dispose();
    _bathsCtrl.dispose();
    _floorsCtrl.dispose();
    _sizeCtrl.dispose();
    _zonesCtrl.dispose();
    _floorTypeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Menú principal'),
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'Crear perfil',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HouseInfoScreen()),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
    ),
  ],
),

      drawer: _profiles.length > 1
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.teal),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (() {
                            final current = (_pinnedProfile ?? _selectedProfile);
                            if (current == null) return null;
                            final pid = current['id'] as String;
                            final url = _avatarUrls[pid];
                            return (url != null) ? NetworkImage(url) : null;
                          })(),
                          child: (() {
                            final current = (_pinnedProfile ?? _selectedProfile);
                            if (current == null) return const Icon(Icons.person, color: Colors.white);
                            final pid = current['id'] as String;
                            final url = _avatarUrls[pid];
                            return (url == null) ? const Icon(Icons.person, color: Colors.white) : null;
                          })(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Perfil seleccionado', style: TextStyle(color: Colors.white70)),
                              Text(
                                (_pinnedProfile ?? _selectedProfile)?['name'] ?? 'Sin nombre',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._profiles.map((profile) {
                    final id = profile['id'] as String;
                    final isSelected = (_pinnedProfile == null && _selectedProfile?['id'] == id) ||
                        (_pinnedProfile != null && _pinnedProfile?['id'] == id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (_avatarUrls[id] != null) ? NetworkImage(_avatarUrls[id]!) : null,
                        child: (_avatarUrls[id] == null) ? const Icon(Icons.person) : null,
                      ),
                      title: Text(profile['name'] ?? 'Perfil sin nombre'),
                      trailing: IconButton(
                        icon: const Icon(Icons.push_pin_outlined),
                        tooltip: 'Anclar perfil',
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('pinned_profile_id', profile['id']);
                          _initializeData();
                        },
                      ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(.3),
                      onTap: () {
                        setState(() {
                          _pinnedProfile = null;
                          _selectedProfile = profile;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? const Center(child: Text('No tienes perfiles de limpieza'))
              : (_pinnedProfile != null || _selectedProfile != null)
                  ? RefreshIndicator(
                      onRefresh: _initializeData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      (_pinnedProfile ?? _selectedProfile)!['name'] ?? 'Perfil sin nombre',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      _pinnedProfile != null
                                          ? 'Perfil anclado. Haz clic para ver detalles'
                                          : 'Perfil seleccionado. Haz clic para ver detalles',
                                    ),
                                    leading: Builder(
                                      builder: (context) {
                                        final current = (_pinnedProfile ?? _selectedProfile)!;
                                        final pid = current['id'] as String;
                                        final url = _avatarUrls[pid];

                                        return InkWell(
                                          onTap: () => _changeAvatarFor(pid), // tocar = cambiar foto
                                          borderRadius: BorderRadius.circular(24),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundImage: (url != null) ? NetworkImage(url) : null,
                                                backgroundColor: Colors.teal.withOpacity(.15),
                                                child: (url == null) ? const Icon(Icons.home, color: Colors.teal) : null,
                                              ),
                                              Positioned(
                                                right: -2,
                                                bottom: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    trailing: (
                                      (_pinnedProfile ?? _selectedProfile)?['user_id'] == user?.id
                                    )
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  final current = (_pinnedProfile ?? _selectedProfile)!;
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => CalendarScreen(profile: current),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.calendar_today, size: 18),
                                                label: const Text('Calendario'),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton.icon(
                                                onPressed: () => _openEditProfileSheet((_pinnedProfile ?? _selectedProfile)!),
                                                icon: const Icon(Icons.edit, size: 18),
                                                label: const Text('Editar'),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                  const Divider(height: 24),
                                  Builder(
                                    builder: (context) {
                                      final profile = (_pinnedProfile ?? _selectedProfile);
                                      final house = profile?['house'] ?? {};
                                      Widget infoRow(IconData icon, String label, String value) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Row(
                                            children: [
                                              Icon(icon, size: 20, color: Colors.teal),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
                                              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Detalles del perfil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          infoRow(Icons.meeting_room, 'Habitaciones', '${house['rooms'] ?? 'N/A'}'),
                                          infoRow(Icons.bathtub_outlined, 'Baños', '${house['bathrooms'] ?? 'N/A'}'),
                                          infoRow(Icons.stairs_outlined, 'Plantas', '${house['floors'] ?? 'N/A'}'),
                                          infoRow(Icons.square_foot, 'Tamaño', '${house['size'] ?? 'N/A'} m²'),
                                          infoRow(Icons.chair_outlined, 'Zonas especiales', '${house['special_zones'] ?? 'N/A'}'),
                                          infoRow(Icons.texture, 'Tipo de suelo', '${house['floor_type'] ?? 'N/A'}'),
                                          infoRow(Icons.groups_2_outlined, '¿Tiene integrantes?', (house['has_members'] ?? false) ? 'Sí' : 'No'),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('Selecciona un perfil desde el menú lateral'),
                    ),
    );
  }
}