import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import '../auth/pages/login_page.dart';
import '../profile/pages/profile_page.dart';
import '../quiz/pages/daily_plan_page.dart';
import '../quiz/pages/quiz_page.dart';
import '../words/controllers/word_list_controller.dart';
import '../words/pages/synonyms_page.dart';
import '../words/pages/words_list_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage>
    with WidgetsBindingObserver {
  late int _currentIndex;
  final GlobalKey<NavigatorState> _myListsNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(wordListControllerProvider.notifier).refresh();
      ref.invalidate(synonymGroupsFutureProvider);
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index && index == 0) {
      // Sadece aynı sekmeye (My Lists) tekrar tıklandığında kök sayfaya dön
      _myListsNavKey.currentState?.popUntil((route) => route.isFirst);
    } else if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth session expiration / 401 unauthorized
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated && mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    const activeColor = Color(0xFF28CD41); // iOS System Green from Swift app
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999);

    final content = IndexedStack(
      index: _currentIndex,
      children: [
        Navigator(
          key: _myListsNavKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const WordsListPage(),
            );
          },
        ),
        const SynonymsPage(),
        const QuizPage(),
        const DailyPlanPage(),
        const ProfilePage(),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex == 0 &&
            _myListsNavKey.currentState != null &&
            _myListsNavKey.currentState!.canPop()) {
          _myListsNavKey.currentState!.pop();
          return;
        }
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  _buildDesktopSidebar(isDark, activeColor, inactiveColor),
                  Expanded(child: content),
                ],
              )
            : content,
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                          index: 0,
                          icon: Icons.format_list_bulleted_rounded,
                          label: 'My Lists',
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 1,
                          icon: Icons.filter_none_rounded,
                          label: 'Synonyms',
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 2,
                          icon: Icons.help_outline_rounded,
                          label: 'Quiz',
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 3,
                          icon: Icons.bolt_rounded,
                          label: 'Plan',
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildTabItem(
                          index: 4,
                          icon: Icons.account_circle_outlined,
                          label: 'Profile',
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    bool isDark,
    Color activeColor,
    Color inactiveColor,
  ) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF9F9FB),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.turquoiseGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.turquoise.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Word Station',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 16),

            // Sidebar Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'My Lists',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.filter_none_rounded,
                    label: 'Synonyms',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.help_outline_rounded,
                    label: 'Quiz',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.bolt_rounded,
                    label: 'Plan',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildSidebarItem(
                    index: 4,
                    icon: Icons.account_circle_outlined,
                    label: 'Profile',
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom subtle branding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.0 (macOS)',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? activeColor.withValues(alpha: 0.15)
                    : activeColor.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
