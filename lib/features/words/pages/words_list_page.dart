import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/offline_status_badge.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../controllers/word_list_controller.dart';
import '../models/list_sort_order.dart';
import '../widgets/word_list_card.dart';
import '../widgets/word_list_dialogs.dart';

class WordsListPage extends ConsumerStatefulWidget {
  const WordsListPage({super.key});

  @override
  ConsumerState<WordsListPage> createState() => _WordsListPageState();
}

class _WordsListPageState extends ConsumerState<WordsListPage> {
  bool _isNavigating = false;

  // Gradient pairs matching Swift HomeTVC
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
      if (ref.read(wordListControllerProvider).words.isEmpty) {
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      }
    });
  }

  void _openListStudy(String listName) {
    if (_isNavigating) return;
    _isNavigating = true;

    HapticFeedback.mediumImpact();

    final wordListState = ref.read(wordListControllerProvider);
    final listWords = wordListState.words
        .where((w) => w.listName == listName)
        .toList();

    context.push(AppRoutes.wordsStudy, extra: {
      'sessionId': 'words_list_study_$listName',
      'words': listWords,
      'listTitle': listName,
    }).then((_) {
      if (mounted) {
        ref.read(wordListControllerProvider.notifier).refresh();
        setState(() {
          _isNavigating = false;
        });
      }
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
                        const OfflineStatusBadge(),
                        Text(
                          'My Lists',
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
                          '${wordListState.listNames.length} word lists available',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Sort & Reorder Menu Button
                        _buildSortMenuButton(isDark),
                        const SizedBox(width: 10),

                        // + Add List Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => WordListDialogs.showAddListDialog(
                              context,
                              ref,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.turquoiseGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.turquoise
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
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
                  child: wordListState.isLoading &&
                          wordListState.listNames.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.turquoise,
                            ),
                          ),
                        )
                      : wordListState.errorMessage != null &&
                              wordListState.listNames.isEmpty
                          ? NetworkErrorView(
                              message: wordListState.errorMessage,
                              onRetry: wordListNotifier.refresh,
                            )
                          : wordListState.listNames.isEmpty
                              ? _buildEmptyState(isDark)
                              : ReorderableListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                  itemCount: wordListState.listNames.length,
                                  buildDefaultDragHandles: false,
                                  // ignore: deprecated_member_use
                                  onReorder: (oldIndex, newIndex) {
                                    ref
                                        .read(
                                            wordListControllerProvider.notifier)
                                        .reorderLists(oldIndex, newIndex);
                                  },
                                  proxyDecorator: (child, index, animation) {
                                    return AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, child) {
                                        final animValue = Curves.easeInOut
                                            .transform(animation.value);
                                        final elevation =
                                            lerpDouble(0, 10, animValue)!;
                                        final scale =
                                            lerpDouble(1, 1.02, animValue)!;
                                        return Transform.scale(
                                          scale: scale,
                                          child: Material(
                                            elevation: elevation,
                                            color: Colors.transparent,
                                            shadowColor: Colors.black
                                                .withValues(alpha: 0.35),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: child,
                                    );
                                  },
                                  itemBuilder: (context, index) {
                                    final listName =
                                        wordListState.listNames[index];
                                    final gradient = _listGradients[
                                        index % _listGradients.length];
                                    final wordCount = wordListState
                                            .wordCountsByList[listName] ??
                                        0;

                                    return Padding(
                                      key: ValueKey(listName),
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: ReorderableDelayedDragStartListener(
                                        index: index,
                                        child: WordListCard(
                                          index: index,
                                          listName: listName,
                                          wordCount: wordCount,
                                          gradient: gradient,
                                          onTap: () =>
                                              _openListStudy(listName),
                                          onRename: () =>
                                              WordListDialogs.showRenameDialog(
                                            context,
                                            ref,
                                            listName,
                                          ),
                                          onDelete: () =>
                                              WordListDialogs.showDeleteDialog(
                                            context,
                                            ref,
                                            listName,
                                          ),
                                        ),
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

  Widget _buildSortMenuButton(bool isDark) {
    return PopupMenuButton<ListSortOrder>(
      tooltip: 'Sırala / Düzenle',
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardElevated : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.swap_vert_rounded,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          size: 24,
        ),
      ),
      color: isDark ? AppColors.darkCardElevated : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? const BorderSide(color: AppColors.darkBorder, width: 0.8)
            : BorderSide.none,
      ),
      onSelected: (order) {
        ref.read(wordListControllerProvider.notifier).sortLists(order);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            'LİSTE SIRALAMASI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ListSortOrder.alphabeticalAsc,
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha_rounded, size: 20),
              const SizedBox(width: 10),
              Text(ListSortOrder.alphabeticalAsc.label),
            ],
          ),
        ),
        PopupMenuItem(
          value: ListSortOrder.alphabeticalDesc,
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha_rounded, size: 20),
              const SizedBox(width: 10),
              Text(ListSortOrder.alphabeticalDesc.label),
            ],
          ),
        ),
        PopupMenuItem(
          value: ListSortOrder.wordCountDesc,
          child: Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 20),
              const SizedBox(width: 10),
              Text(ListSortOrder.wordCountDesc.label),
            ],
          ),
        ),
        PopupMenuItem(
          value: ListSortOrder.wordCountAsc,
          child: Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 20),
              const SizedBox(width: 10),
              Text(ListSortOrder.wordCountAsc.label),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ListSortOrder.reset,
          child: Row(
            children: [
              const Icon(Icons.refresh_rounded, size: 20, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                ListSortOrder.reset.label,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
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
                    'No Word Lists',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first word list by tapping the + button or pull down to refresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Yeni Liste Oluştur',
                    prefixIcon: Icons.add_rounded,
                    variant: ButtonVariant.primary,
                    onPressed: () => WordListDialogs.showAddListDialog(
                      context,
                      ref,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
