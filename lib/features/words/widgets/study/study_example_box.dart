import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/word_model.dart';

class StudyExampleBox extends StatelessWidget {
  final bool isDark;
  final bool hasWords;
  final WordModel? currentWord;
  final ScrollController scrollController;

  const StudyExampleBox({
    super.key,
    required this.isDark,
    required this.hasWords,
    required this.currentWord,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final hasExample = hasWords &&
        currentWord?.example != null &&
        currentWord!.example!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
          width: 1.5,
        ),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SelectableText(
              hasWords
                  ? (hasExample
                      ? currentWord!.example!
                      : 'No example sentence available.')
                  : 'Aradığınız kelime bulunamadı.',
              textAlign: hasExample ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.55,
                color: hasExample
                    ? (isDark ? AppColors.darkTextPrimary : Colors.black87)
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
}
