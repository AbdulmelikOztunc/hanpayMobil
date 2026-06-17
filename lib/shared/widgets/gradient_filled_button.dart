import 'package:flutter/material.dart';
import 'package:hanpay_mobil/core/theme/app_colors.dart';

class GradientFilledButton extends StatelessWidget {
  const GradientFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? LinearGradient(
                colors: [
                  AppColors.gradientStart.withValues(alpha: 0.5),
                  AppColors.gradientEnd.withValues(alpha: 0.5),
                ],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.gradientEnd.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
