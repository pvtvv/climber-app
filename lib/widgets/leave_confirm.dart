import 'package:flutter/material.dart';

/// @cpt-flow:cpt-climberapp-flow-measurement-mode-entry-leave-while-running:p1
Future<bool> confirmLeaveWhileRunning(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: const Text(
        'Leave? Your in-progress timing will be discarded.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return leave ?? false;
}
