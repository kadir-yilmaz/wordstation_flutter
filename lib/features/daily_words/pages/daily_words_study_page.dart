import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_error_view.dart';
import '../../../core/widgets/word_detail_bottom_sheet.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../controllers/daily_word_controller.dart';
import '../models/daily_word_session.dart';

class DailyWordsStudyPage extends ConsumerStatefulWidget {
  final String listName;

  const DailyWordsStudyPage({super.key, required this.listName});

  @override
  ConsumerState<DailyWordsStudyPage> createState() => _DailyWordsStudyPageState();
}

class _DailyWordsStudyPageState extends ConsumerState<DailyWordsStudyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.listName.isNotEmpty) {
      _selectedList = widget.listName;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wordListState = ref.read(wordListControllerProvider);
      if (wordListState.words.isEmpty && !wordListState.isLoading) {
        ref.read(wordListControllerProvider.notifier).loadInitialData();
      } else if (_selectedList != null && _selectedList!.isNotEmpty) {
        ref.read(dailyWordControllerProvider.notifier).loadSession(_selectedList!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordListState = ref.watch(wordListControllerProvider);
    final dailyState = ref.watch(dailyWordControllerProvider);
    final dailyNotifier = ref.read(dailyWordControllerProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if ((_selectedList == null || _selectedList!.isEmpty || !wordListState.listNames.contains(_selectedList)) 
        && wordListState.listNames.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedList = wordListState.listNames.first;
          });
          ref.read(dailyWordControllerProvider.notifier).loadSession(wordListState.listNames.first);
        }
      });
    }

    final currentList = _selectedList ?? '';
    final allWordsInList = wordListState.words
        .where((w) => w.listName == currentList)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: wordListState.listNames.isEmpty
            ? const Text('Günlük Kelimeler')
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedList,
                  focusColor: Colors.transparent,
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _selectedList) {
                      setState(() {
                        _selectedList = newValue;
                      });
                      ref.read(dailyWordControllerProvider.notifier).loadSession(newValue);
                    }
                  },
                  items: wordListState.listNames.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.turquoise,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.turquoise,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Text(
                'Tümü (${allWordsInList.where((w) => !(dailyState.session?.dailyWords.any((d) => d.wordId == w.id) ?? false) && !(dailyState.session?.completedWords.any((c) => c.wordId == w.id) ?? false)).length})',
              ),
            ),
            Tab(
              child: Text(
                'Çalışılan (${dailyState.session?.completedWords.length ?? 0})',
              ),
            ),
            Tab(
              child: Text(
                'Günlük Kelimeler (${dailyState.session?.dailyWords.length ?? 0})',
              ),
            ),
          ],
        ),
      ),
      body: currentList.isEmpty 
          ? Center(
              child: Text(
                'Kelime listesi bulunamadı.',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            )
          : dailyState.isLoading && dailyState.session == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
          : dailyState.errorMessage != null && dailyState.session == null
              ? NetworkErrorView(
                  message: dailyState.errorMessage,
                  onRetry: () => dailyNotifier.loadSession(currentList),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllWordsTab(allWordsInList, dailyState.session, dailyNotifier, isDark, currentList),
                    _buildStudiedWordsTab(allWordsInList, dailyState.session, dailyNotifier, isDark, currentList),
                    _buildDailyWordsTab(allWordsInList, dailyState.session, dailyNotifier, isDark, currentList),
                  ],
                ),
    );
  }

  Widget _buildAllWordsTab(
      List<WordModel> allWords, DailyWordSession? session, DailyWordController notifier, bool isDark, String currentList) {
    
    final dailyWordIds = session?.dailyWords.map((e) => e.wordId).toSet() ?? {};
    final completedWordIds = session?.completedWords.map((e) => e.wordId).toSet() ?? {};

    final unselectedWords = allWords
        .where((w) => !dailyWordIds.contains(w.id) && !completedWordIds.contains(w.id))
        .toList();

    if (unselectedWords.isEmpty) {
      return const Center(child: Text('Tüm kelimeler seçildi veya çalışıldı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unselectedWords.length,
      itemBuilder: (context, index) {
        final word = unselectedWords[index];
        final isDaily = false;
        final isCompleted = false;

        return _buildWordCard(
          word.en,
          word.tr,
          isDaily,
          isCompleted,
          isDark,
          onAddTap: () {
            if (!isDaily && !isCompleted && word.id != null) {
              notifier.addToDaily(currentList, [word.id as int]);
              HapticFeedback.lightImpact();
            }
          },
          onTap: () => showWordDetailModal(context, word: word),
        );
      },
    );
  }

  Widget _buildStudiedWordsTab(
      List<WordModel> allWords, DailyWordSession? session, DailyWordController notifier, bool isDark, String currentList) {
    final completedWords = session?.completedWords ?? [];

    if (completedWords.isEmpty) {
      return const Center(child: Text('Henüz çalışılan kelime yok.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedWords.length,
      itemBuilder: (context, index) {
        final word = completedWords[index];
        final fullWord = allWords.firstWhere(
          (w) => w.id == word.wordId,
          orElse: () => WordModel(id: word.wordId, en: word.en, tr: word.tr, listName: currentList),
        );
        return _buildWordCard(
          word.en, 
          word.tr, 
          false, 
          true, 
          isDark, 
          onAddTap: null,
          onUndoTap: () {
            notifier.addToDaily(currentList, [word.wordId]);
            HapticFeedback.lightImpact();
          },
          onTap: () => showWordDetailModal(context, word: fullWord),
        );
      },
    );
  }

  Widget _buildDailyWordsTab(
      List<WordModel> allWords, DailyWordSession? session, DailyWordController notifier, bool isDark, String currentList) {
    final dailyWords = session?.dailyWords ?? [];

    if (dailyWords.isEmpty) {
      return const Center(child: Text('Günlük çalışılacak kelime seçilmedi.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Günlük Kelimeler (${dailyWords.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final ids = dailyWords.map((e) => e.wordId).toList();
                  notifier.completeAllWords(currentList, ids);
                },
                icon: const Icon(Icons.done_all),
                label: const Text('Tümünü İşaretle'),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dailyWords.length,
            itemBuilder: (context, index) {
              final word = dailyWords[index];
              final fullWord = allWords.firstWhere(
                (w) => w.id == word.wordId,
                orElse: () => WordModel(id: word.wordId, en: word.en, tr: word.tr, listName: currentList),
              );
              return _buildWordCard(
                word.en,
                word.tr,
                true,
                false,
                isDark,
                onAddTap: null,
                onCompleteTap: () {
                  notifier.completeWord(currentList, word.wordId);
                  HapticFeedback.lightImpact();
                },
                onRemoveTap: () {
                  notifier.removeFromDaily(currentList, [word.wordId]);
                  HapticFeedback.lightImpact();
                },
                onTap: () => showWordDetailModal(context, word: fullWord),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(String en, String tr, bool isDaily, bool isCompleted, bool isDark,
      {VoidCallback? onAddTap, VoidCallback? onCompleteTap, VoidCallback? onRemoveTap, VoidCallback? onUndoTap, VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkCardElevated : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(en, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted) ...[
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              if (onUndoTap != null)
                IconButton(
                  icon: const Icon(Icons.undo_rounded, color: AppColors.turquoise),
                  onPressed: onUndoTap,
                  tooltip: 'Günlük Kelimelere Geri Al',
                ),
            ]
            else if (isDaily) ...[
              if (onCompleteTap != null)
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: onCompleteTap,
                  tooltip: 'Tamamla',
                ),
              if (onRemoveTap != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  onPressed: onRemoveTap,
                  tooltip: 'Günlükten Çıkar',
                )
            ] else if (onAddTap != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.turquoise),
                onPressed: onAddTap,
                tooltip: 'Günlük Kelimelere Ekle',
              )
          ],
        ),
      ),
    );
  }
}
