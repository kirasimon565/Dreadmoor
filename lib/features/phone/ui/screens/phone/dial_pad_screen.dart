import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {

  String number = "";

  void addDigit(String digit) {
    setState(() {
      number += digit;
    });
  }

  void deleteDigit() {
    if (number.isEmpty) return;

    setState(() {
      number = number.substring(0, number.length - 1);
    });
  }

  void makeCall() {
    if (number.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallingScreen(number: number),
      ),
    );
  }

  Widget dialButton(String text) {
    return GestureDetector(
      onTap: () => addDigit(text),
      child: Container(
        height: 80,
        width: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2A2A2A),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Phone"),
      ),

      body: Column(
        children: [

          const SizedBox(height: 40),

          Text(
            number.isEmpty ? "Enter number" : number,
            style: GoogleFonts.robotoMono(
              fontSize: 32,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              children: [

                dialButton("1"),
                dialButton("2"),
                dialButton("3"),

                dialButton("4"),
                dialButton("5"),
                dialButton("6"),

                dialButton("7"),
                dialButton("8"),
                dialButton("9"),

                dialButton("*"),
                dialButton("0"),
                dialButton("#"),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white),
                onPressed: () {},
              ),

              GestureDetector(
                onTap: makeCall,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.backspace, color: Colors.white),
                onPressed: deleteDigit,
              ),
            ],
          ),

          const SizedBox(height: 30)
        ],
      ),
    );
  }
}
