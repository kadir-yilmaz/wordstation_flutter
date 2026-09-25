import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../controllers/word_list_controller.dart';
import '../models/synonym_group_model.dart';
import '../models/word_model.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wordsState = ref.read(wordListControllerProvider);
      if (wordsState.words.isEmpty && !wordsState.isLoading) {
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesTurkish(String source, String query) {
    if (query.isEmpty) return true;
    final s = source.toLowerCase().trim();
    final q = query.toLowerCase().trim();
    if (s.contains(q)) return true;

    String normalize(String str) {
      return str
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('Ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('Ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('Ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('Ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll('Ç', 'c')
          .toLowerCase()
          .trim();
    }

    return normalize(s).contains(normalize(q));
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(synonymGroupsFutureProvider);
    final wordListState = ref.watch(wordListControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          groupsAsync.maybeWhen(
                            data: (groups) {
                              if (_searchQuery.isEmpty) {
                                return Text(
                                  '${groups.length} eş anlamlı grup',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                );
                              }

                              final filteredGroups = groups.where((g) {
                                if (_matchesTurkish(g.turkishMeaning, _searchQuery)) return true;
                                return g.words.any((w) =>
                                    _matchesTurkish(w.en, _searchQuery) ||
                                    _matchesTurkish(w.tr, _searchQuery));
                              }).toList();

                              final displayedKeys = <String>{};
                              for (final g in filteredGroups) {
                                for (final w in g.words) {
                                  displayedKeys.add('${w.en.toLowerCase().trim()}::${w.tr.toLowerCase().trim()}');
                                }
                              }

                              final singleCount = wordListState.words.where((w) {
                                final key = '${w.en.toLowerCase().trim()}::${w.tr.toLowerCase().trim()}';
                                if (displayedKeys.contains(key)) return false;
                                return _matchesTurkish(w.tr, _searchQuery) ||
                                    _matchesTurkish(w.en, _searchQuery);
                              }).length;

                              String subtitle;
                              if (filteredGroups.isNotEmpty && singleCount > 0) {
                                subtitle = '${filteredGroups.length} grup • $singleCount tekil kelime bulundu';
                              } else if (filteredGroups.isNotEmpty) {
                                subtitle = '${filteredGroups.length} eş anlamlı grup bulundu';
                              } else if (singleCount > 0) {
                                subtitle = '$singleCount tekil kelime bulundu (Eş anlamlısı yok)';
                              } else {
                                subtitle = 'Sonuç bulunamadı';
                              }

                              return Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              );
                            },
                            orElse: () => Text(
                              'Eş anlamlı kelime grupları',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar (Gelişmiş Türkçe Arama Desteği)
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
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Kelime veya anlam ara (örn: eğilimli, ça)...',
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
                    error: (err, _) => NetworkErrorView(
                      title: 'Eş Anlamlılar Yüklenemedi',
                      message: 'İnternet bağlantınızı kontrol edip lütfen tekrar deneyin.',
                      onRetry: () async {
                        ref.invalidate(synonymGroupsFutureProvider);
                        await ref.read(synonymGroupsFutureProvider.future);
                      },
                    ),
                    data: (groups) {
                      // 1. Eş anlamlı gruplar filtresi
                      final filteredGroups = groups.where((g) {
                        if (_searchQuery.isEmpty) return true;
                        if (_matchesTurkish(g.turkishMeaning, _searchQuery)) return true;
                        return g.words.any((w) =>
                            _matchesTurkish(w.en, _searchQuery) ||
                            _matchesTurkish(w.tr, _searchQuery));
                      }).toList();

                      // 2. Arama yapıldığında eş anlamlısı olmayan tekil eşleşen kelimeleri bul
                      List<SynonymGroupModel> singleWordGroups = [];
                      if (_searchQuery.isNotEmpty) {
                        final displayedKeys = <String>{};
                        for (final g in filteredGroups) {
                          for (final w in g.words) {
                            displayedKeys.add('${w.en.toLowerCase().trim()}::${w.tr.toLowerCase().trim()}');
                          }
                        }

                        final matchingSingleWords = wordListState.words.where((w) {
                          final key = '${w.en.toLowerCase().trim()}::${w.tr.toLowerCase().trim()}';
                          if (displayedKeys.contains(key)) return false;
                          return _matchesTurkish(w.tr, _searchQuery) ||
                              _matchesTurkish(w.en, _searchQuery);
                        }).toList();

                        final map = <String, List<WordModel>>{};
                        for (final w in matchingSingleWords) {
                          final trKey = w.tr.trim();
                          if (trKey.isNotEmpty) {
                            map.putIfAbsent(trKey, () => []).add(w);
                          }
                        }

                        singleWordGroups = map.entries
                            .map((e) => SynonymGroupModel(
                                  turkishMeaning: e.key,
                                  words: e.value,
                                ))
                            .toList();
                      }

                      // İkisi de boşsa boş durum göster
                      if (filteredGroups.isEmpty && singleWordGroups.isEmpty) {
                        return RefreshIndicator(
                          color: AppColors.turquoise,
                          onRefresh: () async {
                            ref.invalidate(synonymGroupsFutureProvider);
                            await ref.read(wordListControllerProvider.notifier).refresh();
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: EmptyStateView(
                                  icon: Icons.search_off_rounded,
                                  title: _searchQuery.isEmpty
                                      ? 'Eş Anlamlı Grup Yok'
                                      : 'Sonuç Bulunamadı',
                                  description: _searchQuery.isEmpty
                                      ? 'Aynı Türkçe anlama sahip en az 2 kelime eklendiğinde burada gruplanacaktır. Aşağı çekerek yenileyebilirsiniz.'
                                      : 'Aradığınız kelimeye veya anlama uygun eşleşme bulunamadı.',
                                  buttonText: _searchQuery.isEmpty ? 'Yenile' : 'Aramayı Temizle',
                                  onButtonPressed: () {
                                    if (_searchQuery.isNotEmpty) {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    } else {
                                      ref.invalidate(synonymGroupsFutureProvider);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.turquoise,
                        onRefresh: () async {
                          ref.invalidate(synonymGroupsFutureProvider);
                          await ref.read(wordListControllerProvider.notifier).refresh();
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            // 1. Üst Bölüm: Eş Anlamlı Gruplar Başlığı (Arama esnasında her iki grup da varsa)
                            if (_searchQuery.isNotEmpty &&
                                filteredGroups.isNotEmpty &&
                                singleWordGroups.isNotEmpty)
                              _buildSectionHeader(
                                title: 'EŞ ANLAMLI GRUPLAR',
                                badge: '${filteredGroups.length} grup',
                                color: AppColors.pink,
                                icon: Icons.compare_arrows_rounded,
                                isDark: isDark,
                              ),

                            // Eş Anlamlı Grup Kartları (Pembe Tema)
                            ...filteredGroups.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildSynonymGroupCard(
                                  context,
                                  group,
                                  wordListState.words,
                                  isDark,
                                ),
                              ),
                            ),

                            // 2. Alt Grup Bölümü: Tekil Kelimeler (Turkuaz Tema)
                            if (singleWordGroups.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildSectionHeader(
                                title: 'TEKİL KELİMELER',
                                subtitle: filteredGroups.isEmpty
                                    ? 'Eş anlamlı grup bulunamadı, ancak aradığınız kelime sözlüğünüzde mevcut:'
                                    : 'Eş anlamlı grubu olmayan diğer Türkçe eşleşmeler',
                                badge: '${singleWordGroups.fold<int>(0, (sum, g) => sum + g.words.length)} kelime',
                                color: AppColors.turquoise,
                                icon: Icons.translate_rounded,
                                isDark: isDark,
                              ),
                              ...singleWordGroups.map(
                                (group) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildSingleWordGroupCard(
                                    context,
                                    group,
                                    wordListState.words,
                                    isDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  // Bölüm Başlığı
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    required String badge,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Standart Eş Anlamlı Grup Kartı (Pembe Tema)
  Widget _buildSynonymGroupCard(
    BuildContext context,
    SynonymGroupModel group,
    List<WordModel> allWords,
    bool isDark,
  ) {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      allWords: allWords,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.pinkLight,
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
  }

  // Farklı Tema: Alt Grupta Gözüken Tekil Kelime Kartı (Turkuaz Tema)
  Widget _buildSingleWordGroupCard(
    BuildContext context,
    SynonymGroupModel group,
    List<WordModel> allWords,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.turquoise.withValues(alpha: 0.28)
              : AppColors.turquoise.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.turquoise.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.turquoise.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: AppColors.turquoise,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tekil Kelime',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                      allWords: allWords,
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
                          : AppColors.turquoiseLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.turquoise.withValues(alpha: 0.38),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.en,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.turquoiseDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10.5,
                          color: AppColors.turquoiseDark,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (group.words.isNotEmpty &&
              group.words.first.example != null &&
              group.words.first.example!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${group.words.first.example!.trim()}”',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
