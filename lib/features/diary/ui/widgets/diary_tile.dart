import 'package:flutter/material.dart';

class DiaryPageTile extends StatelessWidget {
  final int pageNumber;
  final String dateStr;
  final bool isLocked;
  final VoidCallback? onTap;

  const DiaryPageTile({
    super.key,
    required this.pageNumber,
    required this.dateStr,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0EAD6), // Fallback paper color
            borderRadius: BorderRadius.circular(4),
          ),
          foregroundDecoration: isLocked
              ? BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          padding: const EdgeInsets.all(20), // spaceMD
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Page $pageNumber",
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
