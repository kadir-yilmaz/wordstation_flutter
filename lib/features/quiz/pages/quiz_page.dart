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
import '../controllers/quiz_controller.dart';
import '../widgets/active_quiz_view.dart';
import '../widgets/quiz_history_view.dart';
import '../widgets/quiz_result_view.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _activeTabIndex = 0; // 0: Quiz Yap, 1: Geçmiş Sonuçlar
  final Set<String> _selectedLists = {}; // Starts completely EMPTY - no initial auto-selection
  int _questionCount = 10;
  bool _enToTr = true;

  @override
  void initState() {
    super.initState();
    final initialLists = ref.read(wordListControllerProvider).listNames;
    if (initialLists.isNotEmpty) {
      _selectedLists.add(initialLists.first);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(quizControllerProvider.notifier).loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordListState = ref.watch(wordListControllerProvider);
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-select first list by default if nothing selected
    if (_selectedLists.isEmpty && wordListState.listNames.isNotEmpty) {
      _selectedLists.add(wordListState.listNames.first);
    }

    // If an active custom quiz is in progress, show active quiz view
    if (!quizState.isDailyQuiz && quizState.questions.isNotEmpty) {
      return ActiveQuizView(
        quizState: quizState,
        quizNotifier: quizNotifier,
      );
    }

    // If custom quiz was completed, show result view
    if (!quizState.isDailyQuiz && quizState.isQuizCompleted) {
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
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelime Testi',
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
                        'Kelime dağarcığını test et ve pekiştir',
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

              // Segmented Tab Switcher (2 Tabs: Quiz Yap & Geçmiş Sonuçlar)
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
                        title: 'Quiz Yap',
                        icon: Icons.quiz_rounded,
                        isSelected: _activeTabIndex == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Geçmiş Sonuçlar',
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

              // Body Content
              Expanded(
                child: _activeTabIndex == 0
                    ? _buildGeneralQuizTab(
                        context, wordListState, quizState, quizNotifier, isDark)
                    : const QuizHistoryView(isDailyQuiz: false),
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
  // TAB 1: QUİZ YAP (ÖZEL TEST AYARLARI)
  // ==========================================
  Widget _buildGeneralQuizTab(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    if (wordListState.errorMessage != null && wordListState.words.isEmpty) {
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
              title: 'Kelimeler Yüklenemedi',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LİSTE SEÇİMİ (ZORUNLU)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                if (wordListState.listNames.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_selectedLists.length ==
                            wordListState.listNames.length) {
                          _selectedLists.clear();
                        } else {
                          _selectedLists.addAll(wordListState.listNames);
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _selectedLists.length == wordListState.listNames.length
                          ? 'Temizle'
                          : 'Tümünü Seç',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.turquoise,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Modern Multi-Select Filter Chips with word count badge
            if (wordListState.listNames.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  'Henüz oluşturulmuş bir kelime listesi bulunmuyor. Test yapmak için önce liste oluşturun.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wordListState.listNames.map((name) {
                  final isSelected = _selectedLists.contains(name);
                  final count = wordListState.words
                      .where((w) => w.listName == name)
                      .length;

                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.turquoise.withValues(alpha: 0.3)
                                : (isDark
                                    ? AppColors.darkCardElevated
                                    : const Color(0xFFE5E5EA)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.turquoise
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedLists.add(name);
                        } else {
                          _selectedLists.remove(name);
                        }
                      });
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

            const SizedBox(height: 24),

            // Soru Sayısı Seçimi
            Text(
              'SORU SAYISI',
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
              children: [5, 10, 15, 20, 25].map((count) {
                final isSelected = _questionCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _questionCount = count;
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

            const SizedBox(height: 24),

            // Soru Yönü Seçimi (İngilizce -> Türkçe / Türkçe -> İngilizce)
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
                        _enToTr = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _enToTr
                            ? AppColors.turquoise.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.darkSurface
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _enToTr
                              ? AppColors.turquoise
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: _enToTr ? 2 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'İngilizce ➔ Türkçe',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _enToTr ? FontWeight.w700 : FontWeight.w600,
                            color: _enToTr
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
                        _enToTr = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_enToTr
                            ? AppColors.pink.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.darkSurface
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: !_enToTr
                              ? AppColors.pink
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: !_enToTr ? 2 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Türkçe ➔ İngilizce',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                !_enToTr ? FontWeight.w700 : FontWeight.w600,
                            color: !_enToTr
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

            const SizedBox(height: 30),

            // Başlat Butonu
            CustomButton(
              text: 'Testi Başlat',
              prefixIcon: Icons.play_arrow_rounded,
              variant: ButtonVariant.primary,
              onPressed: () =>
                  _handleStartCustomQuiz(context, wordListState, quizNotifier),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _handleStartCustomQuiz(
    BuildContext context,
    WordListState wordListState,
    QuizController quizNotifier,
  ) {
    if (wordListState.words.isEmpty) {
      final err = wordListState.errorMessage;
      if (err != null && DioErrorHandler.isNetworkError(err)) {
        NoInternetDialog.show(
          context,
          onRetry: () async {
            await ref.read(wordListControllerProvider.notifier).refresh();
            await quizNotifier.loadInitialData();
          },
        );
        return;
      }
    }

    if (_selectedLists.isEmpty) {
      _showWarningSnackBar(
        context,
        'Lütfen test yapmak istediğiniz en az bir kelime listesi seçin.',
      );
      return;
    }

    final targetWords = wordListState.words
        .where((w) => _selectedLists.contains(w.listName))
        .toList();

    if (targetWords.length < 4) {
      _showWarningSnackBar(
        context,
        'Seçtiğiniz listelerde toplam en az 4 kelime bulunmalıdır (Mevcut: ${targetWords.length}).',
      );
      return;
    }

    final title = _selectedLists.length == 1
        ? _selectedLists.first
        : '${_selectedLists.length} Liste (${_selectedLists.take(2).join(", ")}...)';

    quizNotifier.generateQuiz(
      customWords: targetWords,
      questionCount: _questionCount,
      englishToTurkish: _enToTr,
      title: title,
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
}
