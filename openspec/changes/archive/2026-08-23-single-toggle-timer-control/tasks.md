## 1. `TimerDialog`: Single Toggling Button

- [x] 1.1 Replace the dual `SizedBox`-wrapped Start/Stop buttons (`lib/widgets/timer_dialog.dart:127-154`) with a single 162px-tall `FilledButton` whose `onPressed` and label derive from `_engine.phase` per design.md D1; verify by rewriting `test/widgets/timer_dialog_test.dart`'s layout-shape assertions to expect exactly one button during idle/running
- [x] 1.2 Confirm the Save/Cancel result-phase branch is untouched; verify existing Save/Cancel behavior via a regression run of the relevant tests in `test/ui_flows_test.dart` and `test/screens/home_screen_test.dart` (required updating `ui_flows_test.dart`'s `'timer Start then Stop shows Save/Cancel'`, which asserted both Start and Stop present simultaneously — a dual-button assumption; all tests in both files now pass)

## 2. `TimerDialog`: Rewrite Interaction-State Tests for the Single Button

- [x] 2.1 Rewrite the "no custom gesture/mouse wrapper" test to check the single toggle button and the Save/Cancel controls (previously checked two separate Start/Stop buttons); verify test passes and fails if a custom wrapper is temporarily introduced
- [x] 2.2 Rewrite the rapid-repeated-tap tests: tapping the single button twice in quick succession while idle starts exactly one run (the second tap, arriving after the label has flipped to "Stop", now stops it — verify this transition is exactly one state change, not a double-start); do the same for the running→stopped transition
- [x] 2.3 Remove or rewrite the disabled-tap tests (`test/widgets/timer_dialog_test.dart`'s "Tap on disabled Stop while idle" / "Tap on disabled Start while running") since there is no longer a second, disabled button to tap in either phase — replace with a test confirming only one button exists at any given phase

## 3. `QuickMeasureScreen`: Single Toggling Button + Remove Result Phase

- [x] 3.1 Simplify `QuickPhase` usage to idle/running from the UI's perspective per design.md D2: on Stop, save via `_store.save(result)` (unchanged) then set phase to idle with `_displayMs` holding the just-completed duration; remove the `quick_result_label` Text and the dedicated Retake button; verify via rewritten tests in `test/screens/quick_measure_screen_test.dart` (also removed the now-write-only `_cachedResult` field, since nothing reads it anymore)
- [x] 3.2 On screen open with a cached `QuickResult`, seed `_displayMs` from the cache and set phase to idle (never a distinct result state); verify `'opens in Result when cached quick result exists'` is rewritten to assert idle-with-cached-duration (button reads "Start", clock shows the cached duration)
- [x] 3.3 Give the single button a 162px height (matching `TimerDialog`, per design.md D3) and remove the `Spacer`; verify via a widget-tree test asserting the button height and the absence of `Spacer`
- [x] 3.4 Confirm tapping Start after a completed/cached duration resets `_displayMs` to zero and begins a new run, overwriting the previous result on the next Stop; verify via `'Retake from Result starts new run and overwrites on Stop'` rewritten to remove the Retake-specific setup and instead tap the (now unified) Start/Stop button directly

## 4. `QuickMeasureScreen`: Interaction-State Coverage

- [x] 4.1 Add a widget-tree test asserting no custom `GestureDetector`/`MouseRegion`/`AnimatedContainer` wraps the toggle button, mirroring `TimerDialog`'s equivalent test
- [x] 4.2 Add a test confirming default press feedback only (no custom animation) is exercised structurally by confirming no such wrapper exists (same test as 4.1 covers this; no separate assertion needed beyond confirming the button's `onPressed` fires synchronously)

## 5. Documentation

- [x] 5.1 Update `docs/sdlc/FEATURE/climberapp-session-timer.md`'s Timer Dialog Phase State Machine and any DoDs describing the dual-button behavior to describe the single toggling button instead; keep the Save/Cancel description unchanged
- [x] 5.2 Update `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md`'s Quick phase state machine, the Retake DoD, and the auto-persist-on-stop DoD to reflect the removed Result phase and immediate return-to-Start behavior (renamed the two affected flow headings and the Retake DoD heading, updated their TOC entries, and added a historical note on the superseded Result→Running transition rather than deleting it silently)
- [x] 5.3 Mark `docs/sdlc/FEATURE/climberapp-start-stop-layout-design.md` as superseded by this change, with a one-line pointer to `openspec/changes/single-toggle-timer-control/` (or its archived spec, once archived)

## 6. Full Regression

- [x] 6.1 Run `flutter analyze` and the full `flutter test` suite; verify zero analyzer issues and all tests passing (rewritten + unaffected existing tests)
