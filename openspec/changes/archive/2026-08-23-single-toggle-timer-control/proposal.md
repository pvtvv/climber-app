## Why

Both timing surfaces should present the run-measurement control as a single toggling button (label swaps Start ↔ Stop on tap) rather than two simultaneously-visible buttons. This supersedes the direction taken in `docs/sdlc/FEATURE/climberapp-start-stop-layout-design.md` and the now-deleted `tap-to-time-interaction-states` / `quick-measure-dual-button-layout` OpenSpec changes, which were porting `TimerDialog`'s dual always-visible Start/Stop buttons to `QuickMeasureScreen`. The user has since decided the dual-button pattern is not the intended design for either surface — `TimerDialog` itself must move to a single toggling button, and `QuickMeasureScreen` should adopt the same single-button pattern (closer to its pre-existing shape) rather than the dual-button one.

## What Changes

- **BREAKING**: `TimerDialog` (Session flow, reached via "Tap to time…") changes from two always-visible Start/Stop buttons (162/90px height swap) to a single button whose label toggles between "Start" and "Stop" as the run is measured. The Save/Cancel split shown after Stop is unchanged.
- `QuickMeasureScreen` (Quick run flow) keeps/adopts the same single toggling button for Start/Stop while measuring.
- **BREAKING**: `QuickMeasureScreen` drops its distinct Result phase ("Result saved" label + separate Retake button). Tapping Stop auto-saves the result silently (as today) and the same button immediately reads "Start" again, ready for the next run — no separate result screen or Retake control.
- Interaction-state guarantees already decided in the deleted `tap-to-time-interaction-states` change (default Material hover/press, silent disabled-tap, default keyboard focus, no custom wrappers) carry forward unchanged in spirit, restated here for a single-button control instead of a two-button pair. The Save/Cancel green/red color exception for `TimerDialog`'s post-Stop phase also carries forward unchanged.
- Corresponding updates to `docs/sdlc/FEATURE/climberapp-session-timer.md` (Timer Dialog Phase State Machine and DoDs currently describe the dual-button behavior as fact) and `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md` (owns Quick's phase state machine, auto-persist-on-stop, and the Retake DoD being removed).
- `docs/sdlc/FEATURE/climberapp-start-stop-layout-design.md` is superseded by this change and should be marked as such (its entire premise — porting the dual-button pattern to Quick — no longer applies).

## Capabilities

### New Capabilities
- `timer-toggle-control`: the single-button toggle control (Start↔Stop label swap, counter behavior, interaction-state contract) shared by `TimerDialog` and `QuickMeasureScreen`, plus each surface's post-Stop behavior (Session: Save/Cancel split; Quick: silent auto-save with immediate return to "Start").

### Modified Capabilities
(none — no capability has been archived to `openspec/specs/` yet; the two prior changes describing the dual-button direction were deleted rather than superseded via a delta, since they were never archived)

## Impact

- **Code**: `lib/widgets/timer_dialog.dart` — replace the dual Start/Stop `SizedBox` pair with a single toggling button; Save/Cancel result phase unchanged. `lib/screens/quick_measure_screen.dart` — collapse `QuickPhase.result` into the Idle/Running toggle (remove the Result UI branch, `quick_result_label`, and the Retake-specific button while keeping the underlying auto-persist call).
- **Tests**: `test/widgets/timer_dialog_test.dart` (already written for the two-button design; must be rewritten for the single toggling button) and `test/screens/quick_measure_screen_test.dart` (several existing assertions, e.g. `'opens in Result when cached quick result exists'`, are built around the Result phase being removed and must be updated).
- **Docs**: `climberapp-session-timer.md`, `climberapp-measurement-mode-entry.md` updated for accuracy; `climberapp-start-stop-layout-design.md` marked superseded.
