import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a frozen (non-live) run-time display with long-press-to-copy: the
/// exact [display] string is copied to the clipboard and a brief
/// self-dismissing confirmation is shown. Only mount this where the
/// underlying value is frozen - do not use it for a live-updating clock.
class CopyableRunTime extends StatefulWidget {
  const CopyableRunTime({
    super.key,
    required this.display,
    this.style,
    this.textAlign,
  });

  final String display;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<CopyableRunTime> createState() => _CopyableRunTimeState();
}

class _CopyableRunTimeState extends State<CopyableRunTime> {
  Future<void> _onLongPress() async {
    await Clipboard.setData(ClipboardData(text: widget.display));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _onLongPress,
      child: Text(
        widget.display,
        textAlign: widget.textAlign,
        style: widget.style,
      ),
    );
  }
}
