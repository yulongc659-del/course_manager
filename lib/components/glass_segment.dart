import 'package:flutter/cupertino.dart';

class GlassSegment<T extends Object> extends StatelessWidget {
  final T groupValue;
  final Map<T, Widget> children;
  final ValueChanged<T> onValueChanged;

  const GlassSegment({
    super.key,
    required this.groupValue,
    required this.children,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSegmentedControl<T>(
      groupValue: groupValue,
      children: children,
      onValueChanged: onValueChanged,
    );
  }
}

class GlassSegmentIcon<T extends Object> extends StatelessWidget {
  final T groupValue;
  final Map<T, IconData> icons;
  final ValueChanged<T> onValueChanged;

  const GlassSegmentIcon({
    super.key,
    required this.groupValue,
    required this.icons,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSegmentedControl<T>(
      groupValue: groupValue,
      children: icons.map((key, icon) => MapEntry(
            key,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(icon, size: 18),
            ),
          )),
      onValueChanged: onValueChanged,
    );
  }
}
