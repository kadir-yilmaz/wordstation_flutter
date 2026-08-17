import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StudyIndexLabel extends StatelessWidget {
  final bool isDark;
  final bool hasWords;
  final int currentIndex;
  final int totalCount;

  const StudyIndexLabel({
    super.key,
    required this.isDark,
    required this.hasWords,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
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
}

class StudyProgressSlider extends StatelessWidget {
  final bool isDark;
  final bool hasWords;
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onSeek;

  const StudyProgressSlider({
    super.key,
    required this.isDark,
    required this.hasWords,
    required this.currentIndex,
    required this.totalCount,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: SliderTheme(
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
                  onSeek(val.round());
                }
              : null,
        ),
      ),
    );
  }
}
