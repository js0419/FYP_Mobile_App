import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rupakgjscjqppgnbegnx.supabase.co',
    anonKey: 'sb_publishable_fumSaSQJJnnNqX9iVET5fQ_ec01qCi9',
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
      home: TestConnectionPage(),
    );
  }
}

class TestConnectionPage extends StatefulWidget {
  const TestConnectionPage({super.key});

  @override
  State<TestConnectionPage> createState() => _TestConnectionPageState();
}

class _TestConnectionPageState extends State<TestConnectionPage> {
  String message = 'Connecting...';

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
  try {
    final result = await supabase
        .from('products')
        .select('product_name')
        .limit(3);

    if (!mounted) return;

    setState(() {
      message = 'Supabase connected. Products found: ${result.length}';
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      message = 'Connection failed: $e';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}