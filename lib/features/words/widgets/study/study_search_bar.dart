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

  const StudySearchBar({
    super.key,
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isSearchContains,
    required this.onToggleSearchMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                isDense: true,
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                        onPressed: onClear,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Square Mode Toggle Button
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
                color: isSearchContains
                    ? (isDark
                        ? AppColors.turquoise.withValues(alpha: 0.18)
                        : AppColors.turquoiseLight)
                    : (isDark
                        ? AppColors.darkSurface
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSearchContains
                      ? AppColors.turquoise.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : const Color(0xFFDCDCE0)),
                  width: 1.5,
                ),
              ),
              child: Text(
                isSearchContains ? '•a•' : 'a...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: isSearchContains
                      ? (isDark ? AppColors.turquoise : AppColors.turquoiseDark)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
