import 'dart:convert';

enum PlanType {
  sequential, // Otomatik Sıralı (Sıfır Tekrar)
  openBuffet, // Açık Büfe (Manuel Günlük Kelime Seçimi)
}

class DailyQuizPlanModel {
  final String id;
  final String title;
  final String listName;
  final PlanType planType;
  final int dailyCount;
  final List<dynamic> shuffledWordIds;
  final List<dynamic> completedWordIds;
  final List<dynamic> dailySelectedWordIds;
  final int currentPointer;
  final String? lastCompletedDate; // 'YYYY-MM-DD'
  final int streakDays;
  final bool isEnglishToTurkish;
  final bool isActive;
  final DateTime createdAt;

  const DailyQuizPlanModel({
    required this.id,
    this.title = '',
    required this.listName,
    this.planType = PlanType.sequential,
    required this.dailyCount,
    required this.shuffledWordIds,
    this.completedWordIds = const [],
    this.dailySelectedWordIds = const [],
    this.currentPointer = 0,
    this.lastCompletedDate,
    this.streakDays = 0,
    this.isEnglishToTurkish = true,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isOpenBuffet => planType == PlanType.openBuffet;

  int get totalWords => shuffledWordIds.length;

  int get completedWordsCount =>
      isOpenBuffet ? completedWordIds.length : currentPointer.clamp(0, totalWords);

  int get remainingWords => isOpenBuffet
      ? (totalWords - completedWordIds.length).clamp(0, totalWords)
      : (totalWords - currentPointer).clamp(0, totalWords);

  int get buffetPoolRemainingCount =>
      (totalWords - completedWordIds.length).clamp(0, totalWords);

  int get dailySelectedCount => dailySelectedWordIds.length;

  bool get hasDailyBuffetSelection => dailySelectedWordIds.isNotEmpty;

  int get totalDays =>
      totalWords > 0 ? (totalWords / dailyCount).ceil() : 0;

  int get completedDays =>
      dailyCount > 0 ? (completedWordsCount / dailyCount).floor() : 0;

  int get currentDay {
    if (totalWords == 0) return 0;
    if (isPlanFinished) return totalDays;
    final day = (completedWordsCount / dailyCount).floor() + 1;
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

  bool get isPlanFinished =>
      totalWords > 0 && remainingWords == 0;

  bool isCompletedToday(String todayStr) => lastCompletedDate == todayStr;

  double get progressRatio {
    if (totalWords == 0) return 0.0;
    return (completedWordsCount / totalWords).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progressRatio * 100).round();

  String get displayTitle {
    if (title.isNotEmpty) return title;
    return '$listName ${isOpenBuffet ? 'Açık Büfe' : 'Sıralı Plan'}';
  }

  DailyQuizPlanModel copyWith({
    String? id,
    String? title,
    String? listName,
    PlanType? planType,
    int? dailyCount,
    List<dynamic>? shuffledWordIds,
    List<dynamic>? completedWordIds,
    List<dynamic>? dailySelectedWordIds,
    int? currentPointer,
    String? lastCompletedDate,
    int? streakDays,
    bool? isEnglishToTurkish,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DailyQuizPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      listName: listName ?? this.listName,
      planType: planType ?? this.planType,
      dailyCount: dailyCount ?? this.dailyCount,
      shuffledWordIds: shuffledWordIds ?? this.shuffledWordIds,
      completedWordIds: completedWordIds ?? this.completedWordIds,
      dailySelectedWordIds: dailySelectedWordIds ?? this.dailySelectedWordIds,
      currentPointer: currentPointer ?? this.currentPointer,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      streakDays: streakDays ?? this.streakDays,
      isEnglishToTurkish: isEnglishToTurkish ?? this.isEnglishToTurkish,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'listName': listName,
        'planType': planType == PlanType.openBuffet ? 1 : 0,
        'dailyCount': dailyCount,
        'shuffledWordIds': shuffledWordIds,
        'completedWordIds': completedWordIds,
        'dailySelectedWordIds': dailySelectedWordIds,
        'currentPointer': currentPointer,
        'lastCompletedDate': lastCompletedDate,
        'streakDays': streakDays,
        'isEnglishToTurkish': isEnglishToTurkish,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyQuizPlanModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> parseIdList(dynamic raw) {
      if (raw is List) return raw;
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded;
        } catch (_) {}
      }
      return [];
    }

    final parsedShuffledIds = parseIdList(json['shuffledWordIds'] ?? json['ShuffledWordIds']);
    final parsedCompletedIds = parseIdList(json['completedWordIds'] ?? json['CompletedWordIds']);
    final parsedDailySelectedIds = parseIdList(json['dailySelectedWordIds'] ?? json['DailySelectedWordIds']);

    final rawCreatedAt = json['createdAt'] ?? json['CreatedAt'];
    DateTime createdAtVal = DateTime.now();
    if (rawCreatedAt != null) {
      createdAtVal = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    final rawId = json['id'] ?? json['Id'];

    final rawPlanType = json['planType'] ?? json['PlanType'];
    final planType = (rawPlanType == 1 || rawPlanType == 'OpenBuffet' || rawPlanType == 'openBuffet')
        ? PlanType.openBuffet
        : PlanType.sequential;

    final titleVal = (json['title'] ?? json['Title'] ?? '').toString();
    final listNameVal = (json['listName'] ?? json['ListName'] ?? 'Tümü').toString();

    return DailyQuizPlanModel(
      id: rawId?.toString() ?? '',
      title: titleVal.isNotEmpty ? titleVal : '$listNameVal ${planType == PlanType.openBuffet ? 'Açık Büfe' : 'Sıralı Plan'}',
      listName: listNameVal,
      planType: planType,
      dailyCount: (json['dailyCount'] ?? json['DailyCount'] as int?) ?? 10,
      shuffledWordIds: parsedShuffledIds,
      completedWordIds: parsedCompletedIds,
      dailySelectedWordIds: parsedDailySelectedIds,
      currentPointer: (json['currentPointer'] ?? json['CurrentPointer'] as int?) ?? 0,
      lastCompletedDate: (json['lastCompletedDate'] ?? json['LastCompletedDate'])?.toString(),
      streakDays: (json['streakDays'] ?? json['StreakDays'] as int?) ?? 0,
      isEnglishToTurkish: (json['isEnglishToTurkish'] ?? json['IsEnglishToTurkish'] as bool?) ?? true,
      isActive: (json['isActive'] ?? json['IsActive'] as bool?) ?? true,
      createdAt: createdAtVal,
    );
  }
}
