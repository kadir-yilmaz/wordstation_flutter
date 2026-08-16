import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  orange,
  blue,
  outline,
  ghost,
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height = 54,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  LinearGradient? get _gradient {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.turquoiseGradient;
      case ButtonVariant.secondary:
        return AppColors.pinkGradient;
      case ButtonVariant.orange:
        return AppColors.orangeGradient;
      case ButtonVariant.blue:
        return AppColors.blueGradient;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return null;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.orange:
      case ButtonVariant.blue:
        return Colors.white;
      case ButtonVariant.outline:
        return AppColors.turquoise;
      case ButtonVariant.ghost:
        return AppColors.turquoise;
    }
  }

  Border? get _border {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(color: AppColors.turquoise, width: 1.5);
    }
    return null;
  }

  Color? get _backgroundColor {
    if (widget.variant == ButtonVariant.ghost) {
      return Colors.transparent;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : _gradient,
          color: isDisabled ? Colors.grey.withValues(alpha: 0.3) : _backgroundColor,
          border: _border,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: !isDisabled && _gradient != null
              ? [
                  BoxShadow(
                    color: _gradient!.colors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTapDown: (_) {
              if (!isDisabled) {
                setState(() => _isPressed = true);
                HapticFeedback.selectionClick();
              }
            },
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: isDisabled ? null : widget.onPressed,
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.prefixIcon != null) ...[
                            Icon(
                              widget.prefixIcon,
                              color: _textColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.grey.shade500
                                  : _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.suffixIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              widget.suffixIcon,
                              color: _textColor,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
