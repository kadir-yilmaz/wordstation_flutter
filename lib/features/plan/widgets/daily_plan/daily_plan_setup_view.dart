import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/no_internet_dialog.dart';
import '../../../words/controllers/word_list_controller.dart';
import '../../controllers/plan_controller.dart';

class DailyPlanSetupView extends ConsumerStatefulWidget {
  final WordListState wordListState;
  final PlanState planState;
  final PlanController planNotifier;
  final bool isDark;
  final bool isCreatingNewPlan;
  final VoidCallback onCancelNewPlan;
  final VoidCallback onPlanCreated;

  const DailyPlanSetupView({
    super.key,
    required this.wordListState,
    required this.planState,
    required this.planNotifier,
    required this.isDark,
    required this.isCreatingNewPlan,
    required this.onCancelNewPlan,
    required this.onPlanCreated,
  });

  @override
  ConsumerState<DailyPlanSetupView> createState() => _DailyPlanSetupViewState();
}

class _DailyPlanSetupViewState extends ConsumerState<DailyPlanSetupView> {
  String _selectedListName = 'Tümü';
  int _wordsPerDay = 10;
  bool _enToTr = true;

  void _showWarningSnackBar(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listOptions = ['Tümü', ...widget.wordListState.listNames];
    final targetWordsCount = _selectedListName == 'Tümü'
        ? widget.wordListState.words.length
        : widget.wordListState.words
            .where((w) => w.listName == _selectedListName)
            .length;
    final totalDays =
        targetWordsCount > 0 ? (targetWordsCount / _wordsPerDay).ceil() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isCreatingNewPlan && widget.planState.dailyPlan != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onCancelNewPlan,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Mevcut Plana Dön'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.turquoise,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 1. Hedef Liste
        Text(
          'HEDEF KELİME LİSTESİ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: widget.isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: listOptions.map((name) {
            final isSelected = _selectedListName == name;
            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedListName = name);
                }
              },
              selectedColor: AppColors.turquoise.withValues(alpha: 0.2),
              checkmarkColor: AppColors.turquoise,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.turquoise
                    : (widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
              backgroundColor:
                  widget.isDark ? AppColors.darkSurface : Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.turquoise
                    : (widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // 2. Günlük Kelime Sayısı
        Text(
          'GÜNLÜK KELİME SAYISI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: widget.isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [5, 10, 20, 50].map((count) {
            final isSelected = _wordsPerDay == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _wordsPerDay = count);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.turquoise.withValues(alpha: 0.15)
                          : (widget.isDark
                              ? AppColors.darkSurface
                              : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.turquoise
                            : (widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        width: isSelected ? 2 : 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.turquoise
                              : (widget.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // 3. Soru Yönü
        Text(
          'SORU YÖNÜ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: widget.isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _enToTr = true);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _enToTr
                        ? AppColors.turquoise.withValues(alpha: 0.15)
                        : (widget.isDark
                            ? AppColors.darkSurface
                            : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _enToTr
                          ? AppColors.turquoise
                          : (widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: _enToTr ? 2 : 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'İngilizce ➔ Türkçe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _enToTr ? FontWeight.w700 : FontWeight.w600,
                        color: _enToTr
                            ? AppColors.turquoise
                            : (widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _enToTr = false);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_enToTr
                        ? AppColors.pink.withValues(alpha: 0.15)
                        : (widget.isDark
                            ? AppColors.darkSurface
                            : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_enToTr
                          ? AppColors.pink
                          : (widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: !_enToTr ? 2 : 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Türkçe ➔ İngilizce',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            !_enToTr ? FontWeight.w700 : FontWeight.w600,
                        color: !_enToTr
                            ? AppColors.pink
                            : (widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Plan Özeti
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.turquoise,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '$targetWordsCount kelime • Günde $_wordsPerDay kelime\nPlan $totalDays günde tamamlanacak.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Planı Başlat Butonu
        CustomButton(
          text: widget.isCreatingNewPlan
              ? 'Planı Yeniden Oluştur'
              : 'Günlük Planı Başlat',
          prefixIcon: Icons.rocket_launch_rounded,
          variant: ButtonVariant.primary,
          onPressed: () async {
            if (targetWordsCount < 4) {
              final err = widget.wordListState.errorMessage;
              if (err != null && DioErrorHandler.isNetworkError(err)) {
                NoInternetDialog.show(
                  context,
                  onRetry: () async {
                    await ref
                        .read(wordListControllerProvider.notifier)
                        .refresh();
                    await widget.planNotifier.loadPlanData();
                  },
                );
              } else {
                _showWarningSnackBar(context,
                    'Plan başlatmak için seçilen listede en az 4 kelime olmalıdır.');
              }
              return;
            }

            HapticFeedback.mediumImpact();

            final success = await widget.planNotifier.createPlan(
              listName: _selectedListName,
              dailyCount: _wordsPerDay,
              englishToTurkish: _enToTr,
            );

            if (success) {
              widget.onPlanCreated();
            } else if (context.mounted) {
              final err = ref.read(planControllerProvider).errorMessage ??
                  widget.wordListState.errorMessage;
              if (err != null && DioErrorHandler.isNetworkError(err)) {
                NoInternetDialog.show(
                  context,
                  onRetry: () async {
                    final ok = await widget.planNotifier.createPlan(
                      listName: _selectedListName,
                      dailyCount: _wordsPerDay,
                      englishToTurkish: _enToTr,
                    );
                    if (!ok) throw Exception('Retry failed');
                  },
                );
              } else {
                _showWarningSnackBar(context,
                    'Plan oluşturulamadı. Lütfen kelime listenizi kontrol edin.');
              }
            }
          },
        ),
      ],
    );
  }
}
