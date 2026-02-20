import 'package:flutter/material.dart';

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAVE / LOAD', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          final isAuto = index == 0;
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: isAuto ? Colors.purple : Colors.grey[800]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                isAuto ? 'AUTOSAVE' : 'SLOT ${index}',
                style: TextStyle(
                  color: isAuto ? Colors.purple[200] : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    isAuto ? 'Episode 1: The Disappearance' : 'Empty Slot',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  if (isAuto)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('2 mins ago', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                ],
              ),
              trailing: isAuto ? const Icon(Icons.check_circle, color: Colors.purple) : null,
              onTap: () {
                // Load Logic
              },
            ),
          );
        },
      ),
    );
  }
}
