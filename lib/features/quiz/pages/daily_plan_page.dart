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
  int _activeTabIndex = 0; // 0: Günlük Plan, 1: Geçmiş Günler / Sonuçlar

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
          maxWidth: 780,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Title + Subtitle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günlük Quiz Planı',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sıfır tekrar ile her gün yeni kelimeler',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Top Segmented Switcher (2 Tabs: Günlük Plan & Geçmiş Günler)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Günlük Plan',
                        icon: Icons.bolt_rounded,
                        isSelected: _activeTabIndex == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Geçmiş Günler',
                        icon: Icons.history_rounded,
                        isSelected: _activeTabIndex == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Tab Body
              Expanded(
                child: _activeTabIndex == 0
                    ? _buildDailyPlanTab(
                        context,
                        wordListState,
                        quizState,
                        quizNotifier,
                        isDark,
                      )
                    : const QuizHistoryView(isDailyQuiz: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.turquoise
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan.streakDays} Günlük Seri',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        plan.listName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%${plan.progressPercentage}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: plan.progressRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.currentPointer} / ${plan.totalWords} Kelime Tamamlandı',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Kalan: ${plan.remainingWords} Kelime',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
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

    if (plan.isPlanFinished) {
      final allPlanWords = allWords
          .where((w) => plan.shuffledWordIds.contains(w.id))
          .toList();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.emoji_events_rounded,
                  size: 52, color: AppColors.success),
            ),
            const SizedBox(height: 12),
            Text(
              'Tebrikler! Planı Tamamladınız!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Seçilen listedeki tüm kelimeleri sıfır tekrar ile başarıyla bitirdiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            if (allPlanWords.isNotEmpty) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 20),
                label: Text(
                  'Tüm Plan Kelimelerini Çalış (${allPlanWords.length})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudySessionPage(
                        words: allPlanWords,
                        listTitle: '${plan.listName} - Tüm Kelimeler',
                        showSearchBar: false,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            CustomButton(
              text: 'Yeni Plan Başlat',
              prefixIcon: Icons.refresh_rounded,
              variant: ButtonVariant.primary,
              onPressed: () => _confirmResetPlan(context, quizNotifier),
            ),
          ],
        ),
      );
    }

    if (quizState.isDailyQuizCompletedToday) {
      // Find today's completed words
      final completedWords = todayHistory != null && todayHistory.results.isNotEmpty
          ? todayHistory.results.map((r) => r.word).toList()
          : allWords
              .where((w) => plan.shuffledWordIds
                  .skip(max(0, plan.currentPointer - plan.dailyCount))
                  .take(plan.dailyCount)
                  .contains(w.id))
              .toList();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 32, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugünün Testi Tamamlandı!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Harika gidiyorsun! Sıradaki ${min(plan.dailyCount, plan.remainingWords)} kelimelik test yarın seni bekliyor olacak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            if (todayHistory != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.turquoise.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bugünün Skoru: ${todayHistory.correctCount} / ${todayHistory.totalQuestions} Doğru • %${todayHistory.percentage}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Button 1: Günün Kelimelerini Çalış / Tekrar Et (Green)
            if (completedWords.isNotEmpty) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 20),
                label: Text(
                  'Günün Kelimelerini Çalış (${completedWords.length} Kelime)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudySessionPage(
                        words: completedWords,
                        listTitle: 'Günün Kelimeleri (Tekrar)',
                        showSearchBar: false,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // Button 2: Bugünün Sonucunu İncele (if history exists)
            if (todayHistory != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white : AppColors.lightTextPrimary,
                  side: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.insights_rounded,
                    size: 18, color: AppColors.turquoise),
                label: const Text(
                  'Bugünün Sonucunu İncele',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showQuizHistoryDetailModal(
                      context, todayHistory, isDark, allWords);
                },
              ),
            ],
          ],
        ),
      );
    }

    // Ready for Today's Quiz Card
    final todayWordIds = plan.shuffledWordIds
        .skip(plan.currentPointer)
        .take(plan.nextBatchCount)
        .toSet();
    final todayWords = allWords
        .where((w) => todayWordIds.contains(w.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.turquoise.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    size: 24, color: AppColors.turquoise),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günün Testi Hazır!',
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
                      '${plan.nextBatchCount} yeni kelime seni bekliyor. Önce çalışabilir veya direkt teste başlayabilirsin.',
                      style: TextStyle(
                        fontSize: 12.5,
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
          const SizedBox(height: 18),

          // Button 1: Günün Kelimelerini Çalış (Green)
          if (todayWords.isNotEmpty) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF34C759),
                side: const BorderSide(color: Color(0xFF34C759), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.auto_stories_rounded, size: 20),
              label: Text(
                'Günün Kelimelerini Çalış (${todayWords.length} Kelime)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudySessionPage(
                      words: todayWords,
                      listTitle: 'Günün Kelimeleri - Gün ${plan.currentDay}',
                      showSearchBar: false,
                      isReadOnly: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Button 2: Günün Testini Başlat (Turquoise)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              quizNotifier.startDailyQuizForToday();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Günün Testini Başlat (${plan.nextBatchCount} Soru)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
