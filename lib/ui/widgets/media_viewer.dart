import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:dreadmoor/core/state/game_state.dart';

/// Call this to open the full-screen viewer:
///
/// ```dart
/// MediaViewer.open(context, items: gallery, initialIndex: index);
/// ```
class MediaViewer extends StatelessWidget {
  final List<GalleryMediaItem> items;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  /// Hero-animated push into full-screen viewer.
  static Future<void> open(
    BuildContext context, {
    required List<GalleryMediaItem> items,
    int initialIndex = 0,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => MediaViewer(
          items: items,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MediaViewerPage(items: items, initialIndex: initialIndex);
  }
}

// ── FULL SCREEN PAGER ─────────────────────────────────────────────────────────

class _MediaViewerPage extends StatefulWidget {
  final List<GalleryMediaItem> items;
  final int initialIndex;

  const _MediaViewerPage({required this.items, required this.initialIndex});

  @override
  State<_MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<_MediaViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;
  bool _barsVisible = true;
  late final AnimationController _barsAnim;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _barsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    // Go edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _barsAnim.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    _barsVisible ? _barsAnim.forward() : _barsAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── SWIPEABLE PAGES ─────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleBars,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                return item.isVideo
                    ? _VideoPage(item: item)
                    : _ImagePage(item: item);
              },
            ),
          ),

          // ── TOP BAR ─────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _barsAnim,
              child: IgnorePointer(
                ignoring: !_barsVisible,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 16,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Close
                      Consumer(
                        builder: (context, ref, _) {
                          return IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 26),
                            onPressed: () {
                              Navigator.pop(context);
                              // Resume story if it was paused waiting for video
                              ref.read(globalSchedulerProvider).resume();
                            },
                          );
                        }
                      ),
                      const Spacer(),
                      // Counter
                      if (widget.items.length > 1)
                        Text(
                          '${_currentIndex + 1} / ${widget.items.length}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM CAPTION BAR ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _barsAnim,
              child: IgnorePointer(
                ignoring: !_barsVisible,
                child: _BottomBar(
                  item: widget.items[_currentIndex],
                  totalItems: widget.items.length,
                  currentIndex: _currentIndex,
                ),
              ),
            ),
          ),

          // ── DOT INDICATOR ───────────────────────────────────────────────
          if (widget.items.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 72,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _barsAnim,
                child: _DotIndicator(
                  count: widget.items.length,
                  current: _currentIndex,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── IMAGE PAGE ────────────────────────────────────────────────────────────────

class _ImagePage extends StatelessWidget {
  final GalleryMediaItem item;
  const _ImagePage({required this.item});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(
        child: item.path.startsWith('assets/')
            ? Image.asset(item.path, fit: BoxFit.contain)
            : Image.file(File(item.path), fit: BoxFit.contain),
      ),
    );
  }
}

// ── VIDEO PAGE ────────────────────────────────────────────────────────────────

class _VideoPage extends StatefulWidget {
  final GalleryMediaItem item;
  const _VideoPage({required this.item});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.item.path.startsWith('assets/')
        ? VideoPlayerController.asset(widget.item.path)
        : VideoPlayerController.file(File(widget.item.path));

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.play();
      }
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Play / Pause overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),

          // Scrubber
          if (_showControls)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: _VideoScrubber(controller: _controller),
            ),
        ],
      ),
    );
  }
}

// ── VIDEO SCRUBBER ────────────────────────────────────────────────────────────

class _VideoScrubber extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoScrubber({required this.controller});

  @override
  Widget build(BuildContext context) {
    final position = controller.value.position;
    final duration = controller.value.duration;
    final progress =
        duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: SliderComponentShape.noOverlay,
            trackHeight: 2,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) {
              final target = Duration(
                milliseconds: (v * duration.inMilliseconds).round(),
              );
              controller.seekTo(target);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── BOTTOM CAPTION BAR ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final GalleryMediaItem item;
  final int totalItems;
  final int currentIndex;

  const _BottomBar({
    required this.item,
    required this.totalItems,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final hasCaption = item.caption != null && item.caption!.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.70),
            Colors.transparent,
          ],
        ),
      ),
      child: hasCaption
          ? Text(
              item.caption!,
              style: GoogleFonts.spectral(
                color: Colors.white.withOpacity(0.88),
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── DOT INDICATOR ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── MEDIA ITEM MODEL ──────────────────────────────────────────────────────────

class GalleryMediaItem {
  final String path;
  final String? caption;
  final bool isVideo;

  const GalleryMediaItem({
    required this.path,
    this.caption,
    this.isVideo = false,
  });

  /// Convenience factory from your MediaItem DB model.
  static GalleryMediaItem fromPhoto(dynamic photo) {
    try {
      final path = photo.filePath as String;
      final type = photo.mediaType as String;
      return GalleryMediaItem(
        path: path,
        caption: null,
        isVideo: type == 'video',
      );
    } catch (e) {
      final path = photo.photoPath as String;
      final isVideo = path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi');
      return GalleryMediaItem(
        path: path,
        caption: photo.caption as String?,
        isVideo: isVideo,
      );
    }
  }
}
