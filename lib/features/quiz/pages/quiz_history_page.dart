import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../../words/pages/study_session_page.dart';
import '../controllers/quiz_controller.dart';
import '../models/quiz_history_model.dart';

class QuizHistoryPage extends ConsumerWidget {
  final bool isDailyQuiz;
  final String title;

  const QuizHistoryPage({
    super.key,
    required this.isDailyQuiz,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    final historyList = quizState.historyList
        .where((h) => h.isDailyQuiz == isDailyQuiz)
        .toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (historyList.isNotEmpty && !isDailyQuiz)
            TextButton(
              onPressed: () => _confirmClearHistory(context, quizNotifier),
              child: const Text(
                'Temizle',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: () async {
            await quizNotifier.loadInitialData();
          },
          child: historyList.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 56,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz Çözülmüş Test Yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isDailyQuiz
                                    ? 'Günlük quizleri çözdükçe tüm sonuçlarınız ve tekrar çalışmalarınız burada listelenecektir.'
                                    : 'Genel quizleri çözdükçe tüm test sonuçlarınız burada listelenecektir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: historyList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final entry = historyList[idx];
                    return _buildCompactHistoryRow(
                      context: context,
                      entry: entry,
                      isDark: isDark,
                      allWords: wordListState.words,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCompactHistoryRow({
    required BuildContext context,
    required QuizHistoryModel entry,
    required bool isDark,
    required List<WordModel> allWords,
  }) {
    final dateStr =
        '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year} • ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';
    final isSuccess = entry.percentage >= 70;
    final isToday = _isToday(entry.date);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showQuizHistoryDetailModal(context, entry, isDark, allWords);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday && isDailyQuiz
                ? AppColors.turquoise
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isToday && isDailyQuiz ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            // Slim Percentage Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isSuccess ? AppColors.success : AppColors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '%${entry.percentage}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSuccess ? AppColors.success : AppColors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (isToday && isDailyQuiz) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.turquoise,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'BUGÜN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Score & Correct/Wrong count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.correctCount} / ${entry.totalQuestions} Doğru',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.turquoise,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${entry.wrongCount} Yanlış',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),

            // Study Flashcards Button
            if (entry.results.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: Color(0xFF34C759),
                ),
                tooltip: 'Kelimeleri Çalış',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final words = entry.results.map((r) => r.word).toList();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudySessionPage(
                        words: words,
                        listTitle: entry.title,
                        showSearchBar: false,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF8E8E93),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _confirmClearHistory(BuildContext context, QuizController quizNotifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDailyQuiz ? 'Günlük Test Geçmişini Temizle' : 'Genel Quiz Geçmişini Temizle'),
        content: Text(
          isDailyQuiz
              ? 'Tüm günlük test geçmiş kayıtlarınız silinecektir. Emin misiniz?'
              : 'Tüm genel quiz geçmiş kayıtlarınız silinecektir. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (isDailyQuiz) {
        await quizNotifier.clearDailyHistory();
      } else {
        await quizNotifier.clearGeneralHistory();
      }
    }
  }
}

void showQuizHistoryDetailModal(
  BuildContext context,
  QuizHistoryModel entry,
  bool isDark,
  List<WordModel> allWords,
) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.correctCount} / ${entry.totalQuestions} Doğru • %${entry.percentage} Başarı',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.turquoise,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.results.isNotEmpty) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.auto_stories_rounded, size: 16),
                        label: const Text(
                          'Çalış',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          final words = entry.results.map((r) => r.word).toList();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudySessionPage(
                                words: words,
                                listTitle: entry.title,
                                showSearchBar: false,
                                isReadOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Flexible(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: entry.results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (c, qIdx) {
                    final item = entry.results[qIdx];
                    return _buildQuestionResultCard(
                      context,
                      item,
                      qIdx + 1,
                      isDark,
                      allWords,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionResultCard(
    BuildContext context,
    QuizQuestionResult item,
    int index,
    bool isDark,
    List<WordModel> allWords,
  ) {
    final statusColor = item.isCorrect ? AppColors.success : AppColors.error;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showWordDetailModal(
          context,
          word: item.word,
          allWords: allWords,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 16,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$index. ${item.word.en}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '(${item.word.tr})',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!item.isCorrect) ...[
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Cevabınız: '),
                          TextSpan(
                            text: item.selectedAnswer.isEmpty ? 'Boş' : item.selectedAnswer,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' • Doğru: '),
                          TextSpan(
                            text: item.correctAnswer,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }
