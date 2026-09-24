import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../quiz/controllers/quiz_controller.dart';
import '../../../quiz/models/quiz_history_model.dart';
import '../../../words/models/word_model.dart';
import '../../controllers/plan_controller.dart';
import '../../models/daily_quiz_plan_model.dart';
import '../../../quiz/pages/quiz_history_page.dart';

class DailyPlanActionCards extends StatelessWidget {
  final DailyQuizPlanModel plan;
  final PlanState planState;
  final PlanController planNotifier;
  final QuizController quizNotifier;
  final List<WordModel> allWords;
  final bool isDark;

  const DailyPlanActionCards({
    super.key,
    required this.plan,
    required this.planState,
    required this.planNotifier,
    required this.quizNotifier,
    required this.allWords,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDay = planState.dailyPlanDays
        .where((d) =>
            d.completedAt.year == now.year &&
            d.completedAt.month == now.month &&
            d.completedAt.day == now.day)
        .firstOrNull ?? planState.dailyPlanDays.firstOrNull;

    final todayHistory = todayDay != null
        ? QuizHistoryModel(
            id: todayDay.id.toString(),
            date: todayDay.completedAt,
            title: '${todayDay.dayNumber}. Gün',
            score: todayDay.score,
            maxScore: todayDay.maxScore,
            totalQuestions: todayDay.totalQuestions,
            correctCount: todayDay.correctCount,
            wrongCount: todayDay.wrongCount,
            isDailyQuiz: true,
            results: todayDay.results,
          )
        : null;

    final isCompleted = planState.isDailyQuizCompletedToday;

    final studyWords = isCompleted
        ? (todayHistory != null && todayHistory.results.isNotEmpty
            ? todayHistory.results.map((r) => r.word).toList()
            : allWords
                .where((w) => plan.shuffledWordIds
                    .skip(max(0, plan.currentPointer - plan.dailyCount))
                    .take(plan.dailyCount)
                    .contains(w.id))
                .toList())
        : allWords
            .where((w) => plan.shuffledWordIds
                .skip(plan.currentPointer)
                .take(plan.nextBatchCount)
                .contains(w.id))
            .toList();

    final effectiveHistory = todayHistory ??
        (isCompleted && studyWords.isNotEmpty
            ? QuizHistoryModel(
                id: 'today_completed',
                date: now,
                title: '${plan.currentDay}. Gün',
                score: studyWords.length * 10,
                maxScore: studyWords.length * 10,
                totalQuestions: studyWords.length,
                correctCount: studyWords.length,
                wrongCount: 0,
                isDailyQuiz: true,
                results: studyWords
                    .map((w) => QuizQuestionResult(
                          word: w,
                          questionText: plan.isEnglishToTurkish ? w.en : w.tr,
                          correctAnswer: plan.isEnglishToTurkish ? w.tr : w.en,
                          selectedAnswer: plan.isEnglishToTurkish ? w.tr : w.en,
                          isCorrect: true,
                        ))
                    .toList(),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 🔵 Quiz Card
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (isCompleted) {
                      if (effectiveHistory != null) {
                        showQuizHistoryDetailModal(
                            context, effectiveHistory, isDark, allWords);
                      } else {
                        context.push(AppRoutes.planHistory);
                      }
                    } else {
                      // PlanController'dan kelimeleri al, QuizController'a başlat
                      final words = planNotifier.getDailyQuizWords();
                      if (words != null && words.isNotEmpty) {
                        quizNotifier.startDailyQuiz(
                          words: words,
                          englishToTurkish: plan.isEnglishToTurkish,
                          title: 'Günün Quizi (Gün ${plan.currentDay}/${plan.totalDays})',
                        );
                      }
                    }
                  },
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
                            : const [Color(0xFF2563EB), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.insights_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCompleted ? 'Tamamlandı' : 'Bugün',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted
                                  ? 'Sonuçları Gör'
                                  : 'Quiz\'i Çöz',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCompleted
                                  ? (effectiveHistory != null
                                      ? '%${effectiveHistory.percentage} Doğru'
                                      : 'İncele')
                                  : '${plan.nextBatchCount} Yeni Soru',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 💖 Study Card
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (studyWords.isNotEmpty) {
                      context.push(AppRoutes.planStudy, extra: {
                        'sessionId':
                            'daily_plan_study_${plan.id}_${plan.currentDay}',
                        'words': studyWords,
                        'listTitle': isCompleted
                            ? 'Günün Kelimeleri (Tekrar)'
                            : 'Günün Kelimeleri - Gün ${plan.currentDay}',
                        'showSearchBar': false,
                        'isReadOnly': true,
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFFF43F5E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFD946EF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Çalışma',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kelimeleri Çalış',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCompleted
                                  ? '${studyWords.length} Kelimeyi Tekrar Et'
                                  : '${studyWords.length} Kelimeyi Öğren',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (isCompleted && todayHistory != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Color(0xFF34C759),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bugünün Skoru: ${todayHistory.correctCount}/${todayHistory.totalQuestions} Doğru (%${todayHistory.percentage})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
