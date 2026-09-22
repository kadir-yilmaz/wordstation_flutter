import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../words/models/word_model.dart';
import '../../controllers/quiz_controller.dart';
import '../../models/daily_quiz_plan_model.dart';
import 'daily_plan_action_card.dart';
import 'daily_plan_streak_card.dart';

class DailyPlanDashboard extends StatelessWidget {
  final DailyQuizPlanModel plan;
  final QuizState quizState;
  final QuizController quizNotifier;
  final List<WordModel> allWords;
  final bool isDark;
  final VoidCallback onDeletePlan;

  const DailyPlanDashboard({
    super.key,
    required this.plan,
    required this.quizState,
    required this.quizNotifier,
    required this.allWords,
    required this.isDark,
    required this.onDeletePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DailyPlanStreakCard(
          plan: plan,
          onTap: () => context.push(AppRoutes.planHistory),
        ),
        const SizedBox(height: 20),
        DailyPlanActionCards(
          plan: plan,
          quizState: quizState,
          quizNotifier: quizNotifier,
          allWords: allWords,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: AppColors.error,
            ),
            label: const Text(
              'Planı Sil',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: onDeletePlan,
          ),
        ),
      ],
    );
  }
}
