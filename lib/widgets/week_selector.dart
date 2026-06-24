import 'package:flutter/material.dart';

class WeekSelector extends StatelessWidget {
  final int currentWeek;
  final ValueChanged<int> onWeekChanged;

  const WeekSelector({
    super.key,
    required this.currentWeek,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentWeek > 1
                ? () => onWeekChanged(currentWeek - 1)
                : null,
          ),
          Text(
            '第 $currentWeek 周',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentWeek < 20
                ? () => onWeekChanged(currentWeek + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
