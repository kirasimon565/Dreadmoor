import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class CharacterProfileScreen extends StatelessWidget {
  final String characterId;

  const CharacterProfileScreen({super.key, required this.characterId});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final name = characterId == 'amelia' ? "AMELIA VANCE" : characterId.toUpperCase();
    final imagePath = 'assets/characters/$characterId.png';
    final age = "24";
    final job = "Journalist";
    final relation = "Childhood Friend";
    final facts = [
      "Last person to see Rebecca alive.",
      "Has been avoiding the factory district.",
      "Recently deleted chat logs.",
    ];

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: DreadmoorColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: GoogleFonts.michroma(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (c,e,s) => Container(color: Colors.grey[900], child: const Icon(Icons.person, size: 100, color: Colors.white24)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Colors.black],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("AGE", age),
                  _buildInfoRow("OCCUPATION", job),
                  _buildInfoRow("RELATION", relation),
                  const SizedBox(height: 32),
                  Text(
                    "KNOWN FACTS",
                    style: GoogleFonts.michroma(fontSize: 14, color: DreadmoorColors.accentCyan),
                  ),
                  const SizedBox(height: 16),
                  ...facts.map((fact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6.0),
                          child: Icon(Icons.circle, size: 6, color: DreadmoorColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fact,
                            style: GoogleFonts.inter(fontSize: 14, color: DreadmoorColors.textPrimary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: DreadmoorColors.accentRed.withOpacity(0.5)),
                      color: DreadmoorColors.accentRed.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CONTRADICTIONS", style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentRed)),
                        const SizedBox(height: 8),
                        Text("None detected yet.", style: GoogleFonts.inter(fontSize: 13, color: DreadmoorColors.accentRed.withOpacity(0.7), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.michroma(fontSize: 11, color: DreadmoorColors.textMeta),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: DreadmoorColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
