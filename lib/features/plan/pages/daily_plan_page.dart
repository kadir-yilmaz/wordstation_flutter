import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../quiz/controllers/quiz_controller.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../quiz/widgets/active_quiz_view.dart';
import '../../quiz/widgets/quiz_result_view.dart';
import '../controllers/plan_controller.dart';
import '../widgets/daily_plan/daily_plan_dashboard.dart';
import '../widgets/daily_plan/daily_plan_setup_view.dart';

class DailyPlanPage extends ConsumerStatefulWidget {
  const DailyPlanPage({super.key});

  @override
  ConsumerState<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends ConsumerState<DailyPlanPage> {
  bool _isCreatingNewPlan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(planControllerProvider.notifier).loadPlanData();
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      }
    });
  }

  bool _canPopDailyPlan(QuizState quizState) {
    if (quizState.isDailyQuiz &&
        (quizState.questions.isNotEmpty || quizState.isQuizCompleted)) {
      return false;
    }
    return !_isCreatingNewPlan;
  }

  void _handleDailyPlanBack(QuizState quizState, QuizController quizNotifier) {
    if (quizState.isDailyQuiz &&
        (quizState.questions.isNotEmpty || quizState.isQuizCompleted)) {
      quizNotifier.resetToSetup();
      return;
    }
    if (_isCreatingNewPlan) {
      setState(() => _isCreatingNewPlan = false);
      return;
    }
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

  Future<void> _confirmDeletePlan(
    BuildContext context,
    PlanController planNotifier,
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
      final success = await planNotifier.deleteDailyPlan();
      if (mounted) {
        setState(() {
          _isCreatingNewPlan = false;
        });
      }
      if (!success && context.mounted) {
        _showWarningSnackBar(context, 'Plan silinemedi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final planState = ref.watch(planControllerProvider);
    final planNotifier = ref.read(planControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    // Quiz result screen — günlük quiz tamamlandığında plan ilerlemesini güncelle
    if (quizState.isDailyQuiz && quizState.isQuizCompleted) {
      // Ensure plan progress is saved when quiz completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && quizState.isQuizCompleted && quizState.isDailyQuiz) {
          planNotifier.onDailyQuizCompleted(
            totalQuestions: quizState.totalQuestions,
            correctCount: quizState.correctCount,
            wrongCount: quizState.wrongCount,
            score: quizState.score,
            maxScore: quizState.maxScore,
            results: quizState.results,
          );
        }
      });

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
                      if (_isCreatingNewPlan) ...[
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
                              _isCreatingNewPlan
                                  ? 'Yeni Plan Oluştur'
                                  : 'Günlük Quiz Planı',
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
                              _isCreatingNewPlan
                                  ? 'Kelime listenizden günlük çalışma planı oluşturun'
                                  : (planState.dailyPlan != null
                                      ? 'Sıfır Tekrar Modu • ${planState.dailyPlan!.listName}'
                                      : 'Henüz bir plan oluşturulmadı'),
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
                      if (!_isCreatingNewPlan && planState.dailyPlan != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 24,
                            color: AppColors.error,
                          ),
                          tooltip: 'Planı Sil',
                          onPressed: () => _confirmDeletePlan(context, planNotifier),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Body
                Expanded(
                  child: _buildBody(
                    context,
                    wordListState,
                    planState,
                    planNotifier,
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

  Widget _buildBody(
    BuildContext context,
    WordListState wordListState,
    PlanState planState,
    PlanController planNotifier,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final plan = planState.dailyPlan;

    // Loading state
    if (!planState.isPlanLoaded && plan == null) {
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
    if ((planState.hasPlanLoadError && plan == null) ||
        (wordListState.errorMessage != null && wordListState.words.isEmpty)) {
      return RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: () async {
          await ref.read(wordListControllerProvider.notifier).refresh();
          await planNotifier.loadPlanData();
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
                await planNotifier.loadPlanData();
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
        await planNotifier.loadPlanData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSetup)
              DailyPlanSetupView(
                wordListState: wordListState,
                planState: planState,
                planNotifier: planNotifier,
                isDark: isDark,
                isCreatingNewPlan: _isCreatingNewPlan,
                onCancelNewPlan: () =>
                    setState(() => _isCreatingNewPlan = false),
                onPlanCreated: () {
                  if (mounted) {
                    setState(() => _isCreatingNewPlan = false);
                  }
                },
              )
            else
              DailyPlanDashboard(
                plan: plan,
                planState: planState,
                planNotifier: planNotifier,
                quizNotifier: quizNotifier,
                allWords: wordListState.words,
                isDark: isDark,
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
