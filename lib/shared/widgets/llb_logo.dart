import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';

class LlbLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool isLightOnDark;

  const LlbLogo({
    super.key,
    this.size = 56,
    this.showSubtitle = true,
    this.isLightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLightOnDark ? Colors.white : AppColors.textPrimary;
    final badgeBg = isLightOnDark ? Colors.white : AppColors.primaryBlack;
    final badgeText = isLightOnDark ? AppColors.primaryBlack : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Elegant Monogram Emblem Badge
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(size * 0.18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'LLB',
            style: TextStyle(
              color: badgeText,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontFamily: 'serif',
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Brand Title
        Text(
          'LLB REAL ESTATE',
          style: AppTypography.heading2.copyWith(
            color: textColor,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            AppConstants.companyFullName.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: isLightOnDark ? Colors.white70 : AppColors.textMuted,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
