import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';

class AppGlass {
  static BoxDecoration card(BuildContext context) {
    return BoxDecoration(
      color: AppColors.cardBackground(context),
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border(context)),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow(context),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration courseCell(BuildContext context, Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(AppRadius.courseCard),
      border: Border.all(
        color: CupertinoColors.white.withValues(alpha: 0.3),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration floatingBar(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? CupertinoColors.systemBackground.withValues(alpha: 0.85)
          : CupertinoColors.lightBackgroundGray.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppSpacing.bottomBarRadius),
      border: Border.all(
        color: AppColors.border(context).withValues(alpha: 0.5),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow(context),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration navButton(BuildContext context) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.navButtonBackground(context),
      border: Border.all(color: AppColors.border(context)),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow(context),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration sheet(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemGroupedBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    );
  }

  static ImageFilter get barBlur =>
      ImageFilter.blur(sigmaX: 10, sigmaY: 10);

  static ImageFilter get lightBlur =>
      ImageFilter.blur(sigmaX: 4, sigmaY: 4);
}
