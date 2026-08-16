import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../controllers/quiz_controller.dart';
import '../models/quiz_history_model.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _activeTabIndex = 0; // 0: Yeni Test, 1: Test Geçmişim
  final Set<String> _selectedLists = {}; // Starts completely EMPTY - no initial auto-selection
  int _questionCount = 10;
  int _dailyQuestionCount = 10;
  bool _enToTr = true;
  final FlutterTts _tts = FlutterTts();
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingTts = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _isPlayingTts = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _isPlayingTts = false);
      });
    } catch (_) {}
  }

  Future<void> _speakWord(String text) async {
    if (text.isEmpty) return;
    if (_isPlayingTts) {
      await _tts.stop();
      if (mounted) setState(() => _isPlayingTts = false);
      return;
    }

    try {
      HapticFeedback.lightImpact();
      setState(() => _isPlayingTts = true);
      await _tts.stop();

      // Auto-reset fallback
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isPlayingTts) {
          setState(() => _isPlayingTts = false);
        }
      });

      await _tts.speak(text);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isPlayingTts = false);
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordListState = ref.watch(wordListControllerProvider);
    final quizState = ref.watch(quizControllerProvider);
    final quizNotifier = ref.read(quizControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (quizState.isQuizCompleted) {
      return _buildQuizResult(context, quizState, quizNotifier, isDark, wordListState.words);
    }

    if (quizState.questions.isNotEmpty) {
      return _buildActiveQuiz(context, quizState, quizNotifier, isDark);
    }

    return Scaffold(
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

              // Segmented Tab Switcher (Yeni Test vs Test Geçmişim)
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
                        title: 'Yeni Test',
                        icon: Icons.quiz_rounded,
                        isSelected: _activeTabIndex == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Test Geçmişim (${quizState.historyList.length})',
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
                    ? _buildNewQuizTab(context, wordListState, quizState, quizNotifier, isDark)
                    : _buildHistoryTab(context, quizState, quizNotifier, isDark, wordListState.words),
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
  // TAB 1: YENİ TEST (GÜNÜN QUİZİ + ÖZEL TEST)
  // ==========================================
  Widget _buildNewQuizTab(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. GÜNÜN QUİZİ KARTI (ÖZEL BÖLÜM)
          _buildDailyQuizCard(context, wordListState, quizState, quizNotifier, isDark),
          const SizedBox(height: 24),

          // 2. ÖZEL TEST OLUŞTUR BÖLÜMÜ
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
                      if (_selectedLists.length == wordListState.listNames.length) {
                        _selectedLists.clear();
                      } else {
                        _selectedLists.addAll(wordListState.listNames);
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _selectedLists.length == wordListState.listNames.length
                        ? 'Seçimi Temizle'
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

          // List Selection Chips (Starts empty, no auto-tick)
          if (wordListState.listNames.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Text(
                  'Henüz kayıtlı bir kelime listeniz bulunmuyor.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wordListState.listNames.map((name) {
                final isSelected = _selectedLists.contains(name);
                final listCount = wordListState.words
                    .where((w) => w.listName == name)
                    .length;

                return FilterChip(
                  label: Text('$name ($listCount)'),
                  selected: isSelected,
                  selectedColor: AppColors.turquoise.withValues(alpha: 0.15),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.turquoise
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 1.8 : 1.2,
                    ),
                  ),
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
                );
              }).toList(),
            ),

          if (_selectedLists.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lütfen test yapmak istediğiniz en az 1 listeyi işaretleyin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.orange.shade300 : AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

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
            children: [5, 10, 15, 20].map((count) {
              final isSelected = _questionCount == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _questionCount = count);
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
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
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

          // Soru Yönü Seçimi
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
                    setState(() => _enToTr = true);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _enToTr
                          ? AppColors.pink.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _enToTr
                            ? AppColors.pink
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
                          fontWeight: _enToTr ? FontWeight.w700 : FontWeight.w600,
                          color: _enToTr
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
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _enToTr = false);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_enToTr
                          ? AppColors.pink.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurface : Colors.white),
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
            onPressed: () => _handleStartCustomQuiz(context, wordListState, quizNotifier),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Günün Quizi Özel Kartı
  Widget _buildDailyQuizCard(
    BuildContext context,
    WordListState wordListState,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final isCompleted = quizState.isDailyQuizCompletedToday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? const LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.turquoiseGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? const Color(0xFF34C759) : AppColors.turquoise)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.star_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Günün Quizi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GÜNLÜK HEDEF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Bugünkü hedefini başarıyla tamamladın! 🎉 Yarın yeni kelimelerle görüşmek üzere.'
                          : 'Günde 10 kelime çözerek hafızanı zinde tut.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isCompleted) ...[
            const SizedBox(height: 16),

            // Soru Sayısı Seçici (5, 10, 15, 20)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Soru Sayısı: $_dailyQuestionCount Kelime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [5, 10, 15, 20].map((c) {
                    final isSel = _dailyQuestionCount == c;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _dailyQuestionCount = c);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$c',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? AppColors.turquoise
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Günün Quizi Başlat Butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.turquoise,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (wordListState.words.length < 4) {
                  _showWarningSnackBar(
                      context, 'Günün testini başlatmak için en az 4 kelimeniz olmalıdır.');
                  return;
                }
                quizNotifier.generateDailyQuiz(
                  questionCount: _dailyQuestionCount,
                  englishToTurkish: _enToTr,
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: AppColors.turquoise,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Günün Testini Başlat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.turquoise,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleStartCustomQuiz(
    BuildContext context,
    WordListState wordListState,
    QuizController quizNotifier,
  ) {
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

  // ==========================================
  // TAB 2: TEST GEÇMİŞİM (QUIZ HISTORY)
  // ==========================================
  Widget _buildHistoryTab(
    BuildContext context,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
    List<WordModel> allWords,
  ) {
    final historyList = quizState.historyList;

    if (historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Çözülmüş Test Yok',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Çözdüğünüz tüm testlerin sonuçları ve detayları burada listelenecektir.',
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
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GEÇMİŞ TEST KAYITLARI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Geçmişi Temizle'),
                    content: const Text(
                        'Tüm quiz geçmiş kayıtlarınız silinecektir. Emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Vazgeç'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await quizNotifier.clearAllHistory();
                }
              },
              child: const Text(
                'Tümünü Temizle',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: historyList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final entry = historyList[idx];
              final dateStr =
                  '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year} - ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';
              final isSuccess = entry.percentage >= 70;

              return InkWell(
                onTap: () => _showHistoryDetailModal(context, entry, isDark, allWords),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Score Badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (isSuccess ? AppColors.success : AppColors.orange)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '%${entry.percentage}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSuccess
                                  ? AppColors.success
                                  : AppColors.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (entry.isDailyQuiz) ...[
                                  const Icon(Icons.star_rounded,
                                      size: 16, color: AppColors.orange),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    entry.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.score}/${entry.maxScore} Puan',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.turquoise,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.correctCount} Doğru, ${entry.wrongCount} Yanlış',
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
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Geçmiş Testin Detaylı Bottom Sheet'i
  void _showHistoryDetailModal(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${entry.correctCount} Doğru / ${entry.totalQuestions} Soru (%${entry.percentage})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.turquoise,
                          ),
                        ),
                      ],
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: entry.results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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

  // ==========================================
  // AKTİF QUIZ EKRANI (SESLİ + HAPTİC)
  // ==========================================
  Widget _buildActiveQuiz(
    BuildContext context,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
  ) {
    final question = quizState.currentQuestion!;
    final index = quizState.currentIndex;
    final total = quizState.totalQuestions;
    final progress = (index + 1) / total;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _tts.stop();
            quizNotifier.resetToSetup();
          },
        ),
        title: Text(
          'Soru ${index + 1} / $total',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded,
                    size: 18, color: AppColors.turquoise),
                const SizedBox(width: 4),
                Text(
                  '${quizState.score} Puan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.turquoise,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Linear Progress Bar & Counter
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.turquoise),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${index + 1}/$total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Question Card with Audio Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 26),
                    decoration: BoxDecoration(
                      gradient: AppColors.turquoiseGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.turquoise.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quizState.isEnglishToTurkish
                              ? 'Bu kelimenin Türkçe anlamı nedir?'
                              : 'Bu ifadenin İngilizce karşılığı nedir?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Word Text + Speaker Audio Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                question.questionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => _speakWord(question.word.en),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlayingTts
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_down_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (question.word.listName != null &&
                            question.word.listName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.word.listName!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4 Option Cards
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: question.options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, optIndex) {
                        final option = question.options[optIndex];
                        final optionLetter =
                            String.fromCharCode(65 + optIndex); // A, B, C, D

                        final isSelected = quizState.selectedAnswer == option;
                        final isCorrect = option == question.correctAnswer;

                        Color cardColor =
                            isDark ? AppColors.darkSurface : Colors.white;
                        Color borderColor =
                            isDark ? AppColors.darkBorder : AppColors.lightBorder;
                        Color textColor = isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary;
                        IconData? statusIcon;

                        if (quizState.isAnswered) {
                          if (isCorrect) {
                            cardColor = AppColors.success.withValues(alpha: 0.15);
                            borderColor = AppColors.success;
                            textColor = AppColors.success;
                            statusIcon = Icons.check_circle_rounded;
                          } else if (isSelected) {
                            cardColor = AppColors.error.withValues(alpha: 0.15);
                            borderColor = AppColors.error;
                            textColor = AppColors.error;
                            statusIcon = Icons.cancel_rounded;
                          }
                        }

                        return InkWell(
                          onTap: quizState.isAnswered
                              ? null
                              : () {
                                  quizNotifier.selectAnswer(option);
                                },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor,
                                width: (isSelected ||
                                        (quizState.isAnswered && isCorrect))
                                    ? 2
                                    : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (quizState.isAnswered && isCorrect)
                                        ? AppColors.success
                                        : (quizState.isAnswered && isSelected)
                                            ? AppColors.error
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : Colors.grey.shade200),
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLetter,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: (quizState.isAnswered &&
                                                (isCorrect || isSelected))
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (statusIcon != null)
                                  Icon(statusIcon, color: borderColor, size: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DETAYLI SONUÇ EKRANI & KELİME POP-UP'LARI
  // ==========================================
  Widget _buildQuizResult(
    BuildContext context,
    QuizState quizState,
    QuizController quizNotifier,
    bool isDark,
    List<WordModel> allWords,
  ) {
    final maxScore = quizState.maxScore;
    final score = quizState.score;
    final percentage = quizState.percentage;
    final isSuccess = percentage >= 70;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => quizNotifier.resetToSetup(),
        ),
        title: const Text('Test Sonucu', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Trophy / Medal Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: isSuccess
                        ? AppColors.turquoiseGradient
                        : AppColors.orangeGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? AppColors.turquoise : AppColors.orange)
                            .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSuccess ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isSuccess ? 'Tebrikler! Harika İş!' : 'Test Tamamlandı!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSuccess
                    ? 'Kelimeleri başarıyla pekiştirdin.'
                    : 'Aşağıdaki kelimeleri inceleyerek eksiklerini tamamlayabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Score Card Row
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Toplam Puan', '$score / $maxScore', AppColors.turquoise, isDark),
                    Container(width: 1, height: 36, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _buildStatCol('Başarı Oranı', '%$percentage', isSuccess ? AppColors.success : AppColors.orange, isDark),
                    Container(width: 1, height: 36, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _buildStatCol('Doğru / Yanlış', '${quizState.correctCount} D / ${quizState.wrongCount} Y', isDark ? Colors.white : Colors.black87, isDark),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Detailed Questions Breakdown Header
              Text(
                'SORU DETAYLARI & KELİMELER',
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

              // List of all question results
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizState.results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, qIdx) {
                  final resultItem = quizState.results[qIdx];
                  return _buildQuestionResultCard(
                    context,
                    resultItem,
                    qIdx + 1,
                    isDark,
                    allWords,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildStatCol(String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionResultCard(
    BuildContext context,
    QuizQuestionResult item,
    int index,
    bool isDark,
    List<WordModel> allWords,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showWordDetailModal(
          context,
          word: item.word,
          allWords: allWords,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isCorrect
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.error.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item.isCorrect ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isCorrect
                    ? Icons.check_rounded
                    : Icons.close_rounded,
                size: 18,
                color: item.isCorrect ? AppColors.success : AppColors.error,
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${item.word.tr})',
                          style: TextStyle(
                            fontSize: 13,
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
                  const SizedBox(height: 4),
                  if (item.isCorrect)
                    Text(
                      'Doğru Cevabınız: ${item.selectedAnswer}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Sizin Cevabınız: ',
                          ),
                          TextSpan(
                            text: '${item.selectedAnswer} ',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '➔ Doğru: '),
                          TextSpan(
                            text: item.correctAnswer,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }
}
