// lib/features/minigame/tracecore/utils/clue_formatter.dart

/// Formats a raw clue string for terminal display.
/// Converts newlines to styled lines, adds a `>` prompt prefix.
class ClueFormatter {
  static List<String> format(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => '> $line')
        .toList();
  }

  /// Returns all unique IPs found in a list of formatted lines.
  static List<String> extractIps(String raw) {
    final regex = RegExp(
        r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b');
    return regex
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  /// Returns all unique names found after "Name:" in the raw string.
  static List<String> extractNames(String raw) {
    final regex = RegExp(r'Name:\s*(.+)');
    return regex
        .allMatches(raw)
        .map((m) => m.group(1)!.trim())
        .toSet()
        .toList();
  }
}
