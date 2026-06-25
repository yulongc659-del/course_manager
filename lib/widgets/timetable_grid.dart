import 'package:flutter/cupertino.dart';
import '../models/course.dart';
import '../utils/constants.dart';

class TimetableGrid extends StatelessWidget {
  final List<Course> courses;
  final ValueChanged<Course>? onCourseTap;

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
    final headerColor = isDark
        ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.5)
        : CupertinoColors.systemGrey6;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(borderColor, headerColor),
                ...List.generate(periodLabels.length, (p) =>
                    _buildRow(p, borderColor, headerColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color borderColor, Color headerColor) {
    return Row(
      children: [
        _cell('时间', 68, isHeader: true, borderColor: borderColor, headerColor: headerColor),
        ...List.generate(7, (d) {
          return _cell(weekdayLabels[d], 74, isHeader: true,
              borderColor: borderColor, headerColor: headerColor);
        }),
      ],
    );
  }

  Widget _buildRow(int periodIndex, Color borderColor, Color headerColor) {
    return Row(
      children: [
        _periodCell(periodIndex, borderColor, headerColor),
        ...List.generate(7, (dayIndex) {
          final course = _findCourse(dayIndex + 1, periodIndex);
          if (course != null) return _courseCell(course);
          return _cell('', 74, borderColor: borderColor, headerColor: headerColor);
        }),
      ],
    );
  }

  Widget _periodCell(int index, Color borderColor, Color headerColor) {
    return Container(
      width: 68,
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        color: headerColor,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            periodLabels[index],
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
          Text(
            periodTimes[index],
            style: TextStyle(
              fontSize: 8,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Course? _findCourse(int dayOfWeek, int periodIndex) {
    final start = periodIndex * 2 + 1;
    for (final course in courses) {
      if (course.dayOfWeek == dayOfWeek &&
          course.periodStart <= start &&
          course.periodEnd >= start + 1) {
        return course;
      }
    }
    return null;
  }

  Widget _courseCell(Course course) {
    final color = courseColor(course.color);
    return GestureDetector(
      onTap: () => onCourseTap?.call(course),
      child: Container(
        width: 74,
        height: 72,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              course.name,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (course.teacher.isNotEmpty)
              Text(
                course.teacher,
                style: TextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.75),
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, {
    bool isHeader = false,
    required Color borderColor,
    required Color headerColor,
  }) {
    return Container(
      width: width,
      height: isHeader ? 34 : 72,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        color: isHeader ? headerColor : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? FontWeight.w500 : FontWeight.normal,
          color: isHeader ? null : CupertinoColors.systemGrey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
