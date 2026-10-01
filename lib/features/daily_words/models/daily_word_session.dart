// lib/features/daily_words/models/daily_word_session.dart
class DailyWordItem {
  final int wordId;
  final String en;
  final String tr;
  final DateTime? completedAt;

  DailyWordItem({
    required this.wordId,
    required this.en,
    required this.tr,
    this.completedAt,
  });

  factory DailyWordItem.fromJson(Map<String, dynamic> json) {
    return DailyWordItem(
      wordId: json['wordId'],
      en: json['en'] ?? '',
      tr: json['tr'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

class DailyWordSession {
  final int id;
  final String listName;
  final List<DailyWordItem> dailyWords;
  final List<DailyWordItem> completedWords;
  final List<int> remainingWordIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyWordSession({
    required this.id,
    required this.listName,
    required this.dailyWords,
    required this.completedWords,
    required this.remainingWordIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyWordSession.fromJson(Map<String, dynamic> json) {
    return DailyWordSession(
      id: json['id'] ?? 0,
      listName: json['listName'] ?? '',
      dailyWords: (json['dailyWords'] as List?)
              ?.map((e) => DailyWordItem.fromJson(e))
              .toList() ??
          [],
      completedWords: (json['completedWords'] as List?)
              ?.map((e) => DailyWordItem.fromJson(e))
              .toList() ??
          [],
      remainingWordIds: (json['remainingWordIds'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
