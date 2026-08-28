## Context

`TimerDialog` (`lib/widgets/timer_dialog.dart`) currently implements the dual always-visible Start/Stop pair (162/90px height swap) that this change replaces with a single toggling button; its Save/Cancel result phase (green/red `FilledButton`s at 56px) is unchanged. `QuickMeasureScreen` (`lib/screens/quick_measure_screen.dart`) currently has a `QuickPhase` enum of `{idle, running, result}`; this change collapses that to effectively `{idle, running}` from a UI perspective (see D2). Two prior OpenSpec changes (`tap-to-time-interaction-states`, `quick-measure-dual-button-layout`) pursued the opposite direction — porting the dual-button pattern to Quick — and were deleted rather than revised, per user decision, since neither had been archived and both were built on the now-rejected premise. See `proposal.md` for the full motivation.

## Goals / Non-Goals

**Goals:**
- Replace `TimerDialog`'s dual-button control with a single toggling button; keep its Save/Cancel result phase exactly as it exists today.
- Give `QuickMeasureScreen` the same single toggling button, and remove its distinct Result/Retake phase in favor of immediate auto-save + return-to-Start.
- Restate the interaction-state contract (default hover/press/focus, silent disabled-tap, no custom wrappers) for a single-button control, since the prior spec's "dual buttons always visible" framing no longer applies.
- Update the FEATURE docs that currently describe the dual-button behavior as fact, and mark `climberapp-start-stop-layout-design.md` superseded.

**Non-Goals:**
- No change to the underlying `TimerEngine`/timer tick mechanics, to `climber_session_v1`/`climber_quick_v1` persistence formats, or to Session's athlete-roster/run-table behavior.
- No change to Quick's auto-persist-on-stop *mechanism* (still saves via `QuickStore` on Stop) — only to what the UI shows immediately after.
- Does not reintroduce a height-swap contract; the single button uses one consistent height on both surfaces (see D3).

## Decisions

**D1 — `TimerDialog`'s Start/Stop become one `FilledButton` whose `onPressed` and label are derived from `TimerEngine.phase`, not two `SizedBox`-wrapped buttons.**
The current `phase == idle ? 162 : 90` height-swap logic and the second `FilledButton.tonal` for Stop are removed entirely. One button: `onPressed: phase == running ? _onStop : _onStart`, `child: Text(phase == running ? 'Stop' : 'Start')`. The Save/Cancel branch (`phase == stopped`) is untouched.
Alternative considered: keep two `SizedBox`-wrapped buttons but hide the inactive one — rejected, since that's materially the "single visible button" behavior already, but keeping the dead code/height contract around invites drift back toward the dual-button reading. A clean single-widget implementation is simpler and matches the spec's actual intent.

**D2 — `QuickMeasureScreen`'s `QuickPhase.result` is removed from the UI's phase-conditional rendering; the enum is simplified to `{idle, running}`.**
On Stop: call `_store.save(result)` (unchanged), then `setState` back to `idle` with `_displayMs` set to the just-completed duration (not reset to zero) — mirroring D1's engine-driven idle/running behavior on `TimerDialog`, but idle's displayed value is the last known duration rather than always zero. Tapping Start from this state resets `_displayMs` to zero and proceeds as a normal run start. On screen open with a cached `QuickResult`, `_displayMs` is seeded from the cache and phase is `idle` (never `result`) — the button always reads "Start" whenever idle, whether that's a fresh idle state or one showing a just-completed/cached duration.
Alternative considered: keep a `result` enum value internally for persistence-timing logic while treating it identically to idle in the UI — rejected as needless indirection; if `result` carries no distinct UI behavior, it isn't a distinct phase from this component's perspective anymore.

**D3 — Single consistent button height on both surfaces; no height-swap contract.**
Since there is only one button, there's nothing to swap heights against. Use 162 logical pixels (the "big button" size already established for `TimerDialog`'s active state) as the constant height on both surfaces, so the visual weight of the primary timing control stays consistent with what's already shipped, without a second inactive-height value to maintain.
Alternative considered: revert to Quick's pre-existing unconstrained/default button height — rejected; there's no reason for the two surfaces' primary control to differ in size now that both are single-button, and 162px is already validated (via `cebb61e`, cited in `climberapp-start-stop-layout-design.md`) as the intended size for this control.

**D4 — Interaction-state requirements restated, not reinvented.**
The default-hover/press/focus/no-haptic/silent-disabled-tap decisions from the deleted `tap-to-time-interaction-states` change were about *how any button on these surfaces behaves*, not specifically about there being two of them. They're restated in `specs/timer-toggle-control/spec.md` for the single toggle button and for Save/Cancel, unchanged in substance. The "No Double-Fire on Rapid Repeated Tap" and "Dual Start/Stop Always Visible" requirements from that deleted change are dropped outright (not restated) since they were specific to the two-button design; D1's single-`onPressed`-source-of-truth approach makes double-fire structurally moot the same way the original phase-gating did.

## Risks / Trade-offs

- [Risk] Removing `QuickPhase.result` changes what `test/screens/quick_measure_screen_test.dart` currently asserts (e.g. `'opens in Result when cached quick result exists'` checks for `quick_result_label`, which no longer exists) → Mitigation: `tasks.md` scopes exactly which assertions are rewritten and why; this is expected fallout from D2, not an accidental regression.
- [Risk] A user stopping a Quick run and immediately reading the frozen duration, then tapping Start again, overwrites that result without an explicit Retake confirmation step that existed before → Mitigation: this is the explicitly requested behavior (no separate result phase); the underlying persistence still occurred on Stop, so the prior result isn't lost until a *new* run is both started and stopped.
- [Risk] `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md`'s Retake DoD and Quick phase state machine become inaccurate once this ships → Mitigation: explicitly scoped as a task in this change (per user confirmation) rather than left to drift.

## Migration Plan

No data migration — `QuickResult`/`climber_quick_v1` persistence is unchanged; only the UI's phase-to-widget mapping changes. Rollback is a revert of `lib/widgets/timer_dialog.dart`, `lib/screens/quick_measure_screen.dart`, and their test files.
