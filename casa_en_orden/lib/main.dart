import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sqftsqtejjakljqxwqzc.supabase.co',       // 👈 Reemplaza esto
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxZnRzcXRlampha2xqcXh3cXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3MDQ5MjcsImV4cCI6MjA2NjI4MDkyN30.EK3pOHueTrdsMNMe7rS4bslGla1FZYuSsaV5Pvg3bDs',                      // 👈 Reemplaza esto
  );

  runApp(const CasaEnOrdenApp());
}