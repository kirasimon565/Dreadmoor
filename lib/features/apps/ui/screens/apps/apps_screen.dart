import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [

          /// Background image
          Positioned.fill(
            child: Image.asset(
              "assets/backgrounds/apps_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// Fog overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [

                      const Icon(Icons.menu, color: Colors.white70),

                      const Spacer(),

                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {
                          context.go('/settings');
                        },
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Apps",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "These applications are available on your device.\n"
                    "More apps will unlock as the investigation progresses.",
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Apps container
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: GridView(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 22,
                            ),
                            children: [

                              /// PHONE APP
                              _appIcon(
                                context,
                                icon: Icons.call,
                                label: "Phone",
                                color: const Color(0xFF53D769),
                                route: "/phone",
                              ),

                              /// PUZZLE
                              _appIcon(
                                context,
                                icon: Icons.extension,
                                label: "Puzzle",
                                color: const Color(0xFF7A5CFF),
                                route: "/puzzle",
                              ),

                              /// BROWSER
                              _appIcon(
                                context,
                                icon: Icons.public,
                                label: "Browser",
                                color: const Color(0xFF4DA3FF),
                                route: "/browser",
                              ),

                              /// LOCKED SLOT
                              _lockedApp(),

                              _lockedApp(),
                              _lockedApp(),
                              _lockedApp(),
                              _lockedApp(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Active app icon
  Widget _appIcon(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required String route,
      }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }

  /// Locked placeholder
  Widget _lockedApp() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.lock_outline,
          color: Colors.white24,
        ),
      ),
    );
  }
}
