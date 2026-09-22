import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WordListCard extends StatelessWidget {
  final int index;
  final String listName;
  final int wordCount;
  final List<Color> gradient;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const WordListCard({
    super.key,
    required this.index,
    required this.listName,
    required this.wordCount,
    required this.gradient,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark ? AppColors.darkCardElevated : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: isDark
                        ? const BorderSide(color: AppColors.darkBorder, width: 0.8)
                        : BorderSide.none,
                  ),
                  onSelected: (val) {
                    if (val == 'rename') onRename();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: isDark ? AppColors.info : AppColors.blue,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Rename List',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete List',
                            style: TextStyle(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                // Drag & Reorder Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: 'Sürükleyip sırala',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Right Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
