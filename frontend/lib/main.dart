import 'package:flutter/material.dart';

void main() {
  runApp(const SddkmApp());
}

class SddkmApp extends StatelessWidget {
  const SddkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('SDDKM MVP: E2E OK')),
      ),
    );
  }
}
