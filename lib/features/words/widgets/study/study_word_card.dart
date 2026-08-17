import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/word_model.dart';

class StudyWordCardFlip extends StatelessWidget {
  final bool hasWords;
  final WordModel? currentWord;
  final Animation<double> flipAnimation;
  final VoidCallback onFlip;

  const StudyWordCardFlip({
    super.key,
    required this.hasWords,
    required this.currentWord,
    required this.flipAnimation,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasWords
          ? () {
              HapticFeedback.selectionClick();
              onFlip();
            }
          : null,
      child: AnimatedBuilder(
        animation: flipAnimation,
        builder: (context, child) {
          final angle = flipAnimation.value * pi;
          final isBackVisible = angle >= (pi / 2);

          final cardText = hasWords
              ? (isBackVisible ? currentWord!.tr : currentWord!.en)
              : (isBackVisible ? 'Sonuç Bulunamadı' : 'No Results');

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBackVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: StudyWordCard(
                      text: cardText,
                      isPink: true,
                    ),
                  )
                : StudyWordCard(
                    text: cardText,
                    isPink: false,
                  ),
          );
        },
      ),
    );
  }
}

class StudyWordCard extends StatelessWidget {
  final String text;
  final bool isPink;

  const StudyWordCard({
    super.key,
    required this.text,
    required this.isPink,
  });

  @override
  Widget build(BuildContext context) {
    // Turquoise: #12C6B2 / Pink: #E3719D matching Swift WordCardView
    final bgColor = isPink
        ? const Color(0xFFE3719D)
        : const Color(0xFF12C6B2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
