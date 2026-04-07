import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../diary_state.dart';

class DiaryDao {
  final AppDatabase db;

  DiaryDao(this.db);

  Future<DiaryState?> loadState(String pageId) async {
    final row = await (db.select(db.diaryStateTable)
          ..where((t) => t.id.equals(pageId)))
        .getSingleOrNull();

    if (row == null) return null;

    List<String?> enteredLetters = [];
    try {
      final List<dynamic> decoded = jsonDecode(row.enteredLetters);
      enteredLetters = decoded.map((e) => e as String?).toList();
    } catch (_) {
      enteredLetters = List.filled(row.targetWord.length, null);
    }

    return DiaryState(
      pageId: row.id,
      targetWord: row.targetWord,
      enteredLetters: enteredLetters,
      isUnlocked: row.isUnlocked,
      isCompleted: row.isCompleted,
    );
  }

  Future<void> saveState(DiaryState state) async {
    final lettersJson = jsonEncode(state.enteredLetters);
    await db.into(db.diaryStateTable).insertOnConflictUpdate(
      DiaryStateTableCompanion(
        id: Value(state.pageId),
        targetWord: Value(state.targetWord),
        enteredLetters: Value(lettersJson),
        isUnlocked: Value(state.isUnlocked),
        isCompleted: Value(state.isCompleted),
      ),
    );
  }

  Future<void> clearState(String pageId) async {
    await (db.delete(db.diaryStateTable)..where((t) => t.id.equals(pageId))).go();
  }
}
