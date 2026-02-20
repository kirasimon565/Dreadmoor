import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DREADMOOR MAP', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 2.0,
        child: Stack(
          children: [
            Image.asset(
              'assets/map/dreadmore_map.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c,o,s) => Container(color: Colors.grey[800], child: const Center(child: Text('Map Unavailable', style: TextStyle(color: Colors.white)))),
            ),
            // Example Pins
            _buildPin(context, 100, 200, 'Factory', 'visited_factory'),
            _buildPin(context, 300, 400, 'Rebecca\'s Home', 'visited_home'),
          ],
        ),
      ),
    );
  }

  Widget _buildPin(BuildContext context, double x, double y, String label, String flag) {
    // In real app, check flag status
    bool unlocked = true;

    if (!unlocked) return const SizedBox.shrink();

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          _showLocationInfo(context, label);
        },
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationInfo(BuildContext context, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cinzel', fontSize: 24, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('A key location in the investigation.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }
}
