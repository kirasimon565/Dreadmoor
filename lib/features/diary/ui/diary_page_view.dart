import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class DiaryPageView extends ConsumerStatefulWidget {
  final String pageId;

  const DiaryPageView({
    super.key,
    required this.pageId,
  });

  @override
  ConsumerState<DiaryPageView> createState() => _DiaryPageViewState();
}

class _DiaryPageViewState extends ConsumerState<DiaryPageView> {
  String _fullText = "";
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;
  bool _isLoading = true;
  String _pageTitle = "Diary Page";

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    try {
      final episodeId = ref.read(currentEpisodeIdProvider) ?? 'ep01';
      final path = 'assets/story/$episodeId/diary/${widget.pageId}.json';

      final jsonString = await rootBundle.loadString(path);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final contentArray = data['content'] as List<dynamic>? ?? [];
      final parsedText = contentArray.map((e) => e.toString()).join('\n\n');

      final pageNum = data['page']?.toString() ?? '';

      if (mounted) {
        setState(() {
          _fullText = parsedText;
          _pageTitle = "Page $pageNum";
          _isLoading = false;
        });
        _startTypewriter();
      }
    } catch (e) {
      // Fallback in case of missing file or bad JSON
      if (mounted) {
        setState(() {
          _fullText = "Error loading diary page data.";
          _isLoading = false;
        });
        _startTypewriter();
      }
    }
  }

  void _startTypewriter() {
    _scheduleNextCharacter();
  }

  void _scheduleNextCharacter() {
    if (_currentIndex >= _fullText.length) return;

    final char = _fullText[_currentIndex];

    int delay = 20 + Random().nextInt(30);
    if ('.!,?'.contains(char)) {
      delay += 120;
    }

    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;

      setState(() {
        _displayedText += char;
        _currentIndex++;
      });

      _scheduleNextCharacter();
    });
  }

  void _skipAnimation() {
    _timer?.cancel();
    if (_displayedText != _fullText) {
      setState(() {
        _displayedText = _fullText;
        _currentIndex = _fullText.length;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B14),
        title: const Text("Diary"),
        automaticallyImplyLeading: false, // OS handles nav
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D1B14)))
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skipAnimation,
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAD6),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pageTitle,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _displayedText,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
