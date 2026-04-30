import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exampleToggle = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile(
              value: _exampleToggle,
              onChanged: (v) => setState(() => _exampleToggle = v),
              title: const Text('Example toggle'),
              subtitle: const Text('Wire this up to real settings later.'),
            ),
          ],
        ),
      ),
    );
  }
}

