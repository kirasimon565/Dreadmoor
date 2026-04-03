class DiaryState {
  final String targetWord;
  final List<String?> enteredLetters;
  final bool isUnlocked;
  final bool isCompleted;

  DiaryState({
    required this.targetWord,
    required this.enteredLetters,
    required this.isUnlocked,
    required this.isCompleted,
  });

  DiaryState copyWith({
    String? targetWord,
    List<String?>? enteredLetters,
    bool? isUnlocked,
    bool? isCompleted,
  }) {
    return DiaryState(
      targetWord: targetWord ?? this.targetWord,
      enteredLetters: enteredLetters ?? this.enteredLetters,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
