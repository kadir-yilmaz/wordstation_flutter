import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_colors.dart';
import '../../features/words/controllers/study_controller.dart';
import '../../features/words/models/word_model.dart';

void showWordDetailModal(
  BuildContext context, {
  required WordModel word,
  List<WordModel> allWords = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => WordDetailBottomSheet(
      word: word,
      allWords: allWords,
    ),
  );
}

class WordDetailBottomSheet extends StatefulWidget {
  final WordModel word;
  final List<WordModel> allWords;

  const WordDetailBottomSheet({
    super.key,
    required this.word,
    this.allWords = const [],
  });

  @override
  State<WordDetailBottomSheet> createState() => _WordDetailBottomSheetState();
}

class _WordDetailBottomSheetState extends State<WordDetailBottomSheet> {
  late WordModel _currentWord;
  final FlutterTts _tts = FlutterTts();
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _currentWord = widget.word;
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
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

  Future<void> _speak() async {
    if (_isPlayingTts) {
      await _tts.stop();
      if (mounted) setState(() => _isPlayingTts = false);
      return;
    }
    try {
      setState(() => _isPlayingTts = true);
      HapticFeedback.lightImpact();
      await _tts.stop();

      // Auto-reset fallback
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isPlayingTts) {
          setState(() => _isPlayingTts = false);
        }
      });

      await _tts.speak(_currentWord.en);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isPlayingTts = false);
      }
    }
  }

  List<SynonymBadgeItem> _computeSynonyms(WordModel targetWord) {
    if (widget.allWords.isEmpty) return [];

    final currentEn = targetWord.en.toLowerCase().trim();
    final atomicMeanings = targetWord.tr
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (atomicMeanings.isEmpty && targetWord.tr.trim().isNotEmpty) {
      atomicMeanings.add(targetWord.tr.trim().toLowerCase());
    }

    final result = <SynonymBadgeItem>[];
    final seenWordIds = <dynamic>{};

    for (int i = 0; i < atomicMeanings.length; i++) {
      final meaning = atomicMeanings[i];
      final gradient = StudyController.synonymGradients[
          i % StudyController.synonymGradients.length];

      for (final w in widget.allWords) {
        final wEn = w.en.toLowerCase().trim();
        if (wEn == currentEn) continue;

        final wMeanings = w.tr
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList();

        final matches = wMeanings.any(
          (wm) => wm == meaning || wm.contains(meaning) || meaning.contains(wm),
        );

        if (matches) {
          final wordKey = w.id ?? '${w.en}_${w.tr}';
          if (!seenWordIds.contains(wordKey)) {
            seenWordIds.add(wordKey);
            result.add(
              SynonymBadgeItem(
                word: w,
                matchedMeaning: meaning,
                gradient: gradient,
              ),
            );
          }
        }
      }
    }

    return result;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final synonyms = _computeSynonyms(_currentWord);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row with TTS & Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentWord.listName != null &&
                            _currentWord.listName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _currentWord.listName!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.turquoise,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // English Word & Audio Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _currentWord.en,
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
                        InkWell(
                          onTap: _speak,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlayingTts
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded,
                              size: 20,
                              color: AppColors.turquoise,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Turkish Meaning
                    Text(
                      _currentWord.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF6C6C70),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Example Sentence Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E5EA),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ÖRNEK KULLANIM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            (_currentWord.example != null &&
                                    _currentWord.example!.trim().isNotEmpty)
                                ? _currentWord.example!
                                : 'Bu kelime için örnek cümle eklenmemiş.',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                              color: (_currentWord.example != null &&
                                      _currentWord.example!.trim().isNotEmpty)
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : Colors.black87)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (synonyms.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 16, color: AppColors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'EŞ ANLAMLILAR (SYNONYMS)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: synonyms.map((badge) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: badge.gradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      badge.gradient.first.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _currentWord = badge.word;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  child: Text(
                                    badge.word.en,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
