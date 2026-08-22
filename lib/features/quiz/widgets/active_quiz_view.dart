import 'package:flutter/material.dart';
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

                          // 2. Question Big Card with TTS Audio Speaker
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
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
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCardElevated
                                            : const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        quizState.isEnglishToTurkish
                                            ? 'İngilizce ➔ Türkçe'
                                            : 'Türkçe ➔ İngilizce',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Audio TTS Pronunciation Icon
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        isPlayingTts
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_up_outlined,
                                        color: isPlayingTts
                                            ? AppColors.turquoise
                                            : (isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary),
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(ttsServiceProvider)
                                            .speak(question.word.en);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  question.questionText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

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
