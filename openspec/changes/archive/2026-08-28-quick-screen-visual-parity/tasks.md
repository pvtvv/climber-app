## 1. Extract Shared Components

- [x] 1.1 Create `lib/widgets/timer_toggle_button.dart` with a `TimerToggleButton` widget (`isRunning`, `onStart`, `onStop`) reproducing `TimerDialog`'s existing 162px `SizedBox` + `FilledButton` + `labelLarge`/`fontSize:21` label shape exactly; verify by running the pre-existing `test/widgets/timer_dialog_test.dart` unmodified against `TimerDialog` once it's switched to use this widget (task 2.1) — all assertions must still pass
- [x] 1.2 Add `elapsedClockTextStyle(BuildContext)` to the same file (or a small sibling file), returning `displayMedium` + `tabularFigures` + `w600`; verify via a unit test asserting the returned style's `fontFeatures` and `fontWeight` (see `test/widgets/timer_toggle_button_test.dart`)

## 2. Wire `TimerDialog` to the Shared Components

- [x] 2.1 Replace `TimerDialog`'s inline toggle-button `SizedBox`/`FilledButton` with `TimerToggleButton`, and its inline clock style with `elapsedClockTextStyle(context)`; verify the full pre-existing `test/widgets/timer_dialog_test.dart` suite still passes unmodified (confirms the extraction is shape-preserving)

## 3. Wire `QuickMeasureScreen` to the Shared Components and Reposition

- [x] 3.1 Replace `QuickMeasureScreen`'s inline button with `TimerToggleButton` and its clock `Text` style with `elapsedClockTextStyle(context)`; verify via updated `test/screens/quick_measure_screen_test.dart` assertions on the clock's resolved `TextStyle` and the button's label style
- [x] 3.2 Wrap `QuickMeasureScreen`'s content in `Center` with an inner `Column(mainAxisSize: MainAxisSize.min)` (replacing the top-pinned `crossAxisAlignment: stretch` column), keeping the 24px horizontal padding and a `SizedBox(width: double.infinity, height: 162)` around the button per design.md D2/D3; verify via a new test asserting the content column's vertical center-of-mass is centered in the viewport (e.g. comparing the midpoint of the clock+button block's bounding box to the body's vertical center, within a small tolerance) or, more simply, asserting a `Center` ancestor wraps the content column (used the simpler `Center`-ancestor assertion)

## 4. Cross-Surface Verification

- [x] 4.1 Add a test (in either test file, or a new shared test file) that directly compares the `TextStyle` resolved for the clock in `TimerDialog` vs. `QuickMeasureScreen`, asserting they are equal (see `test/cross_surface_visual_parity_test.dart`)
- [x] 4.2 Add a test comparing the toggle button's resolved height (162) and label `TextStyle` (`fontSize: 21`) between the two surfaces, asserting they are equal (see `test/cross_surface_visual_parity_test.dart`)
- [x] 4.3 Run `flutter analyze` and the full `flutter test` suite; verify zero analyzer issues and all tests passing

## 5. Documentation

- [x] 5.1 Note the shared `TimerToggleButton`/`elapsedClockTextStyle` components in `docs/sdlc/FEATURE/climberapp-session-timer.md`'s Timer Dialog description (Section 1.4 or the Control shape note added previously) and in `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md` where `QuickMeasureScreen`'s presentation is described, without altering either doc's full-screen-surface DoD
