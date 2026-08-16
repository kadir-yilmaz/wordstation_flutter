import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../controllers/word_list_controller.dart';
import '../models/synonym_group_model.dart';
import '../services/word_service.dart';

final synonymGroupsFutureProvider =
    FutureProvider.autoDispose<List<SynonymGroupModel>>((ref) async {
  final service = ref.watch(wordServiceProvider);
  return await service.getSynonymGroups();
});

class SynonymsPage extends ConsumerStatefulWidget {
  const SynonymsPage({super.key});

  @override
  ConsumerState<SynonymsPage> createState() => _SynonymsPageState();
}

class _SynonymsPageState extends ConsumerState<SynonymsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(synonymGroupsFutureProvider);
    final wordListState = ref.watch(wordListControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final groupCountSubtitle = groupsAsync.maybeWhen(
      data: (groups) {
        final count = groups.where((g) {
          if (_searchQuery.isEmpty) return true;
          return g.turkishMeaning.toLowerCase().trim().startsWith(_searchQuery);
        }).length;
        return '$count eş anlamlı grup';
      },
      orElse: () => 'Eş anlamlı kelime grupları',
    );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ResponsiveContent(
            maxWidth: 800,
            child: Column(
            children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eş Anlamlılar',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        groupCountSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

            // Search Bar (Sadece Türkçe Prefix Arama)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Türkçe eş anlamlı ara (örn: ça)...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: groupsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 44, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Eş anlamlılar yüklenemedi: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(synonymGroupsFutureProvider),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (groups) {
                  final filteredGroups = groups.where((g) {
                    if (_searchQuery.isEmpty) return true;
                    return g.turkishMeaning
                        .toLowerCase()
                        .trim()
                        .startsWith(_searchQuery);
                  }).toList();

                  if (filteredGroups.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: _searchQuery.isEmpty
                          ? 'Eş Anlamlı Grup Yok'
                          : 'Sonuç Bulunamadı',
                      description: _searchQuery.isEmpty
                          ? 'Aynı Türkçe anlama sahip en az 2 kelime eklendiğinde burada gruplanacaktır.'
                          : 'Aradığınız kelimeye veya anlama uygun eş anlamlı grup bulunamadı.',
                      buttonText: _searchQuery.isEmpty ? 'Yenile' : 'Aramayı Temizle',
                      onButtonPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        } else {
                          ref.invalidate(synonymGroupsFutureProvider);
                        }
                      },
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.turquoise,
                    onRefresh: () async {
                      ref.invalidate(synonymGroupsFutureProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: filteredGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Header (Turkish meaning + word count - No Study button)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.pink.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.compare_arrows_rounded,
                                      size: 16,
                                      color: AppColors.pink,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      group.turkishMeaning,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.turquoise.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${group.words.length} kelime',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.turquoise,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Synonym Badges (Interactive: tap to open detail popup, no speaker icon)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.words.map((word) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        showWordDetailModal(
                                          context,
                                          word: word,
                                          allWords: wordListState.words,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkCard
                                              : AppColors.pinkLight,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.pink.withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          word.en,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.pink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
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
