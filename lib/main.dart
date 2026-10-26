
import 'package:flutter/material.dart';

void main() {
  runApp(const MahalliApp());
}

class MahalliApp extends StatelessWidget {
  const MahalliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محلّي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F5B),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'محلّي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 90,
                  color: Color(0xFF087F5B),
                ),
                const SizedBox(height: 20),
                const Text(
                  'أهلًا بك في محلّي',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سوقك المحلي، ومتجرك في مكان واحد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('استكشف السوق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
