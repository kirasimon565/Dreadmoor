import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/ui/os/os_state.dart';

/// Shared profile layout — used by both CharacterProfileScreen
/// and PlayerProfileScreen.
///
/// Stack layers:
///   0 — Background image          (Positioned.fill)
///   1 — White card                (Positioned, FIXED — never moves)
///   1a— ScrollView inside card    (only content scrolls, card stays put)
///   2 — Circular avatar           (Positioned, FIXED)
///   3 — Back button               (Positioned, FIXED — optional)
class ProfileLayout extends StatelessWidget {
  final String?       avatarPath;
  final String?       headerImage;
  final String        heroTag;
  final VoidCallback? onAvatarTap;
  final List<Widget>  cardContent;
  final bool          showBackButton;

  static const double headerHeight = 320.0;
  static const double cardOverlap  = 115.0;
  static const double avatarRadius = 80.0;
  static const double _cardTop     = headerHeight - cardOverlap;
  static const double _avatarTop   = _cardTop - avatarRadius;

  const ProfileLayout({
    super.key,
    required this.avatarPath,
    required this.headerImage,
    required this.heroTag,
    required this.cardContent,
    this.onAvatarTap,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Read the real top padding BEFORE stripping it, so the back button
    // can still be positioned correctly relative to the status bar.
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;

    // FIX: double status bar.
    // The old code had a DreadmoorStatusBar() widget manually placed as
    // Layer 4 in the stack. Flutter's Scaffold also automatically insets
    // its body by MediaQuery.padding.top (the system status bar height).
    // That made the status bar height appear twice.
    //
    // Fix: remove the manual DreadmoorStatusBar layer entirely, and wrap
    // Scaffold in MediaQuery.removePadding(removeTop: true) so Scaffold
    // adds zero top inset. The OS shell's DreadmoorStatusBar already
    // handles that space in the parent column.
    return MediaQuery.removePadding(
      context:   context,
      removeTop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F141A),
        body: SizedBox.expand(
          child: Stack(
            children: [

              // ── LAYER 0: background image ──────────────────────────
              Positioned.fill(
                child: Image.asset(
                  headerImage ?? 'assets/media/headers/default_header.jpg',
                  fit:       BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/media/headers/default_header.jpg',
                    fit:       BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),

              // ── LAYER 1: white card — FIXED to viewport ────────────
              Positioned(
                top:    _cardTop,
                left:   0,
                right:  0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(48),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: avatarRadius + 24),
                          ...cardContent,
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── LAYER 2: avatar — fixed to viewport ────────────────
              Positioned(
                top:  _avatarTop,
                left: screenW / 2 - avatarRadius,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Hero(
                    tag: heroTag,
                    child: Container(
                      width:  avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        color:  Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color:        Colors.black.withOpacity(0.25),
                            blurRadius:   20,
                            spreadRadius: 2,
                            offset:       const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _resolveImage(avatarPath)),
                    ),
                  ),
                ),
              ),

              // ── LAYER 3: back button — fixed to viewport ───────────
              if (showBackButton)
                Positioned(
                  top:  topPad + 8,
                  left: 8,
                  child: Consumer(
                    builder: (context, ref, _) {
                      return IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size:  22,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            ref.read(activeAppProvider.notifier)
                                .setApp(PhoneApp.messenger);
                          }
                        },
                      );
                    },
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.grey, size: 72),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.grey, size: 72),
        ),
      );
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}
