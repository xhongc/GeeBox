import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

void showChansonToast(
  BuildContext context,
  String message, {
  bool destructive = false,
}) {
  showFToast(
    context: context,
    variant: destructive ? FToastVariant.destructive : FToastVariant.primary,
    title: Text(message),
  );
}

class ChansonAlert extends StatelessWidget {
  final String title;
  final String message;
  final FAlertVariant variant;

  const ChansonAlert({
    super.key,
    required this.title,
    required this.message,
    this.variant = FAlertVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return FAlert(
      variant: variant,
      title: Text(title),
      subtitle: Text(message),
    );
  }
}

class ChansonEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const ChansonEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: theme.colors.mutedForeground),
          const SizedBox(height: 14),
          Text(
            message,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
