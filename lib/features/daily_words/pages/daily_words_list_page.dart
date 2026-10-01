import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/widgets/word_list_card.dart';

class DailyWordsListPage extends ConsumerStatefulWidget {
  const DailyWordsListPage({super.key});

  @override
  ConsumerState<DailyWordsListPage> createState() => _DailyWordsListPageState();
}

class _DailyWordsListPageState extends ConsumerState<DailyWordsListPage> {
  static const List<List<Color>> _listGradients = [
    [Color(0xFFFF2D55), Color(0xFFAF52DE)], // Pink -> Purple
    [Color(0xFF007AFF), Color(0xFF5AC8FA)], // Blue -> Teal
    [Color(0xFF34C759), Color(0xFF00C7BE)], // Green -> Mint
    [Color(0xFFFF9500), Color(0xFFFF3B30)], // Orange -> Red
    [Color(0xFF5856D6), Color(0xFFAF52DE)], // Indigo -> Purple
    [Color(0xFF00C7BE), Color(0xFF30B0C7)], // Mint -> Cyan
    [Color(0xFF6B7280), Color(0xFF374151)], // Slate
    [Color(0xFFD946EF), Color(0xFF8B5CF6)], // Fuchsia -> Violet
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(wordListControllerProvider);
      if (state.words.isEmpty && !state.isLoading) {
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      }
    });
  }

  void _openListDailyWords(String listName) {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.dailyWordsStudy, extra: {
      'listName': listName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordListState = ref.watch(wordListControllerProvider);
    final wordListNotifier = ref.read(wordListControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: isDesktop ? 900 : 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Günlük Kelimeler',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Çalışmak istediğiniz listeyi seçin',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Content Area
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.turquoise,
                  onRefresh: wordListNotifier.refresh,
                  child: wordListState.isLoading && wordListState.listNames.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.turquoise,
                            ),
                          ),
                        )
                      : wordListState.errorMessage != null && wordListState.listNames.isEmpty
                          ? NetworkErrorView(
                              message: wordListState.errorMessage,
                              onRetry: wordListNotifier.refresh,
                            )
                          : wordListState.listNames.isEmpty
                              ? _buildEmptyState(isDark)
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                  itemCount: wordListState.listNames.length,
                                  itemBuilder: (context, index) {
                                    final listName = wordListState.listNames[index];
                                    final gradient = _listGradients[index % _listGradients.length];
                                    final wordCount = wordListState.wordCountsByList[listName] ?? 0;

                                    return Padding(
                                      key: ValueKey(listName),
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: WordListCard(
                                        index: index,
                                        listName: listName,
                                        wordCount: wordCount,
                                        gradient: gradient,
                                        onTap: () => _openListDailyWords(listName),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.turquoise.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: AppColors.turquoise,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Kelime Listesi Yok',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Günlük kelime çalışmak için önce "My Lists" sekmesinden yeni bir kelime listesi oluşturmalısınız.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
