import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/quiz_controller.dart';

class ActiveQuizView extends ConsumerWidget {
  final QuizState quizState;
  final QuizController quizNotifier;

  const ActiveQuizView({
    super.key,
    required this.quizState,
    required this.quizNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = quizState.currentQuestion!;
    final index = quizState.currentIndex;
    final total = quizState.totalQuestions;
    final progress = (index + 1) / total;
    final isPlayingTts = ref.watch(ttsServiceProvider).isPlaying;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(ttsServiceProvider).stop();
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
                const Icon(Icons.check_circle_outline_rounded,
                    size: 17, color: AppColors.turquoise),
                const SizedBox(width: 4),
                Text(
                  '${quizState.correctCount} / $total Doğru',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Linear Progress Bar & Counter (Top)
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
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
                          const SizedBox(height: 16),

                          // 2. Question Big Card with Centered Word and Larger Pronunciation Button Below
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 30),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  question.questionText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Centered, larger pronunciation (TTS) button
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ref
                                        .read(ttsServiceProvider)
                                        .speak(question.word.en);
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: isPlayingTts
                                          ? AppColors.turquoise.withValues(alpha: 0.22)
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isPlayingTts
                                            ? AppColors.turquoise
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                        width: 1.6,
                                      ),
                                      boxShadow: [
                                        if (isPlayingTts)
                                          BoxShadow(
                                            color: AppColors.turquoise.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isPlayingTts
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_up_outlined,
                                        color: isPlayingTts
                                            ? AppColors.turquoise
                                            : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Spacer pushes the option buttons to the bottom of the viewport
                          const Spacer(),
                          const SizedBox(height: 16),

                          // 3. Options List (A, B, C, D)
                          ...List.generate(question.options.length, (optIdx) {
                            final option = question.options[optIdx];
                            final optionLetter =
                                String.fromCharCode(65 + optIdx);
                            final isSelected =
                                quizState.selectedAnswer == option;
                            final isCorrect =
                                option == question.correctAnswer;

                            Color cardColor = isDark
                                ? AppColors.darkSurface
                                : Colors.white;
                            Color borderColor = isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder;
                            Color textColor = isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary;
                            IconData? statusIcon;

                            if (quizState.isAnswered) {
                              if (isCorrect) {
                                cardColor = AppColors.success
                                    .withValues(alpha: 0.15);
                                borderColor = AppColors.success;
                                textColor = AppColors.success;
                                statusIcon = Icons.check_circle_rounded;
                              } else if (isSelected) {
                                cardColor =
                                    AppColors.error.withValues(alpha: 0.15);
                                borderColor = AppColors.error;
                                textColor = AppColors.error;
                                statusIcon = Icons.cancel_rounded;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: quizState.isAnswered
                                    ? null
                                    : () {
                                        quizNotifier.selectAnswer(option);
                                      },
                                borderRadius: BorderRadius.circular(18),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: borderColor,
                                      width: (isSelected ||
                                              (quizState.isAnswered &&
                                                  isCorrect))
                                          ? 2
                                          : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
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
                                          color: (quizState.isAnswered &&
                                                  isCorrect)
                                              ? AppColors.success
                                              : (quizState.isAnswered &&
                                                      isSelected)
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
                                                      (isCorrect ||
                                                          isSelected))
                                                  ? Colors.white
                                                  : (isDark
                                                      ? AppColors
                                                          .darkTextPrimary
                                                      : AppColors
                                                          .lightTextPrimary),
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
                                        Icon(statusIcon,
                                            color: borderColor, size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
