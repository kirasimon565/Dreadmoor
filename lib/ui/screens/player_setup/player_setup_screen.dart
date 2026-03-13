import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = 'female';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmIdentity() async {
    if (!mounted || _saving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your phone number.')));
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.selectionClick();

    try {
      final db = ref.read(databaseProvider);

      // Check if player already exists
      final existing = await (db.select(
        db.players,
      )..limit(1)).getSingleOrNull().timeout(const Duration(seconds: 5));

      if (existing != null) {
        // ✅ Set in-memory state immediately — router sees it instantly
        ref.read(playerStateProvider.notifier).state = existing;
        if (mounted) context.go(Routes.welcome);
        return;
      }

      // Insert new player
      final id = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              name: name,
              gender: _selectedGender,
              phoneNumber: Value(phone),
              createdAt: Value(DateTime.now()),
            ),
          )
          .timeout(const Duration(seconds: 5));

      // Fetch the inserted player row
      final newPlayer =
          await (db.select(db.players)..where((p) => p.id.equals(id)))
              .getSingleOrNull()
              .timeout(const Duration(seconds: 5));

      if (newPlayer != null) {
        // ✅ Set in-memory state BEFORE navigating.
        // Router redirect reads playerStateProvider synchronously —
        // no async DB read, no stale cache, no race condition.
        ref.read(playerStateProvider.notifier).state = newPlayer;
      }

      if (mounted) {
        context.go(Routes.welcome);
      }
    } catch (e, s) {
      debugPrint('❌ Failed to save player: $e');
      debugPrintStack(stackTrace: s);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save identity. Try again.')),
        );
        // ✅ Always reset on failure so button never stays locked
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background(Theme.of(context).brightness),
      body: Stack(
        children: [
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

          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WHO ARE YOU",
                    style: GoogleFonts.michroma(
                      fontSize: 13,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.investigatorCyan,
                    ),
                  ),
                  Text(
                    "TO REBECCA?",
                    style: GoogleFonts.michroma(
                      fontSize: 28,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.text(Theme.of(context).brightness),
                    ),
                  ),
                  const SizedBox(height: 48),

                  _GlassInputField(
                    label: "YOUR NAME",
                    hint: "Enter your name",
                    controller: _nameController,
                  ),

                  const SizedBox(height: 24),

                  _GlassInputField(
                    label: "PHONE NUMBER",
                    hint: "Enter phone number",
                    controller: _phoneController,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "IDENTITY",
                    style: GoogleFonts.michroma(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
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
                        color: DreadmoorColors.evidenceRed.withOpacity(0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ConfirmButton(
                    label: _saving ? "SAVING..." : "CONFIRM IDENTITY",
                    onTap: _saving ? () {} : _confirmIdentity,
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
            color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: DreadmoorColors.surface(Theme.of(context).brightness).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DreadmoorColors.investigatorCyan.withOpacity(0.2),
                  width: 0.6,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.inter(color: DreadmoorColors.text(Theme.of(context).brightness)),
                  cursorColor: DreadmoorColors.investigatorCyan,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4),
                    ),
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? DreadmoorColors.investigatorCyan.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? DreadmoorColors.investigatorCyan
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: DreadmoorColors.investigatorCyan.withOpacity(0.5), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? DreadmoorColors.investigatorCyan
                  : DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 11,
                letterSpacing: 2.0,
                color: isSelected
                    ? DreadmoorColors.investigatorCyan
                    : DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
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
              DreadmoorColors.investigatorCyan.withOpacity(0.15),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: DreadmoorColors.investigatorCyan.withOpacity(0.6),
            width: 0.6,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.michroma(
              fontSize: 14,
              letterSpacing: 3.0,
              color: DreadmoorColors.investigatorCyan,
            ),
          ),
        ),
      ),
    );
  }
}
