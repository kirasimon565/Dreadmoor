import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _textSpeed = 1.0;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('GAMEPLAY'),
          _buildSlider('Text Speed', _textSpeed, (v) => setState(() => _textSpeed = v)),

          const SizedBox(height: 20),
          _buildSectionHeader('AUDIO'),
          _buildSlider('Music Volume', _musicVolume, (v) => setState(() => _musicVolume = v)),
          _buildSlider('SFX Volume', _sfxVolume, (v) => setState(() => _sfxVolume = v)),

          const SizedBox(height: 20),
          _buildSectionHeader('SYSTEM'),
          ListTile(
            title: const Text('Accessibility', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {},
          ),
           ListTile(
            title: const Text('Reset Tutorials', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),

          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onLongPress: () {
                // Secret Debug Access
                context.push('/debug');
              },
              child: Text(
                'v0.1.0',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.purple[200],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Slider(
          value: value,
          activeColor: Colors.purple,
          inactiveColor: Colors.grey[800],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
