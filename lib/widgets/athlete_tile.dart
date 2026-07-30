import 'package:flutter/material.dart';
import 'package:climber_app/models/athlete.dart';
import 'package:climber_app/models/athlete_palette.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/widgets/runs_table.dart';
import 'package:climber_app/widgets/timer_dialog.dart';

class AthleteTile extends StatelessWidget {
  const AthleteTile({
    super.key,
    required this.athlete,
    required this.expanded,
    required this.onToggle,
    required this.controller,
    this.timingInProgress,
    this.onLeaveWhileRunning,
  });

  final Athlete athlete;
  final bool expanded;
  final VoidCallback onToggle;
  final SessionController controller;
  final ValueNotifier<bool>? timingInProgress;
  final Future<void> Function()? onLeaveWhileRunning;

  @override
  Widget build(BuildContext context) {
    final color = colorForIndex(athlete.colorIndex);
    final hasPending = athlete.runs.any((r) => r.isPending);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(
                athlete.name.isNotEmpty
                    ? athlete.name.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(athlete.name),
            subtitle: Text(
              '${athlete.runs.where((r) => !r.isPending).length} run(s)',
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onTap: onToggle,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RunsTable(
                runs: athlete.runs,
                hasPending: hasPending,
                onAddPending: () => controller.addPendingRun(athlete.id),
                onSortByTime: () => controller.sortByTime(athlete.id),
                onPendingTap: () async {
                  final ms = await showTimerDialog(
                    context,
                    timingInProgress: timingInProgress,
                    onLeaveWhileRunning: onLeaveWhileRunning,
                  );
                  if (ms == null) {
                    await controller.discardPending(athlete.id);
                  } else {
                    await controller.saveRun(athlete.id, ms);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
