import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/controllers/plan_controller.dart';
import '../../plan/models/daily_plan_day_model.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../controllers/quiz_controller.dart';
import '../models/quiz_history_model.dart';
import '../pages/quiz_history_page.dart';

/// Embedded history view for both QuizPage (general quiz history)
/// and DailyPlanPage (daily quiz history).
class QuizHistoryView extends ConsumerWidget {
  final bool isDailyQuiz;

  const QuizHistoryView({
    super.key,
    required this.isDailyQuiz,
  });

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Future<void> _confirmClearHistory(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Geçmişini Temizle'),
        content: Text(
          isDailyQuiz
              ? 'Tüm günlük plan test geçmişiniz silinecektir. Bu işlem geri alınamaz. Emin misiniz?'
              : 'Tüm test geçmişiniz ve detaylı soru sonuçlarınız silinecektir. Bu işlem geri alınamaz. Emin misiniz?',
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
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final planState = ref.watch(planControllerProvider);
    final planNotifier = ref.read(planControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    final historyList = quizState.historyList;

    return RefreshIndicator(
      color: AppColors.turquoise,
      onRefresh: () async {
        if (isDailyQuiz) {
          await planNotifier.loadPlanData();
        } else {
          await quizNotifier.loadHistory();
        }
      },
      child: isDailyQuiz
          ? _buildDailyPlanHistory(
              context: context,
              planState: planState,
              planNotifier: planNotifier,
              wordListState: wordListState,
              isDark: isDark,
            )
          : _buildGeneralQuizHistory(
              context: context,
              quizNotifier: quizNotifier,
              wordListState: wordListState,
              historyList: historyList,
              isDark: isDark,
            ),
    );
  }

  // ==========================================
  // GÜNLÜK PLAN GEÇMİŞİ (3'LÜ KARE GRID)
  // ==========================================
  Widget _buildDailyPlanHistory({
    required BuildContext context,
    required PlanState planState,
    required PlanController planNotifier,
    required WordListState wordListState,
    required bool isDark,
  }) {
    final plan = planState.dailyPlan;
    // Eğer plan yoksa veya silinmişse, boş durum göster
    if (plan == null) {
      return _buildEmptyState(isDark);
    }

    // Doğrudan DB'deki DailyPlanDayHistories tablosundan gelen günler
    // En son gün en başa gelsin (Yeniden eskiye)
    final sortedList = List<DailyPlanDayModel>.from(planState.dailyPlanDays)
      ..sort((a, b) => b.dayNumber != a.dayNumber
          ? b.dayNumber.compareTo(a.dayNumber)
          : b.completedAt.compareTo(a.completedAt));

    final totalDays = plan.totalDays > 0
        ? plan.totalDays
        : (sortedList.isNotEmpty ? sortedList.length : 1);
    final completedDays = sortedList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Üst İlerleme Özeti Kartı: "3/234 Gün Tamamlandı"
        Container(
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurface, const Color(0xFF1E293B)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.turquoise,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$completedDays/$totalDays Gün Tamamlandı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (sortedList.isNotEmpty)
                    InkWell(
                      onTap: () => _confirmClearHistory(context, onConfirm: () => planNotifier.clearDailyPlan()),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined,
                                size: 15, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              'Temizle',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalDays > 0 ? (completedDays / totalDays).clamp(0.0, 1.0) : 0,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                ),
              ),
            ],
          ),
        ),

        // 2. Bir Satırda 3 Kare Grid (En son gün en başta)
        Expanded(
          child: sortedList.isEmpty
              ? _buildEmptyState(isDark)
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final day = sortedList[index];
                    return _buildDailyGridCard(
                      context: context,
                      day: day,
                      isDark: isDark,
                      allWords: wordListState.words,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDailyGridCard({
    required BuildContext context,
    required DailyPlanDayModel day,
    required bool isDark,
    required List<WordModel> allWords,
  }) {
    final dayTitle = '${day.dayNumber}. Gün';
    final isSuccess = day.percentage >= 70;
    final isToday = _isToday(day.completedAt);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          final modalEntry = QuizHistoryModel(
            id: day.id.toString(),
            date: day.completedAt,
            title: dayTitle,
            score: day.score,
            maxScore: day.maxScore,
            totalQuestions: day.totalQuestions,
            correctCount: day.correctCount,
            wrongCount: day.wrongCount,
            isDailyQuiz: true,
            results: day.results,
          );
          showQuizHistoryDetailModal(context, modalEntry, isDark, allWords);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? AppColors.turquoise
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isToday ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Gün Başlığı ve Mini Yüzde Rozeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (isSuccess ? AppColors.success : AppColors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '%${day.percentage}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSuccess ? AppColors.success : AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Skor Alanı: "7/20 Doğru"
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.correctCount}/${day.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.turquoise,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Doğru',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),

              // 3. Tarih
              Text(
                '${day.completedAt.day} ${_getMonthAbbr(day.completedAt.month)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GENEL TEST GEÇMİŞİ (LİSTE ŞEKLİNDE)
  // ==========================================
  Widget _buildGeneralQuizHistory({
    required BuildContext context,
    required QuizController quizNotifier,
    required WordListState wordListState,
    required List<QuizHistoryModel> historyList,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (historyList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${historyList.length} Test Sonucu',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                InkWell(
                  onTap: () => _confirmClearHistory(context, onConfirm: () => quizNotifier.clearGeneralHistory()),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined,
                            size: 16, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'Temizle',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: historyList.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: historyList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = historyList[index];
                    return _buildCompactHistoryRow(
                      context: context,
                      entry: entry,
                      isDark: isDark,
                      allWords: wordListState.words,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF2F2F7),
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      size: 38,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isDailyQuiz
                        ? 'Henüz Günlük Test Çözülmedi'
                        : 'Henüz Çözülmüş Test Yok',
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
                        ? 'Günlük quiz planınızı çözdükçe tüm günlük sonuçlarınız ve skorlarınız burada listelenecektir.'
                        : 'Kelime testlerini tamamladıkça tüm sonuçlarınız ve analizleriniz burada listelenecektir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          showQuizHistoryDetailModal(context, entry, isDark, allWords);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isSuccess ? AppColors.success : AppColors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '%${entry.percentage}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSuccess ? AppColors.success : AppColors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.correctCount} / ${entry.totalQuestions} Doğru',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.turquoise,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.wrongCount} Yanlış',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
