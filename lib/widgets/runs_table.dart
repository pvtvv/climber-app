import 'package:flutter/material.dart';
import 'package:climber_app/models/run.dart';
import 'package:climber_app/models/time_format.dart';

class RunsTable extends StatelessWidget {
  const RunsTable({
    super.key,
    required this.runs,
    required this.onAddPending,
    required this.onPendingTap,
    required this.onSortByTime,
    this.hasPending = false,
  });

  final List<Run> runs;
  final VoidCallback onAddPending;
  final VoidCallback onPendingTap;
  final VoidCallback onSortByTime;
  final bool hasPending;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Runs',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: runs.where((r) => !r.isPending).length >= 2
                  ? onSortByTime
                  : null,
              icon: const Icon(Icons.sort, size: 18),
              label: const Text('Sort by time'),
            ),
            IconButton(
              tooltip: hasPending
                  ? 'Finish or discard the pending run first'
                  : 'Add run',
              onPressed: hasPending ? null : onAddPending,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (runs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No runs yet. Tap + to time a run.'),
          )
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2.5),
            },
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Run #',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Time',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Date / Time',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              ...runs.map((run) {
                final isPending = run.isPending;
                final timeText = isPending
                    ? 'Tap to time…'
                    : formatDurationMs(run.durationMs);
                final dateTimeText = isPending || run.completedAt == null
                    ? ''
                    : _formatDateTime(run.completedAt!);
                return TableRow(
                  children: [
                    TableRowInkWell(
                      onTap: isPending ? onPendingTap : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '${run.runNumber}',
                          style: TextStyle(
                            fontStyle:
                                isPending ? FontStyle.italic : FontStyle.normal,
                            color: isPending
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                    TableRowInkWell(
                      onTap: isPending ? onPendingTap : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          timeText,
                          style: TextStyle(
                            fontStyle:
                                isPending ? FontStyle.italic : FontStyle.normal,
                            color: isPending
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    TableRowInkWell(
                      onTap: isPending ? onPendingTap : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          dateTimeText,
                          style: TextStyle(
                            fontStyle:
                                isPending ? FontStyle.italic : FontStyle.normal,
                            color: isPending
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute:$second';
  }
}
