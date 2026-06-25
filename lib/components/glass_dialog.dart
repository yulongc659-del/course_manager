import 'package:flutter/cupertino.dart';

Future<void> showGlassDialog({
  required BuildContext context,
  required String title,
  String? content,
  String confirmText = '好',
  String? cancelText,
  bool destructive = false,
  VoidCallback? onConfirm,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        if (cancelText != null)
          CupertinoDialogAction(
            child: Text(cancelText),
            onPressed: () => Navigator.pop(context),
          ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          child: Text(confirmText),
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
        ),
      ],
    ),
  );
}

Future<bool?> showGlassConfirm({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '确定',
  String cancelText = '取消',
  bool destructive = false,
}) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: Text(cancelText),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          child: Text(confirmText),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
}

void showGlassSuccess({
  required BuildContext context,
  required String message,
  VoidCallback? onOk,
}) {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('完成'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: const Text('好'),
          onPressed: () {
            Navigator.pop(context);
            onOk?.call();
          },
        ),
      ],
    ),
  );
}
