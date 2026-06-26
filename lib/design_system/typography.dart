import 'package:flutter/cupertino.dart';

class AppTypography {
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );

  static const callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static TextStyle secondary(BuildContext context) =>
      footnote.copyWith(color: CupertinoColors.systemGrey);

  static TextStyle tertiary(BuildContext context) =>
      caption1.copyWith(color: CupertinoColors.systemGrey);
}
