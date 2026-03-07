import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Store"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Store Coming Soon",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
