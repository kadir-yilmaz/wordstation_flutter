import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../controllers/study_controller.dart';
import '../controllers/word_list_controller.dart';
import '../models/word_model.dart';
import '../widgets/study/study_control_buttons.dart';
import '../widgets/study/study_empty_state.dart';
import '../widgets/study/study_example_box.dart';
import '../widgets/study/study_progress_slider.dart';
import '../widgets/study/study_search_bar.dart';
import '../widgets/study/study_synonyms_bar.dart';
import '../widgets/study/study_word_card.dart';
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
  final FocusNode _pageFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  final ScrollController _exampleScrollController = ScrollController();
  final ScrollController _desktopSynonymsScrollController = ScrollController();
  final ScrollController _mobileSynonymsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
      _pageFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageFocusNode.dispose();
    _flipAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _exampleScrollController.dispose();
    _desktopSynonymsScrollController.dispose();
    _mobileSynonymsScrollController.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!mounted) return KeyEventResult.ignored;

    // Sayfa ekranda aktif/görünür değilse yakalama
    if (ModalRoute.of(context)?.isCurrent == false) {
      return KeyEventResult.ignored;
    }

    // Arama kutusu odaklanmışsa veya herhangi bir metin alanı aktifse
    if (_searchFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _searchFocusNode.unfocus();
        _pageFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null &&
        primaryFocus != FocusManager.instance.rootScope &&
        primaryFocus != _pageFocusNode &&
        (primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
            primaryFocus.context?.widget is EditableText)) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        primaryFocus.unfocus();
        _pageFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final studyState = ref.read(studyControllerProvider);
    final studyNotifier = ref.read(studyControllerProvider.notifier);
    final hasWords = studyState.words.isNotEmpty;
    final currentIndex = studyState.currentIndex;
    final totalCount = studyState.totalCount;
    final hasPrev = hasWords && currentIndex > 0;
    final hasNext = hasWords && currentIndex < totalCount - 1;

    // 1. Sağ Yön Tuşu / D: Sonraki Kelime
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      if (hasNext) {
        HapticFeedback.lightImpact();
        studyNotifier.next();
      }
      return KeyEventResult.handled;
    }
    // 2. Sol Yön Tuşu / A: Önceki Kelime
    else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      if (hasPrev) {
        HapticFeedback.lightImpact();
        studyNotifier.prev();
      }
      return KeyEventResult.handled;
    }
    // 3. Yukarı Yön Tuşu / Space / W: Kartı Döndür
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.keyW) {
      if (hasWords) {
        HapticFeedback.selectionClick();
        studyNotifier.flip();
      }
      return KeyEventResult.handled;
    }
    // 4. Aşağı Yön Tuşu / S / R: Rastgele (Random) Kelime
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS ||
        event.logicalKey == LogicalKeyboardKey.keyR) {
      if (hasWords && totalCount > 1) {
        HapticFeedback.mediumImpact();
        studyNotifier.toggleRandom();
      }
      return KeyEventResult.handled;
    }
    // 5. Nokta (.) / V / L / NumpadDecimal: Sesi Oynat (TTS)
    else if (event.logicalKey == LogicalKeyboardKey.period ||
        event.logicalKey == LogicalKeyboardKey.numpadDecimal ||
        event.logicalKey == LogicalKeyboardKey.keyV ||
        event.logicalKey == LogicalKeyboardKey.keyL) {
      if (hasWords) {
        HapticFeedback.lightImpact();
        studyNotifier.speakCurrent();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleFlip(bool isFlipped) {
    if (isFlipped) {
      _flipAnimationController.forward();
    } else {
      _flipAnimationController.reverse();
    }
  }

  Future<void> _handleAddWord() async {
    final nav = Navigator.of(context);
    final studyNotifier = ref.read(studyControllerProvider.notifier);
    final updated = await nav.push<WordModel>(
      MaterialPageRoute(
        builder: (_) => AddEditWordPage(
          initialListName: widget.listTitle != 'All' ? widget.listTitle : null,
        ),
      ),
    );

    if (updated != null && mounted) {
      ref.read(wordListControllerProvider.notifier).refresh();
      final allWords = ref.read(wordListControllerProvider).words;
      final freshListWords = (widget.listTitle != null &&
              widget.listTitle != 'All' &&
              widget.listTitle != 'General')
          ? allWords.where((w) => w.listName == widget.listTitle).toList()
          : allWords;
      final targetIdx = freshListWords.indexWhere((w) =>
          w.id == updated.id ||
          (w.en == updated.en && w.tr == updated.tr));
      final nextIndex = targetIdx >= 0 ? targetIdx : 0;
      studyNotifier.initWithWords(freshListWords, initialIndex: nextIndex);
    }
  }

  Future<void> _handleEditCurrentWord(WordModel currentWord) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final nav = Navigator.of(context);
      final studyNotifier = ref.read(studyControllerProvider.notifier);
      final updated = await nav.push<WordModel>(
        MaterialPageRoute(
          builder: (_) => AddEditWordPage(wordToEdit: currentWord),
        ),
      );

      if (updated != null && mounted) {
        ref.read(wordListControllerProvider.notifier).refresh();
        final allWords = ref.read(wordListControllerProvider).words;
        final freshListWords = (widget.listTitle != null &&
                widget.listTitle != 'All' &&
                widget.listTitle != 'General')
            ? allWords.where((w) => w.listName == widget.listTitle).toList()
            : allWords;

        if (freshListWords.isEmpty) {
          nav.pop();
        } else {
          final targetIdx = freshListWords.indexWhere((w) =>
              w.id == updated.id ||
              (w.en == updated.en && w.tr == updated.tr));
          final currentIndex = ref.read(studyControllerProvider).currentIndex;
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

    // Listen to flip state and index changes
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: StudyEmptyState(isDark: isDark),
        ),
      );
    }

    final hasWords = studyState.words.isNotEmpty;
    final currentWord = hasWords ? studyState.currentWord : null;
    final currentIndex = hasWords ? studyState.currentIndex : 0;
    final totalCount = studyState.totalCount;
    final hasPrev = hasWords && currentIndex > 0;
    final hasNext = hasWords && currentIndex < totalCount - 1;

    return Focus(
      focusNode: _pageFocusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
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
            widget.listTitle ?? 'Study',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            // Add Word Button (Green)
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 24, color: Color(0xFF34C759)),
              tooltip: 'Add Word',
              onPressed: _handleAddWord,
            ),

            // Edit Word Button (Green)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 21, color: Color(0xFF34C759)),
              tooltip: 'Edit Word',
              onPressed: hasWords && currentWord != null
                  ? () => _handleEditCurrentWord(currentWord)
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
        body: Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent: DoNothingAction(),
            ActivateIntent: DoNothingAction(),
            ButtonActivateIntent: DoNothingAction(),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              _pageFocusNode.requestFocus();
            },
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
                            // Left Column: Solo Example Box
                            Expanded(
                              flex: 5,
                              child: StudyExampleBox(
                                isDark: isDark,
                                hasWords: hasWords,
                                currentWord: currentWord,
                                scrollController: _exampleScrollController,
                              ),
                            ),

                            const SizedBox(width: 24),

                            // Right Column: Search, Synonyms, Centered Word Card & Controls
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StudySearchBar(
                                    isDark: isDark,
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onChanged: (val) {
                                      studyNotifier.onSearchChanged(val);
                                      setState(() {});
                                    },
                                    onClear: () {
                                      _searchController.clear();
                                      studyNotifier.onSearchChanged('');
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  StudySynonymsBar(
                                    isDark: isDark,
                                    badges: studyState.synonymBadges,
                                    isDesktop: true,
                                    scrollController: _desktopSynonymsScrollController,
                                    onBeforeOpenModal: () {
                                      _searchFocusNode.unfocus();
                                      FocusScope.of(context).unfocus();
                                    },
                                    onAfterCloseModal: () {
                                      if (mounted) {
                                        _searchFocusNode.unfocus();
                                        _pageFocusNode.requestFocus();
                                      }
                                    },
                                  ),

                                  // Centered Card & Controls Area
                                  Expanded(
                                    child: Center(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            SizedBox(
                                              height: 220,
                                              child: StudyWordCardFlip(
                                                hasWords: hasWords,
                                                currentWord: currentWord,
                                                flipAnimation: _flipAnimation,
                                                onFlip: studyNotifier.flip,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            StudyIndexLabel(
                                              isDark: isDark,
                                              hasWords: hasWords,
                                              currentIndex: currentIndex,
                                              totalCount: totalCount,
                                            ),
                                            const SizedBox(height: 8),
                                            StudyProgressSlider(
                                              isDark: isDark,
                                              hasWords: hasWords,
                                              currentIndex: currentIndex,
                                              totalCount: totalCount,
                                              onSeek: studyNotifier.seekTo,
                                            ),
                                            const SizedBox(height: 16),
                                            StudyControlButtons(
                                              isDark: isDark,
                                              hasWords: hasWords,
                                              hasPrev: hasPrev,
                                              hasNext: hasNext,
                                              isPlayingTts: studyState.isPlayingTts,
                                              onPrev: studyNotifier.prev,
                                              onRandom: studyNotifier.toggleRandom,
                                              onTts: studyNotifier.speakCurrent,
                                              onNext: studyNotifier.next,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
                          StudySearchBar(
                            isDark: isDark,
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (val) {
                              studyNotifier.onSearchChanged(val);
                              setState(() {});
                            },
                            onClear: () {
                              _searchController.clear();
                              studyNotifier.onSearchChanged('');
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 6),
                          StudySynonymsBar(
                            isDark: isDark,
                            badges: studyState.synonymBadges,
                            isDesktop: false,
                            scrollController: _mobileSynonymsScrollController,
                            onBeforeOpenModal: () {
                              _searchFocusNode.unfocus();
                              FocusScope.of(context).unfocus();
                            },
                            onAfterCloseModal: () {
                              if (mounted) {
                                _searchFocusNode.unfocus();
                                _pageFocusNode.requestFocus();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 5,
                            child: StudyExampleBox(
                              isDark: isDark,
                              hasWords: hasWords,
                              currentWord: currentWord,
                              scrollController: _exampleScrollController,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            flex: 5,
                            child: StudyWordCardFlip(
                              hasWords: hasWords,
                              currentWord: currentWord,
                              flipAnimation: _flipAnimation,
                              onFlip: studyNotifier.flip,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StudyIndexLabel(
                            isDark: isDark,
                            hasWords: hasWords,
                            currentIndex: currentIndex,
                            totalCount: totalCount,
                          ),
                          const SizedBox(height: 6),
                          StudyProgressSlider(
                            isDark: isDark,
                            hasWords: hasWords,
                            currentIndex: currentIndex,
                            totalCount: totalCount,
                            onSeek: studyNotifier.seekTo,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: StudyControlButtons(
                              isDark: isDark,
                              hasWords: hasWords,
                              hasPrev: hasPrev,
                              hasNext: hasNext,
                              isPlayingTts: studyState.isPlayingTts,
                              onPrev: studyNotifier.prev,
                              onRandom: studyNotifier.toggleRandom,
                              onTts: studyNotifier.speakCurrent,
                              onNext: studyNotifier.next,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
