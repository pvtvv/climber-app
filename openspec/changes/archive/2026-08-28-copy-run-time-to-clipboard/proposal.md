## Why

Coaches and climbers currently have no way to get a captured run duration out of the app except by manually re-typing what they read on screen. Both timing surfaces (`TimerDialog` and `QuickMeasureScreen`) already freeze and display a final duration once a run stops; adding long-press-to-copy on that frozen display lets the operator paste the value elsewhere (a spreadsheet, a message, another app) without transcription errors.

## What Changes

- Add a long-press gesture (Flutter's standard ~500ms `onLongPress` threshold) on the frozen run-time display:
  - On `TimerDialog`, active only while showing the frozen duration alongside Save/Cancel (the Stopped phase) — not while idle or running.
  - On `QuickMeasureScreen`, active only when the clock shows a frozen completed/cached duration in the Idle phase (i.e., whenever the button reads "Start" and a duration is displayed) — not while Running.
- On a successful long-press, copy the exact displayed formatted string (e.g. `"00:12.34"`) to the system clipboard.
- Show a brief bottom notification (`SnackBar`) confirming "Copied to clipboard", visible for a short, typical duration (~2-3 seconds) before it auto-dismisses.
- The copied value remains on the clipboard after the operator navigates away from the screen or leaves the app entirely, so it can be pasted into any other app.
- No change to existing Start/Stop/Save/Cancel behavior, phase transitions, or persistence — this is an additive interaction on the already-displayed frozen duration.

## Capabilities

### New Capabilities
- `run-time-clipboard-copy`: long-press-to-copy behavior on the frozen run-time display, shared by `TimerDialog` and `QuickMeasureScreen`, including the copied value format and the confirmation notification.

### Modified Capabilities
(none)

## Impact

- **Code**: `lib/widgets/timer_dialog.dart` (long-press on the frozen clock in the Stopped phase), `lib/screens/quick_measure_screen.dart` (long-press on the clock when idle with a displayed duration). Likely a small shared helper (e.g. in `lib/widgets/timer_toggle_button.dart` or a new sibling file) for the copy-and-notify behavior, consistent with the existing shared-component approach from `quick-screen-visual-parity`.
- **Dependencies**: Flutter's `Clipboard` (`services.dart`, already part of the Flutter SDK — no new package dependency).
- **Tests**: `test/widgets/timer_dialog_test.dart`, `test/screens/quick_measure_screen_test.dart` — new tests asserting long-press copies the correct clipboard value and shows the confirmation `SnackBar`, and that long-press has no effect while Running/Idle-without-a-result.
- **Docs**: `docs/sdlc/FEATURE/climberapp-session-timer.md` and `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md` — note the new copy affordance where the frozen-duration display is described.
