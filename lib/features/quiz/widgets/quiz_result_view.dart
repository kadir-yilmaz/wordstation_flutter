import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../../words/models/word_model.dart';
import '../controllers/quiz_controller.dart';
import '../models/quiz_history_model.dart';

class QuizResultView extends ConsumerWidget {
  final QuizState quizState;
  final QuizController quizNotifier;
  final List<WordModel> allWords;

  const QuizResultView({
    super.key,
    required this.quizState,
    required this.quizNotifier,
    required this.allWords,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = quizState.percentage;
    final isSuccess = percentage >= 70;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => quizNotifier.resetToSetup(),
        ),
        title: const Text('Test Sonucu',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trophy / Medal Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: isSuccess
                            ? AppColors.turquoiseGradient
                            : AppColors.orangeGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isSuccess
                                    ? AppColors.turquoise
                                    : AppColors.orange)
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSuccess
                            ? Icons.emoji_events_rounded
                            : Icons.military_tech_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isSuccess ? 'Tebrikler! Harika İş!' : 'Test Tamamlandı!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSuccess
                        ? 'Kelimeleri başarıyla pekiştirdin.'
                        : 'Aşağıdaki kelimeleri inceleyerek eksiklerini tamamlayabilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Score Card Row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Doğru Sayısı', '${quizState.correctCount} / ${quizState.totalQuestions}',
                            AppColors.turquoise, isDark),
                        Container(
                            width: 1,
                            height: 36,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        _buildStatCol(
                            'Başarı Oranı',
                            '%$percentage',
                            isSuccess ? AppColors.success : AppColors.orange,
                            isDark),
                        Container(
                            width: 1,
                            height: 36,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        _buildStatCol(
                            'Yanlış Sayısı',
                            '${quizState.wrongCount} Yanlış',
                            isDark ? Colors.white70 : Colors.black87,
                            isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detailed Questions Breakdown Header
                  Text(
                    'SORU DETAYLARI & KELİMELER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List of all question results
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quizState.results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, qIdx) {
                      final resultItem = quizState.results[qIdx];
                      return _buildQuestionResultCard(
                        context,
                        resultItem,
                        qIdx + 1,
                        isDark,
                        allWords,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(
      String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionResultCard(
    BuildContext context,
    QuizQuestionResult item,
    int index,
    bool isDark,
    List<WordModel> allWords,
  ) {
    final statusColor = item.isCorrect ? AppColors.success : AppColors.error;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showWordDetailModal(
          context,
          word: item.word,
          allWords: allWords,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$index. ${item.word.en}',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${item.word.tr})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!item.isCorrect) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Sizin Cevabınız: '),
                          TextSpan(
                            text: item.selectedAnswer,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }
}
