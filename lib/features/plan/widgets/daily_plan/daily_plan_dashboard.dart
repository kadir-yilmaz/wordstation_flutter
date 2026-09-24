import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../quiz/controllers/quiz_controller.dart';
import '../../../words/models/word_model.dart';
import '../../controllers/plan_controller.dart';
import '../../models/daily_quiz_plan_model.dart';
import 'daily_plan_action_card.dart';
import 'daily_plan_streak_card.dart';

class DailyPlanDashboard extends StatelessWidget {
  final DailyQuizPlanModel plan;
  final PlanState planState;
  final PlanController planNotifier;
  final QuizController quizNotifier;
  final List<WordModel> allWords;
  final bool isDark;

  const DailyPlanDashboard({
    super.key,
    required this.plan,
    required this.planState,
    required this.planNotifier,
    required this.quizNotifier,
    required this.allWords,
    required this.isDark,
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
          planState: planState,
          planNotifier: planNotifier,
          quizNotifier: quizNotifier,
          allWords: allWords,
          isDark: isDark,
        ),
      ],
    );
  }
}
