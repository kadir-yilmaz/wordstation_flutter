import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/no_internet_dialog.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../../words/pages/study_session_page.dart';
import '../controllers/quiz_controller.dart';
import '../models/daily_quiz_plan_model.dart';
import '../pages/quiz_history_page.dart';
import '../widgets/active_quiz_view.dart';
import '../widgets/quiz_history_view.dart';
import '../widgets/quiz_result_view.dart';

class DailyPlanPage extends ConsumerStatefulWidget {
  const DailyPlanPage({super.key});

  @override
  ConsumerState<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends ConsumerState<DailyPlanPage> {
  bool _showHistory = false; // false: Günlük Plan, true: Geçmiş Günler

  // Plan creation setup state
  String _dailySelectedListName = 'Tümü';
  int _dailyWordsPerDay = 10;
  bool _dailyEnToTr = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(quizControllerProvider.notifier).loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    // If an active daily quiz is in progress, show active quiz view
    if (quizState.isDailyQuiz && quizState.questions.isNotEmpty) {
      return ActiveQuizView(
        quizState: quizState,
        quizNotifier: quizNotifier,
      );
    }

    // If daily quiz was completed, show result view
    if (quizState.isDailyQuiz && quizState.isQuizCompleted) {
      return QuizResultView(
        quizState: quizState,
        quizNotifier: quizNotifier,
        allWords: wordListState.words,
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 620,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Title + Navigation)
              Row(
                children: [
                  if (_showHistory) ...[
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => setState(() => _showHistory = false),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: _showHistory
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          _showHistory ? 'Geçmiş Quizler' : 'Günlük Quiz Planı',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _showHistory
                              ? 'Geçmiş günlerin sonuçlarını ve skorlarını inceleyin'
                              : 'Sıfır tekrar ile her gün düzenli kelime çalışması',
                          textAlign: _showHistory ? TextAlign.start : TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Body
              Expanded(
                child: _showHistory
                    ? const QuizHistoryView(isDailyQuiz: true)
                    : _buildDailyPlanTab(
                        context,
                        wordListState,
                        quizState,
                        quizNotifier,
                        isDark,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: GÜNLÜK PLAN (AKTİF PLAN VEYA PLAN OLUŞTURMA)
  // ==========================================
  Widget _buildDailyPlanTab(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final plan = quizState.dailyPlan;
    final listOptions = ['Tümü', ...wordListState.listNames];
    final targetWordsCount = _dailySelectedListName == 'Tümü'
        ? wordListState.words.length
        : wordListState.words
            .where((w) => w.listName == _dailySelectedListName)
            .length;
    final totalDays = targetWordsCount > 0
        ? (targetWordsCount / _dailyWordsPerDay).ceil()
        : 0;

    if (!quizState.isPlanLoaded && plan == null) {
      return Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.turquoise,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Plan yükleniyor...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if ((quizState.hasPlanLoadError && plan == null) ||
        (wordListState.errorMessage != null && wordListState.words.isEmpty)) {
      return RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: () async {
          await ref.read(wordListControllerProvider.notifier).refresh();
          await quizNotifier.loadInitialData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: NetworkErrorView(
              title: 'Günlük Quiz Yüklenemedi',
              message: 'İnternet bağlantınızı kontrol edip lütfen tekrar deneyin.',
              onRetry: () async {
                await ref.read(wordListControllerProvider.notifier).refresh();
                await quizNotifier.loadInitialData();
              },
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.turquoise,
      onRefresh: () async {
        await ref.read(wordListControllerProvider.notifier).refresh();
        await quizNotifier.loadInitialData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (plan == null) ...[
              // Intro Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sıfır Tekrar Prensibi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelimeleriniz bir kez rastgele karıştırılır. Her gün belirlenen sayıda yeni kelime çözülür.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 1. Target List Selector
              Text(
                'HEDEF LİSTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: listOptions.map((name) {
                  final isSelected = _dailySelectedListName == name;
                  return FilterChip(
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _dailySelectedListName = name;
                        });
                      }
                    },
                    selectedColor: AppColors.turquoise.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.turquoise,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.turquoise
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.turquoise
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // 2. Daily Word Count Chips
              Text(
                'GÜNLÜK KELİME SAYISI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [5, 10, 15, 20].map((count) {
                  final isSelected = _dailyWordsPerDay == count;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _dailyWordsPerDay = count;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.turquoise.withValues(alpha: 0.15)
                                : (isDark
                                    ? AppColors.darkSurface
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.turquoise
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                              width: isSelected ? 2 : 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.turquoise
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // 3. Direction Selector
              Text(
                'SORU YÖNÜ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _dailyEnToTr = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _dailyEnToTr
                              ? AppColors.turquoise.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _dailyEnToTr
                                ? AppColors.turquoise
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: _dailyEnToTr ? 2 : 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'İngilizce ➔ Türkçe',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _dailyEnToTr
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _dailyEnToTr
                                  ? AppColors.turquoise
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _dailyEnToTr = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_dailyEnToTr
                              ? AppColors.pink.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_dailyEnToTr
                                ? AppColors.pink
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: !_dailyEnToTr ? 2 : 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Türkçe ➔ İngilizce',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_dailyEnToTr
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: !_dailyEnToTr
                                  ? AppColors.pink
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Plan Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.turquoise, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '$targetWordsCount kelime • Günde $_dailyWordsPerDay kelime\nPlan $totalDays günde tamamlanacak.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Start Plan Button
              CustomButton(
                text: 'Günlük Planı Başlat',
                prefixIcon: Icons.rocket_launch_rounded,
                variant: ButtonVariant.primary,
                onPressed: () async {
                  if (targetWordsCount < 4) {
                    final err = wordListState.errorMessage;
                    if (err != null && DioErrorHandler.isNetworkError(err)) {
                      NoInternetDialog.show(
                        context,
                        onRetry: () async {
                          await ref
                              .read(wordListControllerProvider.notifier)
                              .refresh();
                          await quizNotifier.loadInitialData();
                        },
                      );
                    } else {
                      _showWarningSnackBar(context,
                          'Plan başlatmak için seçilen listede en az 4 kelime olmalıdır.');
                    }
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  final success = await quizNotifier.startOrResetDailyPlan(
                    listName: _dailySelectedListName,
                    dailyCount: _dailyWordsPerDay,
                    englishToTurkish: _dailyEnToTr,
                  );
                  if (!success && context.mounted) {
                    final err = ref.read(quizControllerProvider).errorMessage ??
                        wordListState.errorMessage;
                    if (err != null && DioErrorHandler.isNetworkError(err)) {
                      NoInternetDialog.show(
                        context,
                        onRetry: () async {
                          final ok = await quizNotifier.startOrResetDailyPlan(
                            listName: _dailySelectedListName,
                            dailyCount: _dailyWordsPerDay,
                            englishToTurkish: _dailyEnToTr,
                          );
                          if (!ok) throw Exception('Retry failed');
                        },
                      );
                    } else {
                      _showWarningSnackBar(context,
                          'Plan başlatılamadı. Lütfen kelime listenizi kontrol edin.');
                    }
                  }
                },
              ),
            ] else ...[
              // Active Plan UI
              _buildActivePlanCard(context, plan, isDark),
              const SizedBox(height: 20),
              _buildDailyActionCard(
                context,
                plan,
                quizState,
                quizNotifier,
                wordListState.words,
                isDark,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.darkTextMuted),
                  label: Text(
                    'Planı Sıfırla / Değiştir',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _confirmResetPlan(context, quizNotifier),
                ),
              ),
            ],

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanCard(
    BuildContext context,
    DailyQuizPlanModel plan,
    bool isDark,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _showHistory = true);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.streakDays} Günlük Seri',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            plan.listName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '%${plan.progressPercentage}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: plan.progressRatio,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${plan.currentPointer} / ${plan.totalWords} Kelime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Geçmiş Günleri İncele',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.history_rounded, size: 14, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyActionCard(
    BuildContext context,
    DailyQuizPlanModel plan,
    QuizState quizState,
    QuizController quizNotifier,
    List<WordModel> allWords,
    bool isDark,
  ) {
    final now = DateTime.now();
    final todayHistory = quizState.historyList
        .where((h) =>
            h.isDailyQuiz &&
            h.date.year == now.year &&
            h.date.month == now.month &&
            h.date.day == now.day)
        .firstOrNull;

    final isCompleted = quizState.isDailyQuizCompletedToday;

    // Words to study for today (either today's upcoming batch or completed batch)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Yan Yana 2 Kutu (Mavi: Quiz / Sonuç - Neon Pembe: Çalış)
        Row(
          children: [
            // 🔵 1. SOL KUTU: MAVİ KART (Quiz Çöz / Sonuçları Gör)
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (isCompleted) {
                      if (todayHistory != null) {
                        showQuizHistoryDetailModal(
                            context, todayHistory, isDark, allWords);
                      }
                    } else {
                      quizNotifier.startDailyQuizForToday();
                    }
                  },
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)] // Derin Mavi
                            : const [Color(0xFF2563EB), Color(0xFF06B6D4)], // Canlı Mavi / Cyan
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
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
                                  ? (todayHistory != null
                                      ? '%${todayHistory.percentage} Doğru'
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

            // 💖 2. SAĞ KUTU: NEON PEMBE KART (Kelimeleri Çalış)
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (studyWords.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudySessionPage(
                            words: studyWords,
                            listTitle: isCompleted
                                ? 'Günün Kelimeleri (Tekrar)'
                                : 'Günün Kelimeleri - Gün ${plan.currentDay}',
                            showSearchBar: false,
                            isReadOnly: true,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFFF43F5E)], // Neon Pembe / Fuşya
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD946EF).withValues(alpha: 0.35),
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

        // Tamamlandıysa ufak tebrik rozeti
        if (isCompleted && todayHistory != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF34C759)),
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

  void _showWarningSnackBar(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _confirmResetPlan(
      BuildContext context, QuizController quizNotifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planı Sıfırla'),
        content: const Text(
          'Mevcut günlük test ilerlemeniz sıfırlanacaktır ve yeni bir plan başlatabileceksiniz. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await quizNotifier.deleteDailyPlan();
      if (!success && context.mounted) {
        final err = ref.read(quizControllerProvider).errorMessage;
        if (err != null && DioErrorHandler.isNetworkError(err)) {
          NoInternetDialog.show(
            context,
            onRetry: () async {
              final ok = await quizNotifier.deleteDailyPlan();
              if (!ok) throw Exception('Retry failed');
            },
          );
        } else {
          _showWarningSnackBar(context, 'Plan sıfırlanamadı.');
        }
      }
    }
  }
}
