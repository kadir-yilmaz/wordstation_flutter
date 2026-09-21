import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../words/models/word_model.dart';
import '../models/daily_quiz_plan_model.dart';

class BuffetWordPickerModal extends StatefulWidget {
  final List<WordModel> poolWords; // Target list words
  final DailyQuizPlanModel plan;
  final Future<void> Function(List<int> selectedWordIds) onConfirm;

  const BuffetWordPickerModal({
    super.key,
    required this.poolWords,
    required this.plan,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required List<WordModel> poolWords,
    required DailyQuizPlanModel plan,
    required Future<void> Function(List<int> selectedWordIds) onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BuffetWordPickerModal(
        poolWords: poolWords,
        plan: plan,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BuffetWordPickerModal> createState() => _BuffetWordPickerModalState();
}

class _BuffetWordPickerModalState extends State<BuffetWordPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with current daily selection if any
    for (final id in widget.plan.dailySelectedWordIds) {
      final parsed = int.tryParse(id.toString());
      if (parsed != null && parsed > 0) {
        _selectedIds.add(parsed);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Kelimelerden sadece havuzda kalanlar (henüz düşmemiş olanlar)
  List<WordModel> get _remainingPoolWords {
    final completedSet = widget.plan.completedWordIds
        .map((id) => int.tryParse(id.toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    return widget.poolWords.where((w) => !completedSet.contains(w.id)).toList();
  }

  List<WordModel> get _filteredWords {
    final pool = _remainingPoolWords;
    if (_searchQuery.isEmpty) return pool;

    final query = _searchQuery.toLowerCase();
    return pool.where((w) {
      return w.en.toLowerCase().contains(query) ||
          w.tr.toLowerCase().contains(query);
    }).toList();
  }

  void _quickSelectRandom(int count) {
    HapticFeedback.mediumImpact();
    final pool = _remainingPoolWords;
    if (pool.isEmpty) return;

    final shuffled = List<WordModel>.from(pool)..shuffle(Random());
    final picked = shuffled
        .take(count)
        .map((w) => int.tryParse(w.id.toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    setState(() {
      _selectedIds
        ..clear()
        ..addAll(picked);
    });
  }

  void _quickSelectFirst(int count) {
    HapticFeedback.mediumImpact();
    final pool = _remainingPoolWords;
    if (pool.isEmpty) return;

    final picked = pool
        .take(count)
        .map((w) => int.tryParse(w.id.toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(picked);
    });
  }

  void _clearSelection() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIds.clear();
    });
  }

  void _toggleWord(int wordId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(wordId)) {
        _selectedIds.remove(wordId);
      } else {
        _selectedIds.add(wordId);
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bugün için en az 1 kelime seçin.'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onConfirm(_selectedIds.toList());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPool = _remainingPoolWords.length;
    final filtered = _filteredWords;
    final targetCount = widget.plan.dailyCount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.turquoise.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.turquoise,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Açık Büfe: Günlük Kelime Seçimi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Havuzda $totalPool kelime kaldı • Hedef: $targetCount kelime',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Havuzda kelime ara...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Select Action Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildQuickChip(
                  label: 'Rastgele $targetCount Seç',
                  icon: Icons.shuffle_rounded,
                  isDark: isDark,
                  onTap: () => _quickSelectRandom(targetCount),
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: 'İlk $targetCount Seç',
                  icon: Icons.format_list_numbered_rounded,
                  isDark: isDark,
                  onTap: () => _quickSelectFirst(targetCount),
                ),
                if (targetCount != 20) ...[
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    label: 'Rastgele 20 Seç',
                    icon: Icons.auto_awesome_rounded,
                    isDark: isDark,
                    onTap: () => _quickSelectRandom(20),
                  ),
                ],
                if (_selectedIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    label: 'Temizle (${_selectedIds.length})',
                    icon: Icons.refresh_rounded,
                    isDark: isDark,
                    isDestructive: true,
                    onTap: _clearSelection,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Divider(height: 1),

          // Word List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aramaya uygun kelime bulunamadı'
                              : 'Havuzdaki tüm kelimeler tamamlandı!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final word = filtered[index];
                      final wordId = int.tryParse(word.id.toString()) ?? 0;
                      final isSelected = _selectedIds.contains(wordId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.turquoise.withValues(alpha: isDark ? 0.18 : 0.12)
                              : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.turquoise
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _toggleWord(wordId),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.turquoise
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.turquoise
                                          : (isDark ? Colors.white30 : Colors.grey.shade400),
                                      width: 1.8,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.en,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        word.tr,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Sticky Bottom Confirmation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedIds.length} / $targetCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.turquoise,
                      ),
                    ),
                    Text(
                      'Kelime Seçildi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _isSaving ? 'Kaydediliyor...' : 'Seçimi Onayla & Başlat',
                    prefixIcon: Icons.check_circle_outline_rounded,
                    isLoading: _isSaving,
                    variant: ButtonVariant.primary,
                    onPressed: _isSaving ? null : _handleConfirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.turquoise;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
