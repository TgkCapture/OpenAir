import 'package:flutter/material.dart';

class TvScreen extends StatelessWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TV')),
      body: const Center(child: Text('TV')),
    );
  }
}