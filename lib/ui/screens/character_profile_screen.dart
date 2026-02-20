import 'package:flutter/material.dart';

class CharacterProfileScreen extends StatelessWidget {
  final String characterId;
  const CharacterProfileScreen({Key? key, required this.characterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final data = _getCharacterData(characterId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(data['name']!, style: const TextStyle(fontFamily: 'Cinzel', color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              background: Image.asset(
                'assets/characters/${characterId.toLowerCase()}.png',
                fit: BoxFit.cover,
                errorBuilder: (c,o,s) => Container(color: Colors.grey[900], child: const Icon(Icons.person, size: 100, color: Colors.grey)),
              ),
            ),
            backgroundColor: Colors.grey[900],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('ROLE', data['role']!),
                    _buildSection('AGE', data['age']!),
                    const Divider(color: Colors.grey),
                    _buildSection('KNOWN FACTS', data['facts']!),
                    const SizedBox(height: 20),
                    if (data.containsKey('secrets'))
                       _buildSection('SECRETS (LOCKED)', '???', isLocked: true),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isLocked = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isLocked ? Colors.redAccent : Colors.purple[200],
              fontSize: 14,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isLocked ? Colors.grey[600] : Colors.white,
              fontSize: 16,
              height: 1.5,
              fontFamily: 'Merriweather',
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getCharacterData(String id) {
    // In a real app, fetch from DB/Provider
    switch (id) {
      case 'amelia':
        return {
          'name': 'AMELIA',
          'role': 'Best Friend',
          'age': '24',
          'facts': 'Amelia has known Rebecca since childhood. She was the last person to call her before the disappearance.',
          'secrets': 'true',
        };
      case 'michael':
        return {
          'name': 'MICHAEL',
          'role': 'Boyfriend',
          'age': '26',
          'facts': 'Michael and Rebecca were arguing recently. He claims he was at work during the incident.',
        };
      default:
        return {
          'name': id.toUpperCase(),
          'role': 'Unknown',
          'age': 'Unknown',
          'facts': 'No information available.',
        };
    }
  }
}
