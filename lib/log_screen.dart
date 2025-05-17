// filepath: /Users/peterbailey/source/repos/tada/lib/log_screen.dart
import 'package:flutter/material.dart';

class LogScreen extends StatelessWidget {
  final String log;

  const LogScreen({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Log'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            log,
            style: const TextStyle(
              fontFamily: 'Courier New',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}