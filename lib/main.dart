import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'entry_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fgqreknznpqdecmpmjsc.supabase.co',   //  SUPABASE URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZncXJla256bnBxZGVjbXBtanNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzOTI1ODQsImV4cCI6MjA3ODk2ODU4NH0.71c8aRhJWxept9ipH5ckhpOAAYxUXSJtqzznTqlvZpU',                     //  SUPABASE ANON KEY
  );

  runApp(const AccountBookApp());
}
final suoabase = Supabase.instance.client;

class AccountBookApp extends StatelessWidget {
  const AccountBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const EntryPage(),
    );
  }
}


