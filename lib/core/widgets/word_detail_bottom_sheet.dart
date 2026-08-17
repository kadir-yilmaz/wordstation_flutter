import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_colors.dart';
import '../../features/words/models/word_model.dart';

Future<void> showWordDetailModal(
  BuildContext context, {
  required WordModel word,
  List<WordModel> allWords = const [],
}) async {
  HapticFeedback.mediumImpact();
  FocusManager.instance.primaryFocus?.unfocus();
  FocusScope.of(context).unfocus();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => WordDetailBottomSheet(
      word: word,
      isDark: isDark,
    ),
  );

  FocusManager.instance.primaryFocus?.unfocus();
}

class WordDetailBottomSheet extends StatefulWidget {
  final WordModel word;
  final bool isDark;

  const WordDetailBottomSheet({
    super.key,
    required this.word,
    required this.isDark,
  });

  @override
  State<WordDetailBottomSheet> createState() => _WordDetailBottomSheetState();
}

class _WordDetailBottomSheetState extends State<WordDetailBottomSheet> {
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);

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
      if (mounted) setState(() => _isPlayingTts = true);
      HapticFeedback.lightImpact();
      await _tts.stop();

      // Auto-reset fallback
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _isPlayingTts) {
          setState(() => _isPlayingTts = false);
        }
      });

      await _tts.speak(widget.word.en);
    } catch (_) {
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final hasExample = widget.word.example != null &&
        widget.word.example!.trim().isNotEmpty;

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
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable Content Area (Ensures long examples never overflow)
            Flexible(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: false,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // List Tag Badge (if available)
                      if (widget.word.listName != null &&
                          widget.word.listName!.isNotEmpty &&
                          widget.word.listName != 'General') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.turquoise.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.word.listName!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.turquoise,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // English Word + Speaker Icon Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.word.en,
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
                            icon: Icon(
                              _isPlayingTts
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded,
                              size: 26,
                              color: const Color(0xFF007AFF), // iOS Accent Blue
                            ),
                            onPressed: _speak,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Turkish Meaning
                      Text(
                        widget.word.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E5EA),
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Example Sentence with SelectableText
                      SelectableText(
                        hasExample
                            ? widget.word.example!
                            : 'Bu kelime için örnek cümle eklenmemiş.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.0,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: hasExample
                              ? (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary)
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF8E8E93)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
