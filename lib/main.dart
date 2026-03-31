import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/shop/home.dart'; // 1. Import your Home Screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xvtdspoevpdphetbetnw.supabase.co',
    anonKey: 'sb_publishable_o2j3-NLwaZ2F6gCIOc0Lkg_UOZNUnwb',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // 2. Set the home property to your HomeScreen
      home: HomeScreen(), 
    );
  }
}