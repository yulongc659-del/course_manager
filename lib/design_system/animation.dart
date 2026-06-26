import 'package:flutter/cupertino.dart';

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve spring = Curves.easeOutBack;
  static const Curve ease = Curves.easeInOut;

  static Animation<double> scaleTap(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: controller, curve: ease),
    );
  }

  static PageRouteBuilder pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: ease)),
            child: child,
          ),
        );
      },
      transitionDuration: normal,
    );
  }
}
