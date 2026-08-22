import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../navigation/main_navigation_page.dart';
import '../../quiz/controllers/quiz_controller.dart';
import '../../words/controllers/word_list_controller.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

/// [AuthGate] replaces the legacy delayed SplashPage.
/// It performs an instant auth status check without artificial delays or redundant branding,
/// routing the user seamlessly to MainNavigationPage or LoginPage.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Yapay bekleme olmadan anında oturum kontrolü başlatılır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Giriş Yapılmış -> Verileri yükle ve anında Ana Sayfayı göster
    if (authState.isAuthenticated) {
      ref.read(wordListControllerProvider.notifier).loadInitialData();
      ref.read(quizControllerProvider.notifier).loadInitialData();
      return const MainNavigationPage();
    }

    // 2. Giriş Yapılmamış / Hata -> Anında Giriş Sayfasını göster
    if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.error) {
      return const LoginPage();
    }

    // 3. İlk Milisaniyeler (Token okunurken) -> Doğal tema arka planı
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: const SizedBox.shrink(),
    );
  }
}

// Geriye dönük uyumluluk için alias
typedef SplashPage = AuthGate;

