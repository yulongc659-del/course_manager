import 'dart:ui';
import 'package:flutter/cupertino.dart';

class AppColors {
  // Background
  static Color background(BuildContext context) =>
      CupertinoTheme.of(context).scaffoldBackgroundColor ??
          CupertinoColors.systemGroupedBackground;

  static Color cardBackground(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return isDark
        ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.85)
        : CupertinoColors.systemBackground.withValues(alpha: 0.92);
  }

  // Primary
  static Color primary(BuildContext context) =>
      CupertinoTheme.of(context).primaryColor;

  static Color primaryContainer(BuildContext context) =>
      CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.1);

  // Text
  static Color label(BuildContext context) =>
      CupertinoDynamicColor.resolve(CupertinoColors.label, context);

  static Color secondaryLabel(BuildContext context) =>
      CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context);

  static Color tertiaryLabel(BuildContext context) =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context);

  // Border
  static Color border(BuildContext context) =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemGrey4, context)
          .withValues(alpha: 0.2);

  // Shadow
  static Color shadow(BuildContext context) =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemGrey4, context)
          .withValues(alpha: 0.08);

  // Status
  static Color get success => const Color(0xFF34C759);
  static Color get warning => const Color(0xFFFF9500);
  static Color get error => const Color(0xFFFF3B30);

  // Glass
  static Color glassHighlight(BuildContext context) =>
      CupertinoColors.white.withValues(alpha: 0.25);

  static Color navButtonBackground(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return isDark
        ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.7)
        : CupertinoColors.white.withValues(alpha: 0.7);
  }

  // Course colors palette
  static const coursePalette = [
    Color(0xFF2196F3),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFFFF2D55),
    Color(0xFF5AC8FA),
    Color(0xFF8B6F47),
    Color(0xFF6E798A),
  ];

  static Color courseColor(int index) =>
      coursePalette[index % coursePalette.length];
}
