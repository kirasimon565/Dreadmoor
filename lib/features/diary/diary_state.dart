class DiaryState {
  final String pageId;
  final String targetWord;
  final List<String?> enteredLetters;
  final bool isUnlocked;
  final bool isCompleted;

  DiaryState({
    required this.pageId,
    required this.targetWord,
    required this.enteredLetters,
    required this.isUnlocked,
    required this.isCompleted,
  });

  factory DiaryState.initial(String word, String pageId) {
    return DiaryState(
      pageId: pageId,
      targetWord: word.toUpperCase(),
      enteredLetters: List.filled(word.length, null),
      isUnlocked: false,
      isCompleted: false,
    );
  }

  DiaryState copyWith({
    String? pageId,
    String? targetWord,
    List<String?>? enteredLetters,
    bool? isUnlocked,
    bool? isCompleted,
  }) {
    return DiaryState(
      pageId: pageId ?? this.pageId,
      targetWord: targetWord ?? this.targetWord,
      enteredLetters: enteredLetters ?? this.enteredLetters,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
