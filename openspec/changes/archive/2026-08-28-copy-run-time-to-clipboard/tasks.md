## 1. Shared Copyable Run-Time Widget

- [x] 1.1 Create `CopyableRunTime` in `lib/widgets/timer_toggle_button.dart` (or a new `lib/widgets/copyable_run_time.dart`): renders `Text(display, style: style)` wrapped in a `GestureDetector` whose `onLongPress` copies `display` via `Clipboard.setData` and shows a `SnackBar` ("Copied to clipboard") via `ScaffoldMessenger.of(context)`, hiding any currently-shown SnackBar first; verify with a standalone widget test asserting long-press copies the given string and shows the SnackBar text (created `lib/widgets/copyable_run_time.dart`; discovered and worked around a real-Clipboard-API hang in this test environment — see design.md risks)
- [x] 1.2 Guard the post-copy `SnackBar` call with a `mounted` check (the widget must be a `StatefulWidget` or otherwise track mount state, since `Clipboard.setData` is async); verify via a test that disposes the widget mid-copy and asserts no error is thrown

## 2. Wire `TimerDialog`

- [x] 2.1 Replace the Stopped-phase duration `Text` in `TimerDialog` with `CopyableRunTime`; the Idle/Running-phase clock `Text` remains a plain `Text` (no long-press); verify via a test that long-pressing the duration in the Stopped phase copies the correct value and shows the SnackBar
- [x] 2.2 Add a test confirming long-press on the Idle/Running clock (before Stop) has no effect: no clipboard write, no SnackBar

## 3. Wire `QuickMeasureScreen`

- [x] 3.1 Replace the `quick_elapsed` `Text` with `CopyableRunTime` when `_phase == QuickPhase.idle`; when `_phase == QuickPhase.running`, keep rendering a plain `Text` (no long-press) with the same key and style; verify via a test that long-pressing the clock while idle-with-a-duration copies the correct value and shows the SnackBar
- [x] 3.2 Add a test confirming long-press on the clock while Running has no effect: no clipboard write, no SnackBar
- [x] 3.3 Add a test confirming long-press on the clock while Idle with no prior result (`00:00.00`) still copies that displayed string (`"00:00.00"`) — the requirement is about the frozen/non-live state, not about a nonzero duration existing

## 4. Verification and Regression

- [x] 4.1 Add a test confirming a second rapid long-press replaces rather than stacks the SnackBar (via `hideCurrentSnackBar` before showing the new one)
- [x] 4.2 Run `flutter analyze` and the full `flutter test` suite; verify zero analyzer issues and all tests passing

## 5. Documentation

- [x] 5.1 Note the long-press-to-copy affordance in `docs/sdlc/FEATURE/climberapp-session-timer.md` (Timer Dialog Phase State Machine / Save-Cancel description) and `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md` (Quick's frozen-duration display), pointing at `openspec/specs/run-time-clipboard-copy/spec.md`
