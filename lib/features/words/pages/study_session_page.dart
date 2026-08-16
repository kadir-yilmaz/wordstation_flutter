import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../controllers/study_controller.dart';
import '../controllers/word_list_controller.dart';
import '../models/word_model.dart';
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

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

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
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _flipAnimationController.dispose();
    _searchController.dispose();
    _exampleScrollController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    // Sayfa ekranda aktif/görünür değilse (üstüne başka sayfa açılmışsa) yakalama
    if (ModalRoute.of(context)?.isCurrent == false) return false;

    // Arama kutusu veya metin alanında yazıyorsa klavye kısayollarını devre dışı bırak
    final isEditingText =
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;
    if (isEditingText) return false;

    final studyState = ref.read(studyControllerProvider);
    final studyNotifier = ref.read(studyControllerProvider.notifier);
    final hasWords = studyState.words.isNotEmpty;
    final currentIndex = studyState.currentIndex;
    final totalCount = studyState.totalCount;
    final hasPrev = hasWords && (studyState.isRandom || currentIndex > 0);
    final hasNext = hasWords && (studyState.isRandom || currentIndex < totalCount - 1);

    // Sağ Yön Tuşu: Sonraki Kelime
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (hasNext) {
        HapticFeedback.lightImpact();
        studyNotifier.next();
        return true;
      }
    }
    // Sol Yön Tuşu: Önceki Kelime
    else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (hasPrev) {
        HapticFeedback.lightImpact();
        studyNotifier.prev();
        return true;
      }
    }
    // Yukarı Yön Tuşu veya Space: Kartı Döndür
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (hasWords) {
        HapticFeedback.selectionClick();
        studyNotifier.flip();
        return true;
      }
    }
    // Aşağı Yön Tuşu: Rastgele (Random) Modunu Aç/Kapat
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (hasWords) {
        HapticFeedback.mediumImpact();
        studyNotifier.toggleRandom();
        return true;
      }
    }
    // Nokta (.) Tuşu: Sesi Oynat (TTS)
    else if (event.logicalKey == LogicalKeyboardKey.period ||
        event.logicalKey == LogicalKeyboardKey.numpadDecimal) {
      if (hasWords) {
        HapticFeedback.lightImpact();
        studyNotifier.speakCurrent();
        return true;
      }
    }

    return false;
  }

  void _handleFlip(bool isFlipped) {
    if (isFlipped) {
      _flipAnimationController.forward();
    } else {
      _flipAnimationController.reverse();
    }
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

      if (word.id != null) {
        await ref.read(wordListControllerProvider.notifier).deleteWord(word.id);
      }

      if (!mounted) return;

      final allWords = ref.read(wordListControllerProvider).words;
      final freshListWords = (widget.listTitle != null &&
              widget.listTitle != 'All' &&
              widget.listTitle != 'Tümü')
          ? allWords.where((w) => w.listName == widget.listTitle).toList()
          : allWords;

      if (freshListWords.isEmpty) {
        Navigator.of(context).pop();
      } else {
        final currentIndex = ref.read(studyControllerProvider).currentIndex;
        final newIndex = currentIndex.clamp(0, freshListWords.length - 1);
        studyNotifier.initWithWords(freshListWords, initialIndex: newIndex);
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

    if (widget.words.isEmpty) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leadingWidth: 90,
          leading: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 8),
              foregroundColor: const Color(0xFF34C759),
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
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
              ],
            ),
          ),
        ),
      );
    }

    final hasWords = studyState.words.isNotEmpty;
    final currentWord = hasWords ? studyState.currentWord : null;
    final currentIndex = hasWords ? studyState.currentIndex : 0;
    final totalCount = studyState.totalCount;
    final hasPrev = hasWords && (studyState.isRandom || currentIndex > 0);
    final hasNext = hasWords && (studyState.isRandom || currentIndex < totalCount - 1);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                final nav = Navigator.of(context);
                final newWord = await nav.push<WordModel>(
                  MaterialPageRoute(
                    builder: (_) => AddEditWordPage(
                      initialListName: widget.listTitle ?? currentWord?.listName,
                    ),
                  ),
                );
                if (!mounted) return;
                if (newWord != null) {
                  final allWords = ref.read(wordListControllerProvider).words;
                  final freshListWords = (widget.listTitle != null &&
                          widget.listTitle != 'All' &&
                          widget.listTitle != 'Tümü')
                      ? allWords.where((w) => w.listName == widget.listTitle).toList()
                      : allWords;

                  final targetIdx = freshListWords.indexWhere((w) =>
                      w.id == newWord.id ||
                      (w.en == newWord.en && w.tr == newWord.tr));
                  final newIndex = targetIdx >= 0 ? targetIdx : (freshListWords.length - 1);
                  studyNotifier.initWithWords(
                    freshListWords,
                    initialIndex: newIndex.clamp(
                        0, freshListWords.isNotEmpty ? freshListWords.length - 1 : 0),
                  );
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
            onPressed: hasWords && currentWord != null
                ? () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    try {
                      final nav = Navigator.of(context);
                      final updated = await nav.push<WordModel>(
                        MaterialPageRoute(
                          builder: (_) => AddEditWordPage(wordToEdit: currentWord),
                        ),
                      );
                      if (!mounted) return;
                      if (updated != null) {
                        final allWords = ref.read(wordListControllerProvider).words;
                        final freshListWords = (widget.listTitle != null &&
                                widget.listTitle != 'All' &&
                                widget.listTitle != 'Tümü')
                            ? allWords.where((w) => w.listName == widget.listTitle).toList()
                            : allWords;

                        if (freshListWords.isEmpty) {
                          nav.pop();
                        } else {
                          final targetIdx = freshListWords.indexWhere((w) =>
                              w.id == updated.id ||
                              (w.en == updated.en && w.tr == updated.tr));
                          final nextIndex = targetIdx >= 0
                              ? targetIdx
                              : currentIndex.clamp(0, freshListWords.length - 1);
                          studyNotifier.initWithWords(freshListWords, initialIndex: nextIndex);
                        }
                      }
                    } finally {
                      if (mounted) _isNavigating = false;
                    }
                  }
                : null,
          ),

          // Delete Button (Green)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFF34C759)),
            tooltip: 'Delete',
            onPressed: hasWords && currentWord != null
                ? () => _handleDeleteCurrentWord(currentWord)
                : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopLayout = constraints.maxWidth >= 680;

              if (isDesktopLayout) {
                // Desktop / Web Two-Column Layout
                return ResponsiveContent(
                  maxWidth: 1100,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column: Search Bar, Synonym Badges, Example Box
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchBar(isDark, studyNotifier),
                              const SizedBox(height: 10),
                              _buildSynonymBadges(isDark, studyState),
                              const SizedBox(height: 14),
                              Expanded(
                                child: _buildExampleContainer(
                                    isDark, hasWords, currentWord),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column: Word Card, Index, Slider, Control Buttons
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildWordCardFlip(
                                    hasWords, currentWord, studyNotifier),
                              ),
                              const SizedBox(height: 14),
                              _buildIndexLabel(
                                  isDark, hasWords, currentIndex, totalCount),
                              const SizedBox(height: 6),
                              _buildProgressSlider(isDark, hasWords,
                                  currentIndex, totalCount, studyNotifier),
                              const SizedBox(height: 10),
                              _buildControlButtons(isDark, hasWords, hasPrev,
                                  hasNext, studyState, studyNotifier),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Mobile Layout (Single Column Stack)
              return ResponsiveContent(
                maxWidth: 680,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(isDark, studyNotifier),
                      const SizedBox(height: 6),
                      _buildSynonymBadges(isDark, studyState),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 5,
                        child: _buildExampleContainer(
                            isDark, hasWords, currentWord),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        flex: 5,
                        child: _buildWordCardFlip(
                            hasWords, currentWord, studyNotifier),
                      ),
                      const SizedBox(height: 10),
                      _buildIndexLabel(
                          isDark, hasWords, currentIndex, totalCount),
                      const SizedBox(height: 6),
                      _buildProgressSlider(isDark, hasWords, currentIndex,
                          totalCount, studyNotifier),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildControlButtons(isDark, hasWords, hasPrev,
                            hasNext, studyState, studyNotifier),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, StudyController studyNotifier) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFE9E9EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onTapOutside: (event) {
          FocusScope.of(context).unfocus();
        },
        onChanged: (val) {
          studyNotifier.onSearchChanged(val);
          setState(() {});
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                  onPressed: () {
                    _searchController.clear();
                    studyNotifier.onSearchChanged('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSynonymBadges(bool isDark, StudyState studyState) {
    return SizedBox(
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
                        color: badge.gradient.first.withValues(alpha: 0.3),
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
                        showWordDetailModal(context, word: badge.word);
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
          : Container(
              height: 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE9E9EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No synonyms available for this word.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildExampleContainer(
      bool isDark, bool hasWords, WordModel? currentWord) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
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
              hasWords
                  ? ((currentWord?.example != null &&
                          currentWord!.example!.trim().isNotEmpty)
                      ? currentWord.example!
                      : 'No example sentence available.')
                  : 'Aradığınız kelime bulunamadı.',
              textAlign: hasWords &&
                      (currentWord?.example != null &&
                          currentWord!.example!.trim().isNotEmpty)
                  ? TextAlign.start
                  : TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: hasWords &&
                        (currentWord?.example != null &&
                            currentWord!.example!.trim().isNotEmpty)
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
    );
  }

  Widget _buildWordCardFlip(
      bool hasWords, WordModel? currentWord, StudyController studyNotifier) {
    return GestureDetector(
      onTap: hasWords
          ? () {
              HapticFeedback.selectionClick();
              studyNotifier.flip();
            }
          : null,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * pi;
          final isBackVisible = angle >= (pi / 2);

          final cardText = hasWords
              ? (isBackVisible ? currentWord!.tr : currentWord!.en)
              : (isBackVisible ? 'Sonuç Bulunamadı' : 'No Results');

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
                      text: cardText,
                      isPink: true,
                    ),
                  )
                : _buildWordCard(
                    text: cardText,
                    isPink: false,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildIndexLabel(
      bool isDark, bool hasWords, int currentIndex, int totalCount) {
    return Center(
      child: Text(
        hasWords ? '${currentIndex + 1}/$totalCount' : '0/0',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.darkTextSecondary
              : const Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(bool isDark, bool hasWords, int currentIndex,
      int totalCount, StudyController studyNotifier) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFE5E5EA),
        inactiveTrackColor:
            isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
        disabledActiveTrackColor:
            isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
        disabledInactiveTrackColor:
            isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
        thumbColor: Colors.white,
        disabledThumbColor: Colors.white.withValues(alpha: 0.6),
        overlayColor: Colors.transparent,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
          disabledThumbRadius: 10,
          elevation: 3,
        ),
      ),
      child: Slider(
        value: (hasWords && totalCount > 1)
            ? currentIndex.toDouble().clamp(0.0, (totalCount - 1).toDouble())
            : 0.0,
        min: 0.0,
        max: (hasWords && totalCount > 1)
            ? (totalCount - 1).toDouble()
            : 1.0,
        divisions: (hasWords && totalCount > 1) ? (totalCount - 1) : 1,
        onChanged: (hasWords && totalCount > 1)
            ? (val) {
                studyNotifier.seekTo(val.round());
              }
            : null,
      ),
    );
  }

  Widget _buildControlButtons(
    bool isDark,
    bool hasWords,
    bool hasPrev,
    bool hasNext,
    StudyState studyState,
    StudyController studyNotifier,
  ) {
    return Row(
      children: [
        // [ ← Prev ]
        Expanded(
          child: _buildActionButton(
            text: '← Prev',
            backgroundColor:
                isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
            textColor: isDark ? Colors.white : Colors.black,
            isEnabled: hasPrev,
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
            isEnabled: hasWords,
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
            isEnabled: hasWords,
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
            backgroundColor:
                isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
            textColor: isDark ? Colors.white : Colors.black,
            isEnabled: hasNext,
            onTap: () {
              HapticFeedback.lightImpact();
              studyNotifier.next();
            },
          ),
        ),
      ],
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
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1.0 : 0.35,
      child: SizedBox(
        height: 52,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isEnabled ? onTap : null,
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
      ),
    );
  }
}
