import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/navigation/main_navigation_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/profile/pages/token_inspector_page.dart';
import '../../features/quiz/pages/daily_plan_page.dart';
import '../../features/quiz/pages/quiz_history_page.dart';
import '../../features/quiz/pages/quiz_page.dart';
import '../../features/words/pages/add_edit_word_page.dart';
import '../../features/words/pages/study_session_page.dart';
import '../../features/words/pages/synonyms_page.dart';
import '../../features/words/pages/words_list_page.dart';
import '../../features/words/models/word_model.dart';
import 'app_routes.dart';

/// Sekme navigator anahtarları
final wordsNavKey = GlobalKey<NavigatorState>(debugLabel: 'wordsNav');
final synonymsNavKey = GlobalKey<NavigatorState>(debugLabel: 'synonymsNav');
final quizNavKey = GlobalKey<NavigatorState>(debugLabel: 'quizNav');
final planNavKey = GlobalKey<NavigatorState>(debugLabel: 'planNav');
final profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profileNav');

final branchNavKeys = [
  wordsNavKey,
  synonymsNavKey,
  quizNavKey,
  planNavKey,
  profileNavKey,
];

Widget _buildStudySessionPage(GoRouterState state) {
  final extra = state.extra as Map<String, dynamic>? ?? {};
  return StudySessionPage(
    words: (extra['words'] as List<WordModel>?) ?? [],
    initialIndex: (extra['initialIndex'] as int?) ?? 0,
    listTitle: extra['listTitle'] as String?,
    showSearchBar: (extra['showSearchBar'] as bool?) ?? true,
    isReadOnly: (extra['isReadOnly'] as bool?) ?? false,
  );
}

/// Merkezi GoRouter provider'ı.
/// Auth durumunu dinler ve otomatik yönlendirme yapar.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.words,
    debugLogDiagnostics: false,

    // ─── Auth Guard ─────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final currentLocation = state.matchedLocation;

      // Auth kontrolü devam ediyorsa yönlendirme yapma
      if (isLoading) return null;

      final isOnAuthRoute =
          currentLocation == AppRoutes.login || currentLocation == AppRoutes.register;

      // Giriş yapmamış ve auth sayfasında değil → login'e gönder
      if (!isAuthenticated && !isOnAuthRoute) return AppRoutes.login;

      // Giriş yapmış ama auth sayfasında → ana sayfaya gönder
      if (isAuthenticated && isOnAuthRoute) return AppRoutes.words;

      return null;
    },

    // ─── Route Tanımları ────────────────────────────────
    routes: [
      // Auth Routes (shell dışında)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // Ana uygulama — StatefulShellRoute ile bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(
            navigationShell: navigationShell,
            branchNavKeys: branchNavKeys,
          );
        },
        branches: [
          // Tab 0: My Lists (Words)
          StatefulShellBranch(
            navigatorKey: wordsNavKey,
            routes: [
              GoRoute(
                path: AppRoutes.words,
                builder: (context, state) => const WordsListPage(),
                routes: [
                  GoRoute(
                    path: 'study',
                    builder: (context, state) => _buildStudySessionPage(state),
                  ),
                ],
              ),
              // Geriye dönük uyumluluk: doğrudan /study çağrılırsa da Tab 0 içinde tabbar ile açılır
              GoRoute(
                path: AppRoutes.study,
                builder: (context, state) => _buildStudySessionPage(state),
              ),
            ],
          ),
          // Tab 1: Synonyms
          StatefulShellBranch(
            navigatorKey: synonymsNavKey,
            routes: [
              GoRoute(
                path: AppRoutes.synonyms,
                builder: (context, state) => const SynonymsPage(),
                routes: [
                  GoRoute(
                    path: 'study',
                    builder: (context, state) => _buildStudySessionPage(state),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Quiz
          StatefulShellBranch(
            navigatorKey: quizNavKey,
            routes: [
              GoRoute(
                path: AppRoutes.quiz,
                builder: (context, state) => const QuizPage(),
                routes: [
                  GoRoute(
                    path: 'study',
                    builder: (context, state) => _buildStudySessionPage(state),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>? ?? {};
                      return QuizHistoryPage(
                        isDailyQuiz: (extra['isDailyQuiz'] as bool?) ?? false,
                        title: (extra['title'] as String?) ?? 'Test Geçmişi',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Daily Plan
          StatefulShellBranch(
            navigatorKey: planNavKey,
            routes: [
              GoRoute(
                path: AppRoutes.plan,
                builder: (context, state) => const DailyPlanPage(),
                routes: [
                  GoRoute(
                    path: 'study',
                    builder: (context, state) => _buildStudySessionPage(state),
                  ),
                ],
              ),
            ],
          ),
          // Tab 4: Profile
          StatefulShellBranch(
            navigatorKey: profileNavKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ─── Full-Screen Overlay Routes ───────────────────
      // AddEditWordPage — nesne geçişi + pop result
      GoRoute(
        path: AppRoutes.addWord,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AddEditWordPage(
            wordToEdit: extra['wordToEdit'] as WordModel?,
            initialListName: extra['initialListName'] as String?,
          );
        },
      ),

      // QuizHistoryPage
      GoRoute(
        path: AppRoutes.quizHistory,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuizHistoryPage(
            isDailyQuiz: (extra['isDailyQuiz'] as bool?) ?? false,
            title: (extra['title'] as String?) ?? 'Test Geçmişi',
          );
        },
      ),

      // TokenInspectorPage
      GoRoute(
        path: AppRoutes.tokenInspector,
        builder: (context, state) => const TokenInspectorPage(),
      ),
    ],
  );
});
