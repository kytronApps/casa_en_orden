import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarService {
  CalendarService(this.sb);
  final SupabaseClient sb;

  // ----------------- Helpers semana ISO (1..7 = Lun..Dom)
  ({int week, int year}) isoWeekYear(DateTime d) {
    final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 + ((thursday.difference(firstThursday).inDays) ~/ 7);
    return (week: week, year: thursday.year);
  }

  DateTime mondayOf(DateTime d) => d.subtract(Duration(days: (d.weekday - 1)));

  // ----------------- Cargas base
  Future<List<Map<String, dynamic>>> getZonesByHouse(String houseId) async {
    final rows = await sb.from('zones').select().eq('house_id', houseId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getResidentsByHouse(String houseId) async {
    final rows = await sb.from('residents').select().eq('house_id', houseId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getSchedulesForZones(List<String> zoneIds) async {
    if (zoneIds.isEmpty) return [];
    final rows = await sb.from('zone_schedules').select().inFilter('zone_id', zoneIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getRotationMembersForZones(List<String> zoneIds) async {
    if (zoneIds.isEmpty) return [];
    final rows = await sb.from('zone_rotation_members').select().inFilter('zone_id', zoneIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ----------------- Guardar reglas de una zona
  // Nota: si no tienes UNIQUE(zone_id) en zone_schedules, hacemos delete+insert.
  Future<void> saveZoneSchedule({
    required String zoneId,
    required int dayOfWeek, // 1..7
    required String mode,   // 'fixed' | 'rotate'
    String? fixedResidentId,
    int? startWeek,
    int? startYear,
  }) async {
    await sb.from('zone_schedules').delete().eq('zone_id', zoneId);
    await sb.from('zone_schedules').insert({
      'zone_id': zoneId,
      'day_of_week': dayOfWeek,
      'mode': mode,
      'fixed_resident_id': fixedResidentId,
      if (startWeek != null) 'start_week': startWeek,
      if (startYear != null) 'start_year': startYear,
    });
  }

  // Asegura miembros de rotación (si no existen, crea todos)
  Future<void> ensureRotationMembers({
    required String zoneId,
    required List<String> residentIds,
  }) async {
    // Lee actuales
    final current = await sb.from('zone_rotation_members').select().eq('zone_id', zoneId);
    final currentSet = current.map((e) => e['resident_id'] as String).toSet();
    final toInsert = <Map<String, dynamic>>[];
    int idx = current.length;
    for (final rid in residentIds) {
      if (!currentSet.contains(rid)) {
        toInsert.add({
          'zone_id': zoneId,
          'resident_id': rid,
          'order_index': idx++,
          'active': true,
        });
      }
    }
    if (toInsert.isNotEmpty) {
      await sb.from('zone_rotation_members').insert(toInsert);
    }
  }

  // ----------------- Asignaciones semanales
  Future<List<Map<String, dynamic>>> getAssignmentsForWeek({
    required String profileId,
    required int week,
    required int year,
  }) async {
    final rows = await sb
        .from('assignments')
        .select()
        .eq('profile_id', profileId)
        .eq('week_number', week)
        .eq('week_year', year);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> saveAssignments(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await sb.from('assignments').upsert(
      rows,
      onConflict: 'profile_id,zone_id,week_year,week_number,day_of_week',
    );
  }

  // Construye (en memoria) la semana a partir de reglas
  Future<List<Map<String, dynamic>>> buildWeek({
    required Map<String, dynamic> profile, // cleaning_profiles
    required DateTime weekDate,
  }) async {
    final (week: w, year: y) = isoWeekYear(weekDate);
    final houseId = profile['house_id'] as String;

    final zones = await getZonesByHouse(houseId);
    final zoneIds = zones.map((z) => z['id'] as String).toList();

    final schedules = await getSchedulesForZones(zoneIds);
    final members = await getRotationMembersForZones(zoneIds);
    final residents = await getResidentsByHouse(houseId);

    // Mapa rápido para nombre de residente
    final resById = {for (final r in residents) r['id'] as String: r};

    // Asegura rotación mínima (si no hay, incluye a todos)
    for (final z in zoneIds) {
      final has = members.any((m) => m['zone_id'] == z);
      if (!has && residents.isNotEmpty) {
        await ensureRotationMembers(
          zoneId: z,
          residentIds: residents.map((r) => r['id'] as String).toList(),
        );
      }
    }
    final members2 = await getRotationMembersForZones(zoneIds);

    // agrupa miembros por zona y ordena por order_index
    final byZone = <String, List<Map<String, dynamic>>>{};
    for (final m in members2) {
      final z = m['zone_id'] as String;
      (byZone[z] ??= []).add(m);
    }
    for (var l in byZone.values) {
      l.sort((a,b)=> (a['order_index'] as int).compareTo(b['order_index'] as int));
    }

    final out = <Map<String, dynamic>>[];
    for (final sc in schedules) {
      final z = sc['zone_id'] as String;
      final mode = sc['mode'] as String; // 'fixed' | 'rotate'
      final day = sc['day_of_week'] as int; // 1..7
      final startWeek = (sc['start_week'] as int?) ?? w;
      final startYear = (sc['start_year'] as int?) ?? y;

      String? residentId;
      bool isFixed = false;

      if (mode == 'fixed') {
        residentId = sc['fixed_resident_id'] as String?;
        isFixed = true;
      } else {
        final list = (byZone[z] ?? []).where((m)=>(m['active'] as bool? ?? true)).toList();
        if (list.isNotEmpty) {
          int delta = (y - startYear) * 53 + (w - startWeek);
          if (delta < 0) delta = 0;
          final idx = delta % list.length;
          residentId = list[idx]['resident_id'] as String;
        }
      }

      if (residentId != null) {
        out.add({
          'profile_id': profile['id'],
          'zone_id': z,
          'resident_id': residentId,
          'week_number': w,
          'week_year': y,
          'day_of_week': day,
          'is_fixed': isFixed,
          // campos de solo lectura: nombres para UI
          '_zone': zones.firstWhere((e)=> e['id']==z, orElse: ()=>{'name':'(zona)'}),
          '_resident': resById[residentId] ?? {'name':'(residente)'},
        });
      }
    }
    return out;
  }
}