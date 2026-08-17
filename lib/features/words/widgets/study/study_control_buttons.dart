import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StudyControlButtons extends StatelessWidget {
  final bool isDark;
  final bool hasWords;
  final bool hasPrev;
  final bool hasNext;
  final bool isPlayingTts;
  final VoidCallback onPrev;
  final VoidCallback onRandom;
  final VoidCallback onTts;
  final VoidCallback onNext;

  const StudyControlButtons({
    super.key,
    required this.isDark,
    required this.hasWords,
    required this.hasPrev,
    required this.hasNext,
    required this.isPlayingTts,
    required this.onPrev,
    required this.onRandom,
    required this.onTts,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // [ ← Prev ]
        Expanded(
          child: StudyActionButton(
            text: '← Prev',
            backgroundColor:
                isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
            textColor: isDark ? Colors.white : Colors.black,
            isEnabled: hasPrev,
            onTap: onPrev,
          ),
        ),
        const SizedBox(width: 10),

        // [ Random ] (Vibrant Orange)
        Expanded(
          child: StudyActionButton(
            text: 'Random',
            backgroundColor: const Color(0xFFFF9500),
            textColor: Colors.white,
            isBold: true,
            isEnabled: hasWords,
            onTap: onRandom,
          ),
        ),
        const SizedBox(width: 10),

        // [ 🔊 ] (Vibrant Blue Speaker)
        Expanded(
          child: StudyActionButton(
            icon: isPlayingTts
                ? Icons.graphic_eq_rounded
                : Icons.volume_up_rounded,
            backgroundColor: const Color(0xFF007AFF),
            textColor: Colors.white,
            isEnabled: hasWords,
            onTap: onTts,
          ),
        ),
        const SizedBox(width: 10),

        // [ Next → ]
        Expanded(
          child: StudyActionButton(
            text: 'Next →',
            backgroundColor:
                isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
            textColor: isDark ? Colors.white : Colors.black,
            isEnabled: hasNext,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

class StudyActionButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final bool isBold;
  final bool isEnabled;
  final VoidCallback onTap;

  const StudyActionButton({
    super.key,
    this.text,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.isBold = false,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1.0 : 0.35,
      child: SizedBox(
        height: 52,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            canRequestFocus: false,
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
