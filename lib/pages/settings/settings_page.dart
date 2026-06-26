import 'package:flutter/cupertino.dart';
import '../../models/course.dart';
import '../../services/settings_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _weekOffsetController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _apiKeyController.text = await SettingsService.getApiKey();
    _baseUrlController.text = await SettingsService.getBaseUrl();
    _weekOffsetController.text = (await SettingsService.getWeekOffset()).toString();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _weekOffsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('设置')),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('设置')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('DeepSeek API',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('用于 AI 课程总结。',
                style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _baseUrlController,
              placeholder: 'API 地址',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              onChanged: (v) => SettingsService.setBaseUrl(v.trim()),
            ),
            const SizedBox(height: 16),
            const Text('周数调整',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('如果当前周计算不对，调整偏移量。正值=往后推，负值=往前移。',
                style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _weekOffsetController,
              placeholder: '周数偏移（如 -1, 0, 2）',
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              onChanged: (v) => SettingsService.setWeekOffset(int.tryParse(v.trim()) ?? 0),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/widget-preview'),
                child: const Row(children: [
                  Icon(CupertinoIcons.square_grid_2x2, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Widget 小组件预览', style: TextStyle(fontSize: 15))),
                  Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _apiKeyController,
              placeholder: 'API Key',
              obscureText: true,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              onChanged: (v) => SettingsService.setApiKey(v.trim()),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: Text('已保存'),
                        content: Text('设置已自动保存'),
                        actions: [CupertinoDialogAction(
                          child: const Text('好'),
                          onPressed: () => Navigator.pop(context),
                        )],
                      ),
                    );
                  },
                  child: const Text('确认保存'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('数据维护',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              child: GestureDetector(
                onTap: () async {
                  final sem = await SemesterService().getCurrent();
                  if (sem == null) return;
                  final courses = await CourseService().getBySemester(sem.id);
                  for (final c in courses) {
                    final updated = Course(
                      id: c.id, semesterId: c.semesterId, name: c.name,
                      teacher: c.teacher, classroom: c.classroom,
                      dayOfWeek: c.dayOfWeek, periodStart: c.periodStart, periodEnd: c.periodEnd,
                      weekStart: c.weekStart, weekEnd: c.weekEnd,
                      color: nameBasedColor(c.name),
                      createdAt: c.createdAt,
                    );
                    await CourseService().update(updated);
                  }
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text('完成'),
                        content: Text('已更新 ${courses.length} 门课程的颜色'),
                        actions: [CupertinoDialogAction(child: const Text('好'), onPressed: () => Navigator.pop(context))],
                      ),
                    );
                  }
                },
                child: const Row(children: [
                  Icon(CupertinoIcons.paintbrush, size: 20),
                  SizedBox(width: 12),
                  Text('统一课程颜色', style: TextStyle(fontSize: 15)),
                  Spacer(),
                  Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            const Text('关于',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info, size: 20, color: CupertinoColors.systemGrey),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('课程管理器', style: TextStyle(fontSize: 15)),
                      Text('v1.1 · 数据本地存储',
                          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
