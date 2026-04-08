import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DiaryPageView extends StatefulWidget {
  final String pageId;
  final int pageNumber;
  final String dateStr;
  final List<String> contentList;

  const DiaryPageView({
    super.key,
    required this.pageId,
    required this.pageNumber,
    required this.dateStr,
    required this.contentList,
  });

  @override
  State<DiaryPageView> createState() => _DiaryPageViewState();
}

class _DiaryPageViewState extends State<DiaryPageView> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;
  late String _fullContent;

  @override
  void initState() {
    super.initState();
    _fullContent = widget.contentList.join('\n\n');
    _startTypewriter();
  }

  void _startTypewriter() {
    _scheduleNextCharacter();
  }

  void _scheduleNextCharacter() {
    if (_currentIndex >= _fullContent.length) return;

    final char = _fullContent[_currentIndex];

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
    if (_displayedText != _fullContent) {
      setState(() {
        _displayedText = _fullContent;
        _currentIndex = _fullContent.length;
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
      body: GestureDetector(
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
                  widget.dateStr,
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
