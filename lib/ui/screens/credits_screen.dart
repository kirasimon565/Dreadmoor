import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CREDITS', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.grey[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Column(
            children: [
              Image.asset('assets/branding/blackmoon_logo.png', width: 100, errorBuilder: (c,o,s) => const Icon(Icons.nightlight, size: 50, color: Colors.white)),
              const SizedBox(height: 20),
              const Text(
                'BLACKMOON STUDIO',
                style: TextStyle(fontFamily: 'Cinzel', fontSize: 24, letterSpacing: 4, color: Colors.white),
              ),
              const SizedBox(height: 60),
              _buildRole('Game Director', 'You'),
              _buildRole('Lead Writer', 'You'),
              _buildRole('Lead Developer', 'You'),
              _buildRole('Art Direction', 'You'),
              const SizedBox(height: 40),
              const Text('Built with Flutter & Drift', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              const Text('© 2024 BlackMoon Studio', style: TextStyle(color: Color(0xFF424242), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRole(String role, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(role.toUpperCase(), style: TextStyle(color: Colors.purple[200], fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cinzel')),
        ],
      ),
    );
  }
}
