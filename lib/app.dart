import 'package:flutter/cupertino.dart';
import 'pages/timetable/timetable_page.dart';
import 'pages/timetable/course_form_page.dart';
import 'pages/homework/homework_list_page.dart';
import 'pages/homework/homework_form_page.dart';
import 'pages/exam/exam_list_page.dart';
import 'pages/exam/exam_form_page.dart';
import 'pages/course_detail/course_detail_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/import/import_page.dart';
import 'widgets/glass.dart';

class CourseManagerApp extends StatelessWidget {
  const CourseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '课程管理器',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: CupertinoColors.label,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;
    bool fullScreenDialog = false;

    switch (settings.name) {
      case '/':
        return CupertinoPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case '/course/edit':
        page = const CourseFormPage();
        break;
      case '/course/detail':
        page = const CourseDetailPage();
        break;
      case '/homework/edit':
        page = const HomeworkFormPage();
        break;
      case '/exam/edit':
        page = const ExamFormPage();
        break;
      case '/settings':
        page = const SettingsPage();
        break;
      case '/import':
        page = const ImportPage();
        break;
      default:
        return null;
    }

    return CupertinoPageRoute(
      builder: (_) => page,
      settings: settings,
      fullscreenDialog: fullScreenDialog,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    TimetablePage(),
    HomeworkListPage(),
    ExamListPage(),
  ];

  final _navItems = const [
    BottomNavItem(
      icon: CupertinoIcons.calendar,
      activeIcon: CupertinoIcons.calendar,
      label: '课表',
    ),
    BottomNavItem(
      icon: CupertinoIcons.doc_text,
      activeIcon: CupertinoIcons.doc_text,
      label: '作业',
    ),
    BottomNavItem(
      icon: CupertinoIcons.clock,
      activeIcon: CupertinoIcons.clock_solid,
      label: '考试',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          if (isWide) {
            return _buildWideLayout(isWide);
          }
          return _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout(bool isWide) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 80,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey5, context),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_navItems.length, (i) {
              final selected = i == _currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? _navItems[i].activeIcon : _navItems[i].icon,
                        size: 24,
                        color: selected
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _navItems[i].label,
                        style: TextStyle(
                          fontSize: 11,
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
        Container(width: 1, color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey5, context)),
        Expanded(child: _pages[_currentIndex]),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(child: _pages[_currentIndex]),
        AppleBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ],
    );
  }
}
