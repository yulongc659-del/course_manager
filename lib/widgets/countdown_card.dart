import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../models/course.dart';
import 'glass.dart';

class CountdownCard extends StatelessWidget {
  final Exam exam;
  final Course? course;
  final VoidCallback? onTap;

  const CountdownCard({
    super.key,
    required this.exam,
    this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final examDate = DateFormat('yyyy-MM-dd').parse(exam.date);
    final daysLeft = examDate.difference(today).inDays;
    final isExpired = exam.date.compareTo(todayStr) < 0;
    final isToday = exam.date == todayStr;

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isToday ? 2 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exam.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _buildStatusBadge(isExpired, isToday, daysLeft),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.book, size: 14, color: CupertinoColors.systemGrey),
              const SizedBox(width: 4),
              Text(course?.name ?? '未知课程',
                  style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 14, color: CupertinoColors.systemGrey),
              const SizedBox(width: 4),
              Text('${exam.date} ${exam.time}',
                  style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              if (exam.location.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.location, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Text(exam.location,
                    style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
            ],
          ),
          if (!isExpired) ...[
            const SizedBox(height: 12),
            AppleProgressBar(value: _progressValue(daysLeft)),
            const SizedBox(height: 4),
            Text(
              isToday ? '就是今天！' : '还剩 $daysLeft 天',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: daysLeft <= 1
                    ? CupertinoColors.systemRed
                    : daysLeft <= 7
                        ? CupertinoColors.systemOrange
                        : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired, bool isToday, int daysLeft) {
    String text;
    Color color;
    if (isExpired) {
      text = '已结束';
      color = CupertinoColors.systemGrey;
    } else if (isToday) {
      text = '今天';
      color = CupertinoColors.systemRed;
    } else if (daysLeft <= 7) {
      text = '即将到来';
      color = CupertinoColors.systemOrange;
    } else {
      text = '$daysLeft 天';
      color = CupertinoColors.systemBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }

  double _progressValue(int daysLeft) {
    if (daysLeft >= 90) return 0.05;
    if (daysLeft <= 0) return 0.95;
    return 1.0 - (daysLeft / 100);
  }
}
