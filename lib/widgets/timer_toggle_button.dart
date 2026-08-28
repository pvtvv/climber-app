import 'package:flutter/material.dart';

/// Elapsed-time clock text style shared by every timing surface: bold,
/// fixed-width digits, so a running clock doesn't visually jitter.
TextStyle? elapsedClockTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.displayMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
      );
}

/// Single toggling Start/Stop button shared by every timing surface, per
/// the `timer-toggle-control` spec: one 162px-tall control whose label and
/// handler are driven by [isRunning].
class TimerToggleButton extends StatelessWidget {
  const TimerToggleButton({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  });

  final bool isRunning;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 162,
      child: FilledButton(
        onPressed: isRunning ? onStop : onStart,
        child: Text(
          isRunning ? 'Stop' : 'Start',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 21,
              ),
        ),
      ),
    );
  }
}
