import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class StudySearchBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isSearchContains;
  final VoidCallback onToggleSearchMode;
  final bool isSearchTr;
  final VoidCallback onToggleSearchLang;

  const StudySearchBar({
    super.key,
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isSearchContains,
    required this.onToggleSearchMode,
    this.isSearchTr = false,
    required this.onToggleSearchLang,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Starts With / Contains Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggleSearchMode();
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isSearchContains ? Icons.format_align_center : Icons.format_align_left,
                  size: 20,
                  color: isSearchContains ? AppColors.turquoise : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // TR / EN Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggleSearchLang();
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSearchTr ? const Color(0xFF785BFF) : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSearchTr ? const Color(0xFF785BFF) : (isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0)),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isSearchTr ? 'TR' : 'EN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSearchTr ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search Bar
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: onChanged,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Kelime ara...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.transparent,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
