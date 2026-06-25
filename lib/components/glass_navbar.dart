import 'package:flutter/cupertino.dart';

class GlassLargeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBottomDivider;

  const GlassLargeTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBottomDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2)),
                  ),
                  if (actions.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                ],
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey)),
                ),
            ],
          ),
        ),
        if (showBottomDivider)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey4, context).withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}

class GlassNavAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassNavAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20,
            color: CupertinoTheme.of(context).primaryColor),
      ),
    );
  }
}
