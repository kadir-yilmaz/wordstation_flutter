import 'dart:convert';

class DailyQuizPlanModel {
  final String id;
  final String listName;
  final int dailyCount;
  final List<dynamic> shuffledWordIds;
  final int currentPointer;
  final String? lastCompletedDate; // 'YYYY-MM-DD'
  final int streakDays;
  final bool isEnglishToTurkish;
  final DateTime createdAt;

  const DailyQuizPlanModel({
    required this.id,
    required this.listName,
    required this.dailyCount,
    required this.shuffledWordIds,
    this.currentPointer = 0,
    this.lastCompletedDate,
    this.streakDays = 0,
    this.isEnglishToTurkish = true,
    required this.createdAt,
  });

  int get totalWords => shuffledWordIds.length;
  
  int get remainingWords =>
      (totalWords - currentPointer).clamp(0, totalWords);

  int get totalDays =>
      totalWords > 0 ? (totalWords / dailyCount).ceil() : 0;

  int get completedDays =>
      dailyCount > 0 ? (currentPointer / dailyCount).floor() : 0;

  int get currentDay {
    if (totalWords == 0) return 0;
    if (isPlanFinished) return totalDays;
    final day = (currentPointer / dailyCount).floor() + 1;
    return day.clamp(1, totalDays > 0 ? totalDays : 1);
  }

  /// Aktif gün durumuna göre (bugün çözüldüyse tamamlanan günü, çözülmediyse sıradaki günü) döner
  int displayDay(String todayStr) {
    if (totalWords == 0) return 0;
    if (isPlanFinished) return totalDays;
    if (isCompletedToday(todayStr) && completedDays > 0) {
      return completedDays.clamp(1, totalDays);
    }
    return currentDay;
  }

  int get nextBatchCount => remainingWords.clamp(0, dailyCount);

  bool get isPlanFinished => totalWords > 0 && currentPointer >= totalWords;

  bool isCompletedToday(String todayStr) => lastCompletedDate == todayStr;

  double get progressRatio =>
      totalWords > 0 ? (currentPointer / totalWords).clamp(0.0, 1.0) : 0.0;

  int get progressPercentage => (progressRatio * 100).round();

  DailyQuizPlanModel copyWith({
    String? id,
    String? listName,
    int? dailyCount,
    List<dynamic>? shuffledWordIds,
    int? currentPointer,
    String? lastCompletedDate,
    int? streakDays,
    bool? isEnglishToTurkish,
    DateTime? createdAt,
  }) {
    return DailyQuizPlanModel(
      id: id ?? this.id,
      listName: listName ?? this.listName,
      dailyCount: dailyCount ?? this.dailyCount,
      shuffledWordIds: shuffledWordIds ?? this.shuffledWordIds,
      currentPointer: currentPointer ?? this.currentPointer,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      streakDays: streakDays ?? this.streakDays,
      isEnglishToTurkish: isEnglishToTurkish ?? this.isEnglishToTurkish,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listName': listName,
        'dailyCount': dailyCount,
        'shuffledWordIds': shuffledWordIds,
        'currentPointer': currentPointer,
        'lastCompletedDate': lastCompletedDate,
        'streakDays': streakDays,
        'isEnglishToTurkish': isEnglishToTurkish,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyQuizPlanModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> parsedShuffledIds = [];
    final rawIds = json['shuffledWordIds'] ?? json['ShuffledWordIds'];
    if (rawIds is List) {
      parsedShuffledIds = rawIds;
    } else if (rawIds is String && rawIds.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawIds);
        if (decoded is List) {
          parsedShuffledIds = decoded;
        }
      } catch (_) {}
    }

    final rawCreatedAt = json['createdAt'] ?? json['CreatedAt'];
    DateTime createdAtVal = DateTime.now();
    if (rawCreatedAt != null) {
      createdAtVal = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    final rawId = json['id'] ?? json['Id'];

    return DailyQuizPlanModel(
      id: rawId?.toString() ?? '',
      listName: (json['listName'] ?? json['ListName'] ?? 'Tümü').toString(),
      dailyCount: (json['dailyCount'] ?? json['DailyCount'] as int?) ?? 10,
      shuffledWordIds: parsedShuffledIds,
      currentPointer: (json['currentPointer'] ?? json['CurrentPointer'] as int?) ?? 0,
      lastCompletedDate: (json['lastCompletedDate'] ?? json['LastCompletedDate'])?.toString(),
      streakDays: (json['streakDays'] ?? json['StreakDays'] as int?) ?? 0,
      isEnglishToTurkish: (json['isEnglishToTurkish'] ?? json['IsEnglishToTurkish'] as bool?) ?? true,
      createdAt: createdAtVal,
    );
  }
}
