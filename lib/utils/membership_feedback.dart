import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

class MembershipFeedback {
  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final actionColor = theme.colorScheme.primary;
    final dialog = Platform.isIOS
        ? CupertinoAlertDialog(
            title: Text(title, style: theme.textTheme.titleMedium),
            content: Text(message, style: theme.textTheme.bodyMedium),
            actions: [
              CupertinoDialogAction(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                isDefaultAction: true,
                child: Text('OK', style: TextStyle(color: actionColor)),
              ),
            ],
          )
        : AlertDialog(
            title: Text(title, style: theme.textTheme.titleMedium),
            content: Text(message, style: theme.textTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text('OK', style: TextStyle(color: actionColor)),
              ),
            ],
          );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
  }

  static Widget loadingOverlay(
    BuildContext context, {
    required bool isLoading,
    required Widget child,
  }) {
    if (!isLoading) return child;
    final theme = Theme.of(context);
    final lbTheme = theme.extension<LBTheme>();
    final overlayColor =
        lbTheme?.controlSurface.withOpacity(0.86) ??
        theme.colorScheme.surface.withOpacity(0.86);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: overlayColor,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      ],
    );
  }
}
