import 'package:flutter/cupertino.dart';
import '../../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _apiKeyController.text = await SettingsService.getApiKey();
    _baseUrlController.text = await SettingsService.getBaseUrl();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
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
                      builder: (_) => const CupertinoAlertDialog(
                        title: Text('已保存'),
                        content: Text('设置已自动保存'),
                        actions: [CupertinoDialogAction(child: Text('好'))],
                      ),
                    );
                  },
                  child: const Text('确认保存'),
                ),
              ],
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
