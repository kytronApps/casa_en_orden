import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:casa_en_orden/services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarService _svc = CalendarService(Supabase.instance.client);

  DateTime _anchor = DateTime.now(); // cualquier día de la semana actual
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _rows = [];   // lo que se muestra
  List<Map<String, dynamic>> _persisted = []; // lo que hay guardado (para detectar cambios)
// cache para el formulario de alta
List<Map<String, dynamic>> _zones = [];
List<Map<String, dynamic>> _residents = [];
  static const _days = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=> _loading = true);
    final iso = _svc.isoWeekYear(_anchor);
    // cargar zonas y residentes del hogar del perfil
final houseId = widget.profile['house_id'] as String;
_zones = await _svc.getZonesByHouse(houseId);
_residents = await _svc.getResidentsByHouse(houseId);
    final profileId = widget.profile['id'] as String;

    final saved = await _svc.getAssignmentsForWeek(
      profileId: profileId, week: iso.week, year: iso.year,
    );

    if (saved.isNotEmpty) {
      _rows = saved;
      _persisted = List<Map<String,dynamic>>.from(saved);
    } else {
      _rows = await _svc.buildWeek(profile: widget.profile, weekDate: _anchor);
      _persisted = [];
    }
    if (mounted) setState(()=> _loading = false);
  }

  Future<void> _prevWeek() async {
    setState(()=> _anchor = _anchor.subtract(const Duration(days: 7)));
    await _load();
  }

  Future<void> _nextWeek() async {
    setState(()=> _anchor = _anchor.add(const Duration(days: 7)));
    await _load();
  }

  String _monthNameEs(int m) {
    const meses = [
      '', 'Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
    ];
    return meses[m];
  }

  String _weekTitle() {
    final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final month = _monthNameEs(monday.month);
    final year = monday.year;
    String dd(int d) => d.toString().padLeft(2, '0');
    return '$month $year • Semana del ${dd(monday.day)}–${dd(sunday.day)}';
  }

  bool get _isDirty => _persisted.length != _rows.length ||
      !_persisted.every((p) => _rows.any((r) =>
          r['zone_id']==p['zone_id'] &&
          r['resident_id']==p['resident_id'] &&
          r['day_of_week']==p['day_of_week']));

  Future<void> _save() async {
    setState(()=> _saving = true);
    await _svc.saveAssignments(_rows.map((e){
      final m = Map<String,dynamic>.from(e);
      m.remove('_zone'); m.remove('_resident');
      return m;
    }).toList());
    _persisted = List<Map<String,dynamic>>.from(_rows);
    if (mounted) {
      setState(()=> _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semana guardada')),
      );
    }
  }

  Future<void> _openAddTaskSheet() async {
    if (_zones.isEmpty || _residents.isEmpty) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final zoneCtrl = TextEditingController();
          final residentCtrl = TextEditingController();
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Antes de añadir tareas…', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Necesitas al menos 1 zona y 1 residente en este perfil.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneCtrl,
                    decoration: const InputDecoration(labelText: 'Nueva zona (opcional)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: residentCtrl,
                    decoration: const InputDecoration(labelText: 'Nuevo residente (opcional)'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Crear y continuar'),
                      onPressed: () async {
                        final houseId = widget.profile['house_id'] as String;
                        if (zoneCtrl.text.trim().isNotEmpty) {
                          await Supabase.instance.client
                              .from('zones')
                              .insert({'house_id': houseId, 'name': zoneCtrl.text.trim()});
                        }
                        if (residentCtrl.text.trim().isNotEmpty) {
                          await Supabase.instance.client
                              .from('residents')
                              .insert({'house_id': houseId, 'name': residentCtrl.text.trim()});
                        }
                        if (mounted) Navigator.pop(ctx);
                        await _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    final iso = _svc.isoWeekYear(_anchor);
    int day = DateTime.now().weekday; // 1..7
    String? zoneId = _zones.first['id'] as String?;
    String? residentId = _residents.first['id'] as String?;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Añadir tarea', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: day,
                  decoration: const InputDecoration(labelText: 'Día de la semana'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Lunes')),
                    DropdownMenuItem(value: 2, child: Text('Martes')),
                    DropdownMenuItem(value: 3, child: Text('Miércoles')),
                    DropdownMenuItem(value: 4, child: Text('Jueves')),
                    DropdownMenuItem(value: 5, child: Text('Viernes')),
                    DropdownMenuItem(value: 6, child: Text('Sábado')),
                    DropdownMenuItem(value: 7, child: Text('Domingo')),
                  ],
                  onChanged: (v) => setModalState(() => day = v ?? day),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: zoneId,
                  decoration: const InputDecoration(labelText: 'Zona'),
                  items: _zones.map((z) => DropdownMenuItem(
                    value: z['id'] as String,
                    child: Text(z['name']?.toString() ?? '(zona)'),
                  )).toList(),
                  onChanged: (v) => setModalState(() => zoneId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: residentId,
                  decoration: const InputDecoration(labelText: 'Residente'),
                  items: _residents.map((r) => DropdownMenuItem(
                    value: r['id'] as String,
                    child: Text(r['name']?.toString() ?? '(residente)'),
                  )).toList(),
                  onChanged: (v) => setModalState(() => residentId = v),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_task),
                    label: const Text('Añadir'),
                    onPressed: () {
                      if (zoneId == null || residentId == null) return;

                      _rows.removeWhere((r) => r['zone_id'] == zoneId && r['day_of_week'] == day);

                      final zone = _zones.firstWhere((z) => z['id'] == zoneId, orElse: () => {});
                      final resident = _residents.firstWhere((r) => r['id'] == residentId, orElse: () => {});

                      _rows.add({
                        'profile_id': widget.profile['id'],
                        'zone_id': zoneId,
                        'resident_id': residentId,
                        'week_number': iso.week,
                        'week_year': iso.year,
                        'day_of_week': day,
                        'is_fixed': false,
                        '_zone': zone,
                        '_resident': resident,
                      });

                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tarea agregada a la semana')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_weekTitle()),
        actions: [
          IconButton(onPressed: _prevWeek, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextWeek, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isDirty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Cambios sin guardar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _WeekList(rows: _rows),
                ],
              ),
            ),
      floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    FloatingActionButton.extended(
      heroTag: 'add-task',
      onPressed: _openAddTaskSheet,
      icon: const Icon(Icons.add_task),
      label: const Text('Añadir tarea'),
    ),
    const SizedBox(height: 12),
    FloatingActionButton.extended(
      heroTag: 'save-week',
      onPressed: _isDirty && !_saving ? _save : null,
      icon: const Icon(Icons.save),
      label: Text(_saving ? 'Guardando...' : 'Guardar semana'),
    ),
  ],
),
    );
  }
}

class _WeekList extends StatelessWidget {
  const _WeekList({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    // agrupa por día 1..7
    final byDay = <int, List<Map<String,dynamic>>>{};
    for (final r in rows) {
      final d = r['day_of_week'] as int;
      (byDay[d] ??= []).add(r);
    }
    // ordena por nombre de zona
    for (final l in byDay.values) {
      l.sort((a,b)=> (a['_zone']?['name'] ?? '').toString()
          .compareTo((b['_zone']?['name'] ?? '').toString()));
    }

    const names = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final day = i+1;
        final list = byDay[day] ?? [];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(names[i], style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  Text('— Sin tareas —',
                      style: Theme.of(context).textTheme.bodyMedium),
                ...list.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(r['_zone']?['name'] ?? '(zona)'),
                  subtitle: Text(r['_resident']?['name'] ?? '(residente)'),
                )),
              ],
            ),
          ),
        );
      }),
    );
  }
}