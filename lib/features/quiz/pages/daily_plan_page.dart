import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/no_internet_dialog.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../controllers/quiz_controller.dart';
import '../models/daily_quiz_plan_model.dart';
import '../models/quiz_history_model.dart';
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
  bool _showHistory = false;
  bool _isCreatingNewPlan = false;

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
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      }
    });
  }

  bool _canPopDailyPlan(QuizState quizState) {
    if (quizState.isDailyQuiz &&
        (quizState.questions.isNotEmpty || quizState.isQuizCompleted)) {
      return false;
    }
    return !_showHistory && !_isCreatingNewPlan;
  }

  void _handleDailyPlanBack(QuizState quizState, QuizController quizNotifier) {
    if (quizState.isDailyQuiz &&
        (quizState.questions.isNotEmpty || quizState.isQuizCompleted)) {
      quizNotifier.resetToSetup();
      return;
    }
    if (_showHistory) {
      setState(() => _showHistory = false);
      return;
    }
    if (_isCreatingNewPlan) {
      setState(() => _isCreatingNewPlan = false);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    // Quiz result screen
    if (quizState.isDailyQuiz && quizState.isQuizCompleted) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          quizNotifier.resetToSetup();
        },
        child: QuizResultView(
          quizState: quizState,
          quizNotifier: quizNotifier,
          allWords: wordListState.words,
        ),
      );
    }

    // Active quiz screen
    if (quizState.isDailyQuiz && quizState.questions.isNotEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          quizNotifier.resetToSetup();
        },
        child: ActiveQuizView(
          quizState: quizState,
          quizNotifier: quizNotifier,
        ),
      );
    }

    final canPop = _canPopDailyPlan(quizState);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleDailyPlanBack(quizState, quizNotifier);
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SafeArea(
          child: ResponsiveContent(
            maxWidth: MediaQuery.of(context).size.width >= 720 ? 900 : 700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_showHistory || _isCreatingNewPlan) ...[
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                          tooltip: 'Geri Dön',
                          onPressed: () =>
                              _handleDailyPlanBack(quizState, quizNotifier),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _showHistory
                                  ? 'Geçmiş Günler'
                                  : (_isCreatingNewPlan
                                      ? 'Yeni Plan Oluştur'
                                      : 'Günlük Quiz Planı'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _showHistory
                                  ? 'Geçmiş günlerin sonuçlarını ve skorlarını inceleyin'
                                  : (_isCreatingNewPlan
                                      ? 'Kelime listenizden günlük çalışma planı oluşturun'
                                      : (quizState.dailyPlan != null
                                          ? 'Sıfır Tekrar Modu • ${quizState.dailyPlan!.listName}'
                                          : 'Henüz bir plan oluşturulmadı')),
                              textAlign: TextAlign.start,
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
                ),
                const SizedBox(height: 8),

                // Body
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
      ),
    );
  }

  // ==========================================
  // MAIN PLAN TAB
  // ==========================================
  Widget _buildDailyPlanTab(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final plan = quizState.dailyPlan;

    // Loading state
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

    // Error state
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
              message:
                  'İnternet bağlantınızı kontrol edip lütfen tekrar deneyin.',
              onRetry: () async {
                await ref.read(wordListControllerProvider.notifier).refresh();
                await quizNotifier.loadInitialData();
              },
            ),
          ),
        ),
      );
    }

    final showSetup = plan == null || _isCreatingNewPlan;

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
            if (showSetup)
              _buildPlanSetupView(
                context,
                wordListState,
                quizState,
                quizNotifier,
                isDark,
              )
            else
              _buildSequentialDashboard(
                context,
                plan,
                quizState,
                quizNotifier,
                wordListState.words,
                isDark,
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW: PLAN OLUŞTURMA FORMU
  // ==========================================
  Widget _buildPlanSetupView(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final listOptions = ['Tümü', ...wordListState.listNames];
    final targetWordsCount = _dailySelectedListName == 'Tümü'
        ? wordListState.words.length
        : wordListState.words
            .where((w) => w.listName == _dailySelectedListName)
            .length;
    final totalDays = targetWordsCount > 0
        ? (targetWordsCount / _dailyWordsPerDay).ceil()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isCreatingNewPlan && quizState.dailyPlan != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _isCreatingNewPlan = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Mevcut Plana Dön'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.turquoise,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 1. Hedef Liste
        Text(
          'HEDEF KELİME LİSTESİ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                  setState(() => _dailySelectedListName = name);
                }
              },
              selectedColor: AppColors.turquoise.withValues(alpha: 0.2),
              checkmarkColor: AppColors.turquoise,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.turquoise
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.turquoise
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // 2. Günlük Kelime Sayısı
        Text(
          'GÜNLÜK KELİME SAYISI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [5, 10, 20, 50].map((count) {
            final isSelected = _dailyWordsPerDay == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _dailyWordsPerDay = count);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.turquoise.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurface : Colors.white),
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
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
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

        // 3. Soru Yönü
        Text(
          'SORU YÖNÜ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dailyEnToTr = true);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _dailyEnToTr
                        ? AppColors.turquoise.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkSurface : Colors.white),
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
                        fontWeight:
                            _dailyEnToTr ? FontWeight.w700 : FontWeight.w600,
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
                  setState(() => _dailyEnToTr = false);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_dailyEnToTr
                        ? AppColors.pink.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkSurface : Colors.white),
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
                        fontWeight:
                            !_dailyEnToTr ? FontWeight.w700 : FontWeight.w600,
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

        // Plan Özeti
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.turquoise,
                size: 28,
              ),
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
        const SizedBox(height: 24),

        // Planı Başlat Butonu
        CustomButton(
          text: _isCreatingNewPlan ? 'Planı Yeniden Oluştur' : 'Günlük Planı Başlat',
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

            final success = await quizNotifier.createPlan(
              listName: _dailySelectedListName,
              dailyCount: _dailyWordsPerDay,
              englishToTurkish: _dailyEnToTr,
            );

            if (success) {
              if (mounted) {
                setState(() => _isCreatingNewPlan = false);
              }
            } else if (context.mounted) {
              final err = ref.read(quizControllerProvider).errorMessage ??
                  wordListState.errorMessage;
              if (err != null && DioErrorHandler.isNetworkError(err)) {
                NoInternetDialog.show(
                  context,
                  onRetry: () async {
                    final ok = await quizNotifier.createPlan(
                      listName: _dailySelectedListName,
                      dailyCount: _dailyWordsPerDay,
                      englishToTurkish: _dailyEnToTr,
                    );
                    if (!ok) throw Exception('Retry failed');
                  },
                );
              } else {
                _showWarningSnackBar(context,
                    'Plan oluşturulamadı. Lütfen kelime listenizi kontrol edin.');
              }
            }
          },
        ),
      ],
    );
  }

  // ==========================================
  // VIEW: SEQUENTIAL DASHBOARD
  // ==========================================
  Widget _buildSequentialDashboard(
    BuildContext context,
    DailyQuizPlanModel plan,
    QuizState quizState,
    QuizController quizNotifier,
    List<WordModel> allWords,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActivePlanCard(context, plan, isDark),
        const SizedBox(height: 20),
        _buildDailyActionCard(
          context,
          plan,
          quizState,
          quizNotifier,
          allWords,
          isDark,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.error),
            label: const Text(
              'Planı Sil',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => _confirmDeletePlan(context, quizNotifier),
          ),
        ),
      ],
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
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                            '${plan.listName} Listesi',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      Icon(Icons.history_rounded,
                          size: 14, color: Colors.white),
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
    final todayDay = quizState.dailyPlanDays
        .where((d) =>
            d.completedAt.year == now.year &&
            d.completedAt.month == now.month &&
            d.completedAt.day == now.day)
        .firstOrNull ?? quizState.dailyPlanDays.firstOrNull;

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
        : quizState.historyList
            .where((h) =>
                h.date.year == now.year &&
                h.date.month == now.month &&
                h.date.day == now.day)
            .firstOrNull;

    final isCompleted = quizState.isDailyQuizCompletedToday;

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
                        setState(() {
                          _showHistory = true;
                        });
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

  // ==========================================
  // HELPERS & DIALOGS
  // ==========================================
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

  Future<void> _confirmDeletePlan(
    BuildContext context,
    QuizController quizNotifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan Silinsin mi?'),
        content: const Text(
          'Bu çalışma planı ve planınıza ait tüm geçmiş kalıcı olarak silinecektir. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await quizNotifier.deleteDailyPlan();
      if (mounted) {
        setState(() {
          _showHistory = false;
          _isCreatingNewPlan = false;
        });
      }
      if (!success && context.mounted) {
        _showWarningSnackBar(context, 'Plan silinemedi.');
      }
    }
  }
}
