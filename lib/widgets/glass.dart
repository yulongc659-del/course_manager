import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.opacity = 0.65,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.shadows,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.lightBackgroundGray;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey5, context),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withValues(alpha: opacity),
                  bgColor.withValues(alpha: opacity - 0.05),
                ],
              ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onTap,
    this.elevation = 1,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.7)
              : CupertinoColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey5, context),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey4, context).withValues(alpha: 0.3),
              blurRadius: 6 * elevation,
              offset: Offset(0, 2 * elevation),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
    return card;
  }
}

class AppleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool primary;
  final EdgeInsetsGeometry padding;

  const AppleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.primary = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bg = primary
        ? CupertinoTheme.of(context).primaryColor
        : (isDark
            ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.7)
            : CupertinoColors.white.withValues(alpha: 0.9));

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(
                  color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemGrey4, context),
                ),
          boxShadow: [
            BoxShadow(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey4, context).withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class AppleBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const AppleBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey5, context),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: isDark
                ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.85)
                : CupertinoColors.lightBackgroundGray.withValues(alpha: 0.85),
            padding: const EdgeInsets.only(top: 6),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 24,
                            color: selected
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? CupertinoTheme.of(context).primaryColor
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AppleProgressBar extends StatelessWidget {
  final double value;

  const AppleProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey5, context),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

class AppleSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;

  const AppleSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey4, context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title!,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
