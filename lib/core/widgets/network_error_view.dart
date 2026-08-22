import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

/// Reusable inline error widget for pages when data fails to load due to network or server issues.
class NetworkErrorView extends StatefulWidget {
  final String? title;
  final String? message;
  final String buttonText;
  final Future<void> Function()? onRetry;
  final IconData icon;

  const NetworkErrorView({
    super.key,
    this.title,
    this.message,
    this.buttonText = 'Tekrar Dene',
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  State<NetworkErrorView> createState() => _NetworkErrorViewState();
}

class _NetworkErrorViewState extends State<NetworkErrorView> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry!();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Badge
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.error.withValues(alpha: 0.15)
                    : const Color(0xFFFFECEB),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 22),

            // Title
            Text(
              widget.title ?? 'Bağlantı Kurulamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              widget.message ??
                  'İnternet bağlantınızı kontrol edip lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),

            if (widget.onRetry != null) ...[
              const SizedBox(height: 26),
              CustomButton(
                text: widget.buttonText,
                prefixIcon: Icons.refresh_rounded,
                isLoading: _isRetrying,
                onPressed: _handleRetry,
                variant: ButtonVariant.primary,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
