import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

/// [AuthGate] artık yalnızca ilk auth kontrolü sırasında
/// gösterilecek minimal bir loading ekranıdır.
/// Route kararları go_router'ın redirect mekanizması tarafından yapılır.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // İlk milisaniyeler (Token okunurken) → Doğal tema arka planı
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: const SizedBox.shrink(),
    );
  }
}

// Geriye dönük uyumluluk için alias
typedef SplashPage = AuthGate;
