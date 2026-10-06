import 'package:flutter/material.dart';

/// Stand-in for screens built in later steps.
class TodoScreen extends StatelessWidget {
  const TodoScreen(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: Text('به‌زودی')));
}
