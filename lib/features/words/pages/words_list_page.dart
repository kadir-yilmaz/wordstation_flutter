import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../controllers/word_list_controller.dart';
import 'study_session_page.dart';

class WordsListPage extends ConsumerStatefulWidget {
  const WordsListPage({super.key});

  @override
  ConsumerState<WordsListPage> createState() => _WordsListPageState();
}

class _WordsListPageState extends ConsumerState<WordsListPage> {
  bool _isNavigating = false;
  bool _isDialogOpen = false;

  // Gradient pairs matching Swift HomeTVC
  final List<List<Color>> _listGradients = const [
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
      ref.read(wordListControllerProvider.notifier).loadInitialData();
    });
  }

  void _showAddListDialog() {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New List',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter a name for your new word list.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Name (e.g. YDS, TOEFL, A1)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(wordListControllerProvider.notifier)
                      .createList(text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _isDialogOpen = false;
    });
  }

  void _showRenameDialog(String oldName) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final textController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Rename List'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'New List Name',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(wordListControllerProvider.notifier)
                      .renameList(oldName, newName);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _isDialogOpen = false;
    });
  }

  void _showDeleteDialog(String listName) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete List'),
          content: Text(
            "'$listName' will be permanently deleted. Are you sure?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref
                    .read(wordListControllerProvider.notifier)
                    .deleteList(listName);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _isDialogOpen = false;
    });
  }

  void _openListStudy(String listName) {
    if (_isNavigating) return;
    _isNavigating = true;

    HapticFeedback.mediumImpact();

    // Instant zero-lag retrieval from in-memory state
    final wordListState = ref.read(wordListControllerProvider);
    final listWords = wordListState.words
        .where((w) => w.listName == listName)
        .toList();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => StudySessionPage(
              words: listWords,
              listTitle: listName,
            ),
          ),
        )
        .then((_) {
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
              // Header Bar (Swift HomeVC replica)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                    // + Add List Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showAddListDialog,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.turquoiseGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.turquoise.withValues(alpha: 0.35),
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
                                AppColors.turquoise),
                          ),
                        )
                      : wordListState.listNames.isEmpty
                          ? _buildEmptyState(isDark)
                          : isDesktop
                              ? GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: 100,
                                  ),
                                  itemCount: wordListState.listNames.length,
                                  itemBuilder: (context, index) {
                                    final listName =
                                        wordListState.listNames[index];
                                    final gradient = _listGradients[
                                        index % _listGradients.length];

                                    final wordCount = wordListState.words
                                        .where((w) => w.listName == listName)
                                        .length;

                                    return _buildListCard(
                                      listName: listName,
                                      wordCount: wordCount,
                                      gradient: gradient,
                                      onTap: () => _openListStudy(listName),
                                      onRename: () =>
                                          _showRenameDialog(listName),
                                      onDelete: () =>
                                          _showDeleteDialog(listName),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                  itemCount: wordListState.listNames.length,
                                  itemBuilder: (context, index) {
                                    final listName =
                                        wordListState.listNames[index];
                                    final gradient = _listGradients[
                                        index % _listGradients.length];

                                    // Count words in this list
                                    final wordCount = wordListState.words
                                        .where((w) => w.listName == listName)
                                        .length;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: _buildListCard(
                                        listName: listName,
                                        wordCount: wordCount,
                                        gradient: gradient,
                                        onTap: () => _openListStudy(listName),
                                        onRename: () =>
                                            _showRenameDialog(listName),
                                        onDelete: () =>
                                            _showDeleteDialog(listName),
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

  Widget _buildListCard({
    required String listName,
    required int wordCount,
    required List<Color> gradient,
    required VoidCallback onTap,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (wordCount > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '$wordCount words',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Popup Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (val) {
                    if (val == 'rename') onRename();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Rename List'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete List',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                // Right Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
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
              'Create your first word list by tapping the + button',
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
              onPressed: _showAddListDialog,
            ),
          ],
        ),
      ),
    );
  }
}
