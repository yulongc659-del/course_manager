import 'package:flutter/cupertino.dart';
import '../design_system/colors.dart';
import '../design_system/radius.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 22,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark
            ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.85)
            : CupertinoColors.systemBackground.withValues(alpha: 0.92));

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey4, context).withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey4, context).withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class GlassSectionHeader extends StatelessWidget {
  final String title;

  const GlassSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey, context))),
    );
  }
}

class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;

  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56,
                color: CupertinoColors.systemGrey.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.55))),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14,
                      color: CupertinoColors.systemGrey)),
            ],
          ],
        ),
      ),
    );
  }
}
