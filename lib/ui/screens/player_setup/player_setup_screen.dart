import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _nameController = TextEditingController();
  String _selectedGender = 'male'; // Default or none? Spec implies selection. Defaulting to male for simplicity or allow null? Spec shows 'MALE' and 'FEMALE'.

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmIdentity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    // Create player profile
    await db.into(db.players).insert(PlayersCompanion.insert(
      id: 'player',
      name: name,
      gender: _selectedGender,
      joinedAt: DateTime.now(),
    ));

    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // [0] Silhouette
          Positioned(
            bottom: 0,
            right: -40,
            child: Image.asset(
              'assets/characters/rebecca_silhouette.png',
              height: 420,
              fit: BoxFit.fitHeight,
              color: Colors.white.withOpacity(0.03),
              colorBlendMode: BlendMode.modulate,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          // [1] Glitch Overlay
          Opacity(
            opacity: 0.04,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          // [2] Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WHO ARE YOU",
                    style: GoogleFonts.michroma(
                      fontSize: 13,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.accentCyan,
                    ),
                  ),
                  Text(
                    "TO REBECCA?",
                    style: GoogleFonts.michroma(
                      fontSize: 28,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _GlassInputField(
                    label: "YOUR NAME",
                    hint: "Enter your name",
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "IDENTITY",
                    style: GoogleFonts.michroma(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _GenderChip(
                        label: "MALE",
                        icon: Icons.male,
                        isSelected: _selectedGender == 'male',
                        onTap: () => setState(() => _selectedGender = 'male'),
                      ),
                      const SizedBox(width: 12),
                      _GenderChip(
                        label: "FEMALE",
                        icon: Icons.female,
                        isSelected: _selectedGender == 'female',
                        onTap: () => setState(() => _selectedGender = 'female'),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      "THIS CANNOT BE CHANGED LATER.",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DreadmoorColors.accentRed.withOpacity(0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConfirmButton(
                    label: "CONFIRM IDENTITY",
                    onTap: _confirmIdentity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _GlassInputField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.michroma(
            fontSize: 11,
            letterSpacing: 2.0,
            color: DreadmoorColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DreadmoorColors.accentCyan.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
                  cursorColor: DreadmoorColors.accentCyan,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(color: DreadmoorColors.textMeta),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DreadmoorColors.accentCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DreadmoorColors.accentCyan : Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 11,
                letterSpacing: 2.0,
                color: isSelected ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ConfirmButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DreadmoorColors.accentCyan.withOpacity(0.15),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: DreadmoorColors.accentCyan.withOpacity(0.6),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.michroma(
              fontSize: 14,
              letterSpacing: 3.0,
              color: DreadmoorColors.accentCyan,
            ),
          ),
        ),
      ),
    );
  }
}
