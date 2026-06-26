import 'package:flutter/cupertino.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import '../design_system/glass.dart' as ds;

class TimetableGrid extends StatelessWidget {
  final List<Course> courses;
  final ValueChanged<Course>? onCourseTap;

  static const _rowHeight = 72.0;
  static const _headerHeight = 36.0;
  static const _timeColWidth = 72.0;
  static const _dayColWidth = 76.0;

  const TimetableGrid({
    super.key,
    required this.courses,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final borderColor = CupertinoDynamicColor.resolve(
        CupertinoColors.systemGrey5, context);
    final gridBg = isDark
        ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.5)
        : CupertinoColors.systemGroupedBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = _timeColWidth + _dayColWidth * 7;
        final totalHeight = _headerHeight + _rowHeight * periodLabels.length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  // Background grid
                  Column(
                    children: [
                      _buildHeaderRow(borderColor),
                      ...List.generate(periodLabels.length, (i) {
                        return _buildGridRow(i, borderColor, isDark);
                      }),
                    ],
                  ),
                  // Course cards overlay
                  ..._buildCourseCards(context, borderColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(Color borderColor) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          _baseCell(_timeColWidth, _headerHeight, borderColor, '', isHeader: true),
          ...List.generate(7, (d) {
            return _baseCell(_dayColWidth, _headerHeight, borderColor,
                weekdayLabels[d], isHeader: true);
          }),
        ],
      ),
    );
  }

  Widget _buildGridRow(int periodIndex, Color borderColor, bool isDark) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          _periodLabelCell(periodIndex, borderColor),
          ...List.generate(7, (_) {
            return _baseCell(_dayColWidth, _rowHeight, borderColor, '');
          }),
        ],
      ),
    );
  }

  Widget _periodLabelCell(int index, Color borderColor) {
    return Container(
      width: _timeColWidth,
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(periodLabels[index],
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Text(periodTimes[index],
              style: TextStyle(fontSize: 9, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  List<Widget> _buildCourseCards(BuildContext ctx, Color borderColor) {
    final used = <int, Map<int, bool>>{};
    final cards = <Widget>[];

    for (final course in courses) {
      final day = course.dayOfWeek - 1;
      final periodCount = course.periodEnd - course.periodStart + 1;
      // Map period to row index: period 1-2 → row 0, 3-4 → row 1, etc.
      final startRow = (course.periodStart - 1) ~/ 2;
      final endRow = (course.periodEnd - 1) ~/ 2;
      final spanRows = endRow - startRow + 1;

      final left = _timeColWidth + day * _dayColWidth + 2;
      final top = _headerHeight + startRow * _rowHeight + 2;
      final width = _dayColWidth - 4;
      final height = _rowHeight * spanRows - 4;

      // Mark occupied cells
      used.putIfAbsent(day, () => {});
      for (int r = startRow; r <= endRow; r++) {
        used[day]![r] = true;
      }

      final color = courseColor(course.color);

      cards.add(Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: _buildCourseCard(ctx, course, color, height),
      ));
    }

    return cards;
  }

  Widget _buildCourseCard(BuildContext context, Course course, Color color, double height) {
    return GestureDetector(
      onTap: () => onCourseTap?.call(course),
      child: Container(
        decoration: ds.AppGlass.courseCell(context, color),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              course.name,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: height > 90 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (course.teacher.isNotEmpty)
              Text(
                course.teacher,
                style: TextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.78),
                  fontSize: height > 90 ? 9 : 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            if (course.classroom.isNotEmpty)
              Text(
                course.classroom,
                style: TextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.65),
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _baseCell(double width, double height, Color borderColor, String text,
      {bool isHeader = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        color: isHeader
            ? CupertinoColors.systemGrey6.withValues(alpha: 0.5)
            : null,
      ),
      alignment: Alignment.center,
      child: text.isNotEmpty
          ? Text(
              text,
              style: TextStyle(
                fontSize: isHeader ? 12 : 10,
                fontWeight: isHeader ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            )
          : null,
    );
  }
}
