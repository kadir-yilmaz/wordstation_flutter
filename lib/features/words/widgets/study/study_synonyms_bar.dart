import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/word_detail_bottom_sheet.dart';
import '../../controllers/study_controller.dart';

class StudySynonymsBar extends StatelessWidget {
  final bool isDark;
  final List<SynonymBadgeItem> badges;
  final bool isDesktop;
  final ScrollController scrollController;
  final VoidCallback? onBeforeOpenModal;
  final VoidCallback? onAfterCloseModal;

  const StudySynonymsBar({
    super.key,
    required this.isDark,
    required this.badges,
    required this.isDesktop,
    required this.scrollController,
    this.onBeforeOpenModal,
    this.onAfterCloseModal,
  });

  Widget _buildBadgeItem(BuildContext context, SynonymBadgeItem badge) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: badge.gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: badge.gradient.first.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            onBeforeOpenModal?.call();
            await showWordDetailModal(context, word: badge.word);
            onAfterCloseModal?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              badge.word.en,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Container(
        height: 38,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No synonyms available for this word.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    }

    // On Desktop / Web: 3-row compact multi-line Wrap layout with vertical scroll if more
    if (isDesktop) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 120),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: false,
          radius: const Radius.circular(6),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((b) => _buildBadgeItem(context, b)).toList(),
            ),
          ),
        ),
      );
    }

    // On Mobile / Phone: Single horizontal scrollable row
    return SizedBox(
      height: 38,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: badges.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final badge = badges[idx];
          return _buildBadgeItem(context, badge);
        },
      ),
    );
  }
}
