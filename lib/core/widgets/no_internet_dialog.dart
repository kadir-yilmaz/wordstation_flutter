import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

/// Modal dialog with a darkened / blurred backdrop that pops up when a network action fails.
/// Provides an interactive "Tekrar Dene" button with an animated spinner.
class NoInternetDialog extends StatefulWidget {
  final String? title;
  final String? message;
  final String retryButtonText;
  final String cancelButtonText;
  final Future<void> Function()? onRetry;
  final VoidCallback? onCancel;

  const NoInternetDialog({
    super.key,
    this.title,
    this.message,
    this.retryButtonText = 'Tekrar Dene',
    this.cancelButtonText = 'Kapat',
    this.onRetry,
    this.onCancel,
  });

  /// Displays the dialog over the current Navigator context with darkened blur.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    String retryButtonText = 'Tekrar Dene',
    String cancelButtonText = 'Kapat',
    Future<void> Function()? onRetry,
    VoidCallback? onCancel,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NoInternetDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return NoInternetDialog(
          title: title,
          message: message,
          retryButtonText: retryButtonText,
          cancelButtonText: cancelButtonText,
          onRetry: onRetry,
          onCancel: onCancel,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * curved.value,
            sigmaY: 5 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _isRetrying = false;
  String? _inlineError;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() {
      _isRetrying = true;
      _inlineError = null;
    });

    try {
      await widget.onRetry!();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _inlineError = 'Hâlâ bağlanılamadı. Lütfen tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardElevated : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge with subtle border
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.error.withValues(alpha: 0.16)
                        : const Color(0xFFFFECEB),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 36,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  widget.title ?? 'İnternet Bağlantısı Yok',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.message ??
                      'Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),

                // Inline Error notice if retry fails
                if (_inlineError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons: Cancel & Retry
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isRetrying
                            ? null
                            : () {
                                if (widget.onCancel != null) {
                                  widget.onCancel!();
                                }
                                Navigator.of(context).pop(false);
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.cancelButtonText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: widget.retryButtonText,
                        prefixIcon: _isRetrying ? null : Icons.refresh_rounded,
                        isLoading: _isRetrying,
                        onPressed: _handleRetry,
                        variant: ButtonVariant.primary,
                        height: 46,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
