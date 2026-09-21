import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../widgets/buffet_word_picker_modal.dart';
import '../widgets/quiz_history_view.dart';
import '../widgets/quiz_result_view.dart';

class DailyPlanPage extends ConsumerStatefulWidget {
  const DailyPlanPage({super.key});

  @override
  ConsumerState<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends ConsumerState<DailyPlanPage> {
  bool _showHistory = false; // false: Günlük Plan, true: Geçmiş Günler
  bool _isCreatingNewPlan = false;

  // Plan creation setup state
  String _dailySelectedListName = 'Tümü';
  int _dailyWordsPerDay = 10;
  bool _dailyEnToTr = true;
  PlanType _dailyPlanType = PlanType.openBuffet;
  final TextEditingController _planTitleController = TextEditingController();

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
  void dispose() {
    _planTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final wordListState = ref.watch(wordListControllerProvider);

    // Completed quizzes still keep questions in state, so results must
    // be checked before the in-progress view.
    if (quizState.isDailyQuiz && quizState.isQuizCompleted) {
      return QuizResultView(
        quizState: quizState,
        quizNotifier: quizNotifier,
        allWords: wordListState.words,
      );
    }

    if (quizState.isDailyQuiz && quizState.questions.isNotEmpty) {
      return ActiveQuizView(
        quizState: quizState,
        quizNotifier: quizNotifier,
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
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
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
                              : 'Açık büfe veya sıralı planlarla her gün düzenli çalışma',
                          textAlign: _showHistory
                              ? TextAlign.start
                              : TextAlign.center,
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
              const SizedBox(height: 16),

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
                'Planlar yükleniyor...',
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
            // Plan Switcher Bar (Multiple Plans Carousel/Chip Row)
            if (quizState.allPlans.isNotEmpty) ...[
              _buildPlanSwitcherBar(quizState, quizNotifier, isDark),
              const SizedBox(height: 18),
            ],

            if (showSetup)
              _buildPlanSetupView(
                context,
                wordListState,
                quizState,
                quizNotifier,
                isDark,
              )
            else if (plan.isOpenBuffet)
              _buildOpenBuffetDashboard(
                context,
                plan,
                quizState,
                quizNotifier,
                wordListState.words,
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
  // PLAN SWITCHER BAR (YATAY PLAN LİSTESİ)
  // ==========================================
  Widget _buildPlanSwitcherBar(
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final activePlanId = quizState.dailyPlan?.id;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...quizState.allPlans.map((p) {
            final isSelected = !_isCreatingNewPlan && p.id == activePlanId;
            final isBuffet = p.isOpenBuffet;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_isCreatingNewPlan || p.id != activePlanId) {
                    setState(() => _isCreatingNewPlan = false);
                    quizNotifier.switchActivePlan(p.id);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isBuffet
                            ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                            : const Color(0xFF6366F1).withValues(alpha: 0.15))
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (isBuffet
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF6366F1))
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBuffet
                            ? Icons.restaurant_menu_rounded
                            : Icons.bolt_rounded,
                        size: 16,
                        color: isSelected
                            ? (isBuffet
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF6366F1))
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.displayTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                          Text(
                            isBuffet
                                ? '${p.buffetPoolRemainingCount} Kalan'
                                : '%${p.progressPercentage}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (isBuffet
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFF6366F1))
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // + Yeni Plan Butonu
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isCreatingNewPlan = true;
                _planTitleController.clear();
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isCreatingNewPlan
                    ? AppColors.turquoise.withValues(alpha: 0.15)
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isCreatingNewPlan
                      ? AppColors.turquoise
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  width: _isCreatingNewPlan ? 1.8 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: _isCreatingNewPlan
                        ? AppColors.turquoise
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Yeni Plan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _isCreatingNewPlan
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _isCreatingNewPlan
                          ? AppColors.turquoise
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

        // 1. Plan Türü Seçimi (Açık Büfe vs Sıralı)
        Text(
          'PLAN TÜRÜ',
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
            // Açık Büfe Kartı
            Expanded(
              child: _buildPlanTypeCard(
                type: PlanType.openBuffet,
                title: 'Açık Büfe',
                subtitle: 'Serbest seçim • Havuzdan düşmeli',
                icon: Icons.restaurant_menu_rounded,
                gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                isSelected: _dailyPlanType == PlanType.openBuffet,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dailyPlanType = PlanType.openBuffet);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Sıralı Kartı
            Expanded(
              child: _buildPlanTypeCard(
                type: PlanType.sequential,
                title: 'Sıfır Tekrar',
                subtitle: 'Sıralı tamamlama • Otomatik',
                icon: Icons.bolt_rounded,
                gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                isSelected: _dailyPlanType == PlanType.sequential,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dailyPlanType = PlanType.sequential);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Plan Türü Bilgilendirme Bannerı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _dailyPlanType == PlanType.openBuffet
                ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                : const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _dailyPlanType == PlanType.openBuffet
                  ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                  : const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: _dailyPlanType == PlanType.openBuffet
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF6366F1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dailyPlanType == PlanType.openBuffet
                      ? 'Açık Büfe Modu: Listedeki tüm kelimeler havuzdadır. Bugün çalışmak istediğiniz kelimeleri (örn: 50 adet) siz seçersiniz ve çalıştıkça havuzdan kalıcı olarak düşer.'
                      : 'Sıfır Tekrar Modu: Listeniz baştan sona tek seferlik karıştırılır. Her gün belirlediğiniz sayıda yeni kelime sırayla karşınıza gelir.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // 2. Plan Başlığı
        Text(
          'PLAN BAŞLIĞI (İSTEĞE BAĞLI)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _planTitleController,
          decoration: InputDecoration(
            hintText: _dailyPlanType == PlanType.openBuffet
                ? 'Örn: YDS 2500 Açık Büfe'
                : 'Örn: B2 Sıralı Kelime Planı',
            hintStyle: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            prefixIcon: const Icon(Icons.bookmark_outline_rounded, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.turquoise,
                width: 1.8,
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // 3. Hedef Liste
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
                  setState(() {
                    _dailySelectedListName = name;
                  });
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

        // 4. Günlük Kelime Sayısı / Hedefi
        Text(
          _dailyPlanType == PlanType.openBuffet
              ? 'GÜNLÜK HEDEF KELİME SAYISI'
              : 'GÜNLÜK KELİME SAYISI',
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

        // 5. Soru Yönü
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
              Icon(
                _dailyPlanType == PlanType.openBuffet
                    ? Icons.restaurant_menu_rounded
                    : Icons.calendar_month_rounded,
                color: _dailyPlanType == PlanType.openBuffet
                    ? const Color(0xFF0D9488)
                    : AppColors.turquoise,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _dailyPlanType == PlanType.openBuffet
                      ? '$targetWordsCount kelimelik havuz oluşturulacak.\nHer gün dilediğiniz kelimeleri seçip çözeceksiniz.'
                      : '$targetWordsCount kelime • Günde $_dailyWordsPerDay kelime\nPlan $totalDays günde tamamlanacak.',
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
          text: _isCreatingNewPlan
              ? 'Yeni Planı Oluştur'
              : 'Günlük Planı Başlat',
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
            final title = _planTitleController.text.trim();

            final success = await quizNotifier.createPlan(
              title: title.isNotEmpty ? title : null,
              listName: _dailySelectedListName,
              dailyCount: _dailyWordsPerDay,
              englishToTurkish: _dailyEnToTr,
              planType: _dailyPlanType,
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
                      title: title.isNotEmpty ? title : null,
                      listName: _dailySelectedListName,
                      dailyCount: _dailyWordsPerDay,
                      englishToTurkish: _dailyEnToTr,
                      planType: _dailyPlanType,
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

  Widget _buildPlanTypeCard({
    required PlanType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? gradient.first.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? gradient.first
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: gradient.first,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW: AÇIK BÜFE DASHBOARD
  // ==========================================
  Widget _buildOpenBuffetDashboard(
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

    final isCompletedToday = quizState.isDailyQuizCompletedToday;

    // Filter words belonging to this plan's list
    final targetListWords = (plan.listName == 'Tümü' || plan.listName == 'All')
        ? allWords
        : allWords.where((w) => w.listName == plan.listName).toList();

    // Words selected for today
    final selectedTodayWords = allWords
        .where((w) => plan.dailySelectedWordIds.contains(w.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. AÇIK BÜFE HAVUZ HERO KARTI
        _buildOpenBuffetHeroCard(
          context,
          plan,
          allWords,
          quizNotifier,
          isDark,
        ),
        const SizedBox(height: 20),

        // 2. BUGÜNÜN MENÜSÜ & KELİME SEÇİMİ
        Text(
          'BUGÜNÜN SEÇİMİ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),

        if (plan.dailySelectedWordIds.isEmpty) ...[
          // Kelime Henüz Seçilmedi Durumu
          Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.playlist_add_check_rounded,
                    size: 34,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bugün İçin Kelime Seçilmedi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Açık büfe havuzundaki ${plan.buffetPoolRemainingCount} kelime arasından bugün çalışmak ve quiz çözmek istediklerinizi seçin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Açık Büfeden Kelime Seç',
                  prefixIcon: Icons.restaurant_menu_rounded,
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    BuffetWordPickerModal.show(
                      context: context,
                      poolWords: targetListWords,
                      plan: plan,
                      onConfirm: (selectedIds) async {
                        await quizNotifier.selectBuffetWords(selectedIds);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          // Kelimeler Seçilmiş -> Özet ve Butonlar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0D9488),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${plan.dailySelectedWordIds.length} Kelime Seçildi',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        BuffetWordPickerModal.show(
                          context: context,
                          poolWords: targetListWords,
                          plan: plan,
                          onConfirm: (selectedIds) async {
                            await quizNotifier.selectBuffetWords(selectedIds);
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Değiştir'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (selectedTodayWords.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedTodayWords.take(8).map((w) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          w.en,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (selectedTodayWords.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${selectedTodayWords.length - 8} kelime daha...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2 KUTU: MAVİ (QUIZ) & PEMBE (ÇALIŞ)
          _buildBuffetActionButtons(
            context,
            plan,
            quizState,
            quizNotifier,
            selectedTodayWords,
            todayHistory,
            isCompletedToday,
            allWords,
            isDark,
          ),
        ],

        const SizedBox(height: 24),

        // Plan Yönetimi (Sıfırla / Sil)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.restart_alt_rounded,
                  size: 16, color: AppColors.darkTextMuted),
              label: Text(
                'Planı Sıfırla',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirmResetPlan(context, plan, quizNotifier),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
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
              onPressed: () => _confirmDeletePlan(context, plan, quizNotifier),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenBuffetHeroCard(
    BuildContext context,
    DailyQuizPlanModel plan,
    List<WordModel> allWords,
    QuizController quizNotifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.displayTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.listName} • Açık Büfe',
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
              // Seri Rozeti
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.streakDays} Gün',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3 Kolonlu Havuz İstatistikleri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Toplam Havuz',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${plan.totalWords}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Kalan Kelime',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${plan.buffetPoolRemainingCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFACC15), // Canlı Sarı/Amber Vurgusu
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Havuzdan Düşen',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${plan.completedWordsCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // İlerleme Çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: plan.progressRatio,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '%${plan.progressPercentage} tamamlandı',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              // Havuzdan Düşenleri İncele Butonu
              InkWell(
                onTap: () {
                  _showCompletedWordsModal(
                    context,
                    plan,
                    allWords,
                    quizNotifier,
                    isDark,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Havuzdan Düşenleri İncele (${plan.completedWordsCount})',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuffetActionButtons(
    BuildContext context,
    DailyQuizPlanModel plan,
    QuizState quizState,
    QuizController quizNotifier,
    List<WordModel> selectedTodayWords,
    QuizHistoryModel? todayHistory,
    bool isCompletedToday,
    List<WordModel> allWords,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 🔵 1. MAVİ KART: Quiz'i Çöz / Sonuçları Gör
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (isCompletedToday) {
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
                        colors: isCompletedToday
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
                                isCompletedToday
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
                                isCompletedToday ? 'Tamamlandı' : 'Bugün',
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
                              isCompletedToday
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
                              isCompletedToday
                                  ? (todayHistory != null
                                      ? '%${todayHistory.percentage} Doğru'
                                      : 'İncele')
                                  : '${selectedTodayWords.length} Soru',
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

            // 💖 2. NEON PEMBE KART: Kelimeleri Çalış
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (selectedTodayWords.isNotEmpty) {
                      context.push('/study', extra: {
                        'words': selectedTodayWords,
                        'listTitle':
                            '${plan.displayTitle} (${selectedTodayWords.length} Kelime)',
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
                                'Kartlar',
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
                              '${selectedTodayWords.length} Kelimeyi Öğren',
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

        if (isCompletedToday) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Harika! Bugünkü kelimeler tamamlandı ve açık büfe havuzundan kalıcı olarak düşürüldü.',
                    style: TextStyle(
                      fontSize: 12,
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
        ],
      ],
    );
  }

  // ==========================================
  // VIEW: SIRALI PLAN DASHBOARD (LEGACY/STANDART)
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.darkTextMuted),
              label: Text(
                'Planı Sıfırla',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirmResetPlan(context, plan, quizNotifier),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
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
              onPressed: () => _confirmDeletePlan(context, plan, quizNotifier),
            ),
          ],
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
                            '${plan.displayTitle} (${plan.listName})',
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
                      context.push('/study', extra: {
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
  // MODAL: HAVUZDAN DÜŞEN KELİMELERİ İNCELE & İADE ET
  // ==========================================
  void _showCompletedWordsModal(
    BuildContext context,
    DailyQuizPlanModel plan,
    List<WordModel> allWords,
    QuizController quizNotifier,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _CompletedWordsSheet(
          plan: plan,
          allWords: allWords,
          quizNotifier: quizNotifier,
          isDark: isDark,
        );
      },
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
    BuildContext context,
    DailyQuizPlanModel plan,
    QuizController quizNotifier,
  ) async {
    final isBuffet = plan.isOpenBuffet;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${plan.displayTitle} Sıfırlansın mı?'),
        content: Text(
          isBuffet
              ? 'Açık büfe havuzundan düşen tüm kelimeler havuza geri dönecek ve günlük seçim sıfırlanacaktır. Devam etmek istiyor musunuz?'
              : 'Mevcut ilerlemeniz sıfırlanacaktır ve ilk kelimeden itibaren tekrar başlayabileceksiniz. Devam etmek istiyor musunuz?',
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
      final success = await quizNotifier.resetPlanProgress(plan.id);
      if (!success && context.mounted) {
        _showWarningSnackBar(context, 'Plan sıfırlanamadı.');
      }
    }
  }

  Future<void> _confirmDeletePlan(
    BuildContext context,
    DailyQuizPlanModel plan,
    QuizController quizNotifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${plan.displayTitle} Silinsin mi?'),
        content: const Text(
          'Bu çalışma planı kalıcı olarak silinecektir. Varsa diğer planlarınızdan çalışmaya devam edebilirsiniz. Emin misiniz?',
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
      final success = await quizNotifier.deleteDailyPlan(planId: plan.id);
      if (!success && context.mounted) {
        _showWarningSnackBar(context, 'Plan silinemedi.');
      }
    }
  }
}

// ==========================================
// COMPLETED WORDS BOTTOM SHEET WIDGET
// ==========================================
class _CompletedWordsSheet extends StatefulWidget {
  final DailyQuizPlanModel plan;
  final List<WordModel> allWords;
  final QuizController quizNotifier;
  final bool isDark;

  const _CompletedWordsSheet({
    required this.plan,
    required this.allWords,
    required this.quizNotifier,
    required this.isDark,
  });

  @override
  State<_CompletedWordsSheet> createState() => _CompletedWordsSheetState();
}

class _CompletedWordsSheetState extends State<_CompletedWordsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedIds = widget.plan.completedWordIds
        .map((id) => int.tryParse(id.toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    final completedWords =
        widget.allWords.where((w) => completedIds.contains(w.id)).toList();

    final filtered = _searchQuery.isEmpty
        ? completedWords
        : completedWords.where((w) {
            final q = _searchQuery.toLowerCase();
            return w.en.toLowerCase().contains(q) ||
                w.tr.toLowerCase().contains(q);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Havuzdan Düşen Kelimeler (${completedWords.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bu kelimeler tamamlandığı için aktif açık büfeden çıkarıldı.',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Düşen kelimelerde ara...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: widget.isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            completedWords.isEmpty
                                ? Icons.inbox_rounded
                                : Icons.search_off_rounded,
                            size: 48,
                            color: widget.isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            completedWords.isEmpty
                                ? 'Henüz havuzdan düşen kelime yok.'
                                : 'Aramanızla eşleşen kelime bulunamadı.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final word = filtered[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.en,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: widget.isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    word.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: widget.isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Havuza İade Et Butonu
                            OutlinedButton.icon(
                              icon: const Icon(Icons.undo_rounded, size: 14),
                              label: const Text('Havuza İade Et'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0D9488),
                                side: const BorderSide(
                                    color: Color(0xFF0D9488), width: 1.2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await widget.quizNotifier
                                    .returnWordToBuffetPool(word.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '"${word.en}" tekrar açık büfe havuzuna eklendi.'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
