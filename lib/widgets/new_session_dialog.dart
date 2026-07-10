import 'package:flutter/material.dart';

/// New Session: Save = export then clear; Cancel = clear only.
class NewSessionDialog extends StatelessWidget {
  const NewSessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Session'),
      content: const Text(
        'Start a new session? Choose Save to export the current results as CSV first, or Cancel to clear without exporting.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('save'),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<String?> showNewSessionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const NewSessionDialog(),
  );
}
