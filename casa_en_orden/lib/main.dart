import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; 

const _envUrl  = String.fromEnvironment('SUPABASE_URL');
const _envKey  = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Primero intentamos leer --dart-define (ideal para Web)
  var url = _envUrl;
  var key = _envKey;

  // 2) Si faltan (mobile/dev), cargamos assets/env.mobile
  if (url.isEmpty || key.isEmpty) {
    try {
      await dotenv.load(fileName: 'assets/env.mobile'); // sin punto
      url = dotenv.env['SUPABASE_URL'] ?? '';
      key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (_) {
      // ignoramos; validamos abajo
    }
  }

  if (url.isEmpty || key.isEmpty) {
    throw Exception(
      '⚠️ Config faltante. Pasa --dart-define SUPABASE_URL / SUPABASE_ANON_KEY '
      'o crea assets/env.mobile con esas claves.'
    );
  }

  await Supabase.initialize(url: url, anonKey: key);

  runApp(const CasaEnOrdenApp());
}