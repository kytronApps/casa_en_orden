// auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse?> login({required String email, required String password}) async {
    try {
      final result = await _client.auth.signInWithPassword(email: email, password: password);
      return result;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);

      if (res.user != null) {
        await _client.from('residents').insert({
          'id': res.user!.id,
          'name': '',
          'color': '',
          'avatar': ''
        });
        return null;
      } else {
        return 'Error desconocido';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        return null;
      } else {
        return 'Error desconocido';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> fetchResidentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('residents')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }
}