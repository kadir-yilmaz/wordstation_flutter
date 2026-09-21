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

/// Merkezi GoRouter provider'ı.
/// Auth durumunu dinler ve otomatik yönlendirme yapar.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/words',
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
          currentLocation == '/login' || currentLocation == '/register';

      // Giriş yapmamış ve auth sayfasında değil → login'e gönder
      if (!isAuthenticated && !isOnAuthRoute) return '/login';

      // Giriş yapmış ama auth sayfasında → ana sayfaya gönder
      if (isAuthenticated && isOnAuthRoute) return '/words';

      return null;
    },

    // ─── Route Tanımları ────────────────────────────────
    routes: [
      // Auth Routes (shell dışında)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Ana uygulama — StatefulShellRoute ile bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: My Lists (Words)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/words',
                builder: (context, state) => const WordsListPage(),
              ),
            ],
          ),
          // Tab 1: Synonyms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/synonyms',
                builder: (context, state) => const SynonymsPage(),
              ),
            ],
          ),
          // Tab 2: Quiz
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quiz',
                builder: (context, state) => const QuizPage(),
              ),
            ],
          ),
          // Tab 3: Daily Plan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const DailyPlanPage(),
              ),
            ],
          ),
          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ─── Full-Screen Overlay Routes ───────────────────
      // StudySessionPage — karmaşık nesne geçişi, extra ile
      GoRoute(
        path: '/study',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return StudySessionPage(
            words: (extra['words'] as List<WordModel>?) ?? [],
            initialIndex: (extra['initialIndex'] as int?) ?? 0,
            listTitle: extra['listTitle'] as String?,
            showSearchBar: (extra['showSearchBar'] as bool?) ?? true,
            isReadOnly: (extra['isReadOnly'] as bool?) ?? false,
          );
        },
      ),

      // AddEditWordPage — nesne geçişi + pop result
      GoRoute(
        path: '/add-word',
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
        path: '/quiz-history',
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
        path: '/token-inspector',
        builder: (context, state) => const TokenInspectorPage(),
      ),
    ],
  );
});
