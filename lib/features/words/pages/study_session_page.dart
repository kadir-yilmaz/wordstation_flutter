import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../controllers/study_controller.dart';
import '../controllers/word_list_controller.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';
import 'add_edit_word_page.dart';

class StudySessionPage extends ConsumerStatefulWidget {
  final List<WordModel> words;
  final int initialIndex;
  final String? listTitle;

  const StudySessionPage({
    super.key,
    required this.words,
    this.initialIndex = 0,
    this.listTitle,
  });

  @override
  ConsumerState<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends ConsumerState<StudySessionPage>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _exampleScrollController = ScrollController();
  final FlutterTts _sheetTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    _sheetTts.setLanguage('en-US');
    _sheetTts.setSpeechRate(0.48);
    _sheetTts.awaitSpeakCompletion(true);

    _flipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyControllerProvider.notifier).initWithWords(
            widget.words,
            initialIndex: widget.initialIndex,
          );
    });
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    _searchController.dispose();
    _exampleScrollController.dispose();
    _sheetTts.stop();
    super.dispose();
  }

  void _handleFlip(bool isFlipped) {
    if (isFlipped) {
      _flipAnimationController.forward();
    } else {
      _flipAnimationController.reverse();
    }
  }

  // Show Synonym Detail Modal Pop-up (Swift SynonymWordDetailSheet replica)
  void _showSynonymDetailSheet(BuildContext context, WordModel word) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Grabber handle
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF48484A)
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. English word + Speaker Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        word.en,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        size: 28,
                        color: Color(0xFF007AFF), // iOS Blue
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _sheetTts.stop();
                        _sheetTts.speak(word.en);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 3. Turkish meaning
                Text(
                  word.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE5E5EA),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Example sentence with SelectableText
                SelectableText(
                  (word.example != null && word.example!.trim().isNotEmpty)
                      ? word.example!
                      : 'No example sentence available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    color: (word.example != null &&
                            word.example!.trim().isNotEmpty)
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteCurrentWord(WordModel word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete'),
        content: Text('Delete ${word.en}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final studyNotifier = ref.read(studyControllerProvider.notifier);
      final wordService = ref.read(wordServiceProvider);

      if (word.id != null) {
        await wordService.deleteWord(word.id);
        ref.read(wordListControllerProvider.notifier).refresh();
      }

      final currentWords =
          List<WordModel>.from(ref.read(studyControllerProvider).words);
      currentWords.removeWhere((w) => w.id == word.id || w.en == word.en);

      if (currentWords.isEmpty) {
        if (mounted) Navigator.of(context).pop();
      } else {
        final currentIndex = ref.read(studyControllerProvider).currentIndex;
        final newIndex =
            currentIndex >= currentWords.length ? currentWords.length - 1 : currentIndex;
        studyNotifier.initWithWords(currentWords, initialIndex: newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyControllerProvider);
    final studyNotifier = ref.read(studyControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to flip state changes
    ref.listen<StudyState>(studyControllerProvider, (prev, next) {
      if (prev?.isFlipped != next.isFlipped) {
        _handleFlip(next.isFlipped);
      }
      if (prev?.currentIndex != next.currentIndex) {
        if (_exampleScrollController.hasClients) {
          _exampleScrollController.jumpTo(0);
        }
      }
    });

    if (studyState.words.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.listTitle ?? 'Study Session'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: AppColors.turquoise,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu Listede Henüz Kelime Yok',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu listeye ilk kelimenizi ekleyerek çalışmaya başlayın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Yeni Kelime Ekle',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final created = await Navigator.of(context).push<WordModel>(
                      MaterialPageRoute(
                        builder: (_) => AddEditWordPage(
                          initialListName: widget.listTitle,
                        ),
                      ),
                    );
                    if (created != null && mounted) {
                      studyNotifier.initWithWords([created]);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentWord = studyState.currentWord!;
    final currentIndex = studyState.currentIndex;
    final totalCount = studyState.totalCount;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leadingWidth: 90,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 8),
            foregroundColor: const Color(0xFF34C759), // iOS Green
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          label: const Text(
            'Back',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.listTitle ?? 'Study Session',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          // Add Word Button (Green)
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26, color: Color(0xFF34C759)),
            tooltip: 'Yeni Kelime Ekle',
            onPressed: () async {
              if (_isNavigating) return;
              _isNavigating = true;
              try {
                final newWord = await Navigator.of(context).push<WordModel>(
                  MaterialPageRoute(
                    builder: (_) => AddEditWordPage(
                      initialListName: widget.listTitle ?? currentWord.listName,
                    ),
                  ),
                );
                if (newWord != null && mounted) {
                  final currentWords = List<WordModel>.from(studyState.words);
                  currentWords.add(newWord);
                  studyNotifier.initWithWords(currentWords, initialIndex: currentWords.length - 1);
                  ref.read(wordListControllerProvider.notifier).refresh();
                }
              } finally {
                if (mounted) _isNavigating = false;
              }
            },
          ),

          // Edit Button (Green)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF34C759)),
            tooltip: 'Edit',
            onPressed: () async {
              if (_isNavigating) return;
              _isNavigating = true;
              try {
                final updated = await Navigator.of(context).push<WordModel>(
                  MaterialPageRoute(
                    builder: (_) => AddEditWordPage(wordToEdit: currentWord),
                  ),
                );
                if (updated != null && mounted) {
                  final updatedWords = List<WordModel>.from(studyState.words);
                  updatedWords[currentIndex] = updated;
                  studyNotifier.initWithWords(updatedWords, initialIndex: currentIndex);
                }
              } finally {
                if (mounted) _isNavigating = false;
              }
            },
          ),

          // Delete Button (Green)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFF34C759)),
            tooltip: 'Delete',
            onPressed: () => _handleDeleteCurrentWord(currentWord),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 680,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // 1. Search Bar (Swift replica)
              Container(
                height: 42,
                margin: const EdgeInsets.only(top: 6, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFE9E9EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    studyNotifier.onSearchChanged(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a word...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // 2. Synonym Badges (Height matching search bar: 42)
              SizedBox(
                height: 42,
                child: studyState.synonymBadges.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        itemCount: studyState.synonymBadges.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final badge = studyState.synonymBadges[idx];

                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: badge.gradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: badge.gradient.first
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showSynonymDetailSheet(context, badge.word);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Center(
                                    child: Text(
                                      badge.word.en,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'No synonyms available for this word.',
                                style: TextStyle(
                                  fontSize: 13,
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
              ),
              const SizedBox(height: 10),

              // 3. Example Container (TOP - Clean matching Swift StudyVC with SelectableText)
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E5EA),
                      width: 1.5,
                    ),
                  ),
                  child: Scrollbar(
                    controller: _exampleScrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _exampleScrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SelectableText(
                          (currentWord.example != null &&
                                  currentWord.example!.trim().isNotEmpty)
                              ? currentWord.example!
                              : 'No example sentence available.',
                          textAlign: (currentWord.example != null &&
                                  currentWord.example!.trim().isNotEmpty)
                              ? TextAlign.start
                              : TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            color: (currentWord.example != null &&
                                    currentWord.example!.trim().isNotEmpty)
                                ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : Colors.black87)
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : const Color(0xFF8E8E93)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Word Card (MIDDLE / BOTTOM - Matching Swift StudyVC)
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    studyNotifier.flip();
                  },
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * pi;
                      final isBackVisible = angle >= (pi / 2);

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isBackVisible
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildWordCard(
                                  text: currentWord.tr,
                                  isPink: true,
                                ),
                              )
                            : _buildWordCard(
                                text: currentWord.en,
                                isPink: false,
                              ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 5. Index Label (Centered right below word card)
              Center(
                child: Text(
                  '${currentIndex + 1}/$totalCount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // 6. Progress Slider
              if (totalCount > 1)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE5E5EA),
                    inactiveTrackColor: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE5E5EA),
                    thumbColor: Colors.white,
                    overlayColor: Colors.transparent,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 3,
                    ),
                  ),
                  child: Slider(
                    value: currentIndex.toDouble(),
                    min: 0,
                    max: (totalCount - 1).toDouble(),
                    divisions: totalCount > 1 ? totalCount - 1 : 1,
                    onChanged: (val) {
                      studyNotifier.seekTo(val.round());
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // 7. Control Buttons Bar (4 Buttons in a row - Swift replica)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    // [ ← Prev ]
                    Expanded(
                      child: _buildActionButton(
                        text: '← Prev',
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF2F2F7),
                        textColor: isDark ? Colors.white : Colors.black,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          studyNotifier.prev();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // [ Random ] (Vibrant Orange)
                    Expanded(
                      child: _buildActionButton(
                        text: 'Random',
                        backgroundColor: const Color(0xFFFF9500),
                        textColor: Colors.white,
                        isBold: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          studyNotifier.toggleRandom();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // [ 🔊 ] (Vibrant Blue Speaker)
                    Expanded(
                      child: _buildActionButton(
                        icon: studyState.isPlayingTts
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                        backgroundColor: const Color(0xFF007AFF),
                        textColor: Colors.white,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          studyNotifier.speakCurrent();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // [ Next → ]
                    Expanded(
                      child: _buildActionButton(
                        text: 'Next →',
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF2F2F7),
                        textColor: isDark ? Colors.white : Colors.black,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          studyNotifier.next();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildWordCard({
    required String text,
    required bool isPink,
  }) {
    // Turquoise: #12C6B2 / Pink: #E3719D matching Swift WordCardView
    final bgColor = isPink
        ? const Color(0xFFE3719D)
        : const Color(0xFF12C6B2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    String? text,
    IconData? icon,
    required Color backgroundColor,
    required Color textColor,
    bool isBold = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: textColor, size: 24)
                : Text(
                    text ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
