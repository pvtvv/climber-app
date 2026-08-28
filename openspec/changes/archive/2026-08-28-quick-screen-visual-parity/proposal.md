## Why

`QuickMeasureScreen` and `TimerDialog` currently implement visually similar but independently-declared controls (matching heights, but Quick lacks `TimerDialog`'s clock typography, button label typography, and centered content positioning, and duplicates rather than reuses the styling values). The user wants the two surfaces to be visually indistinguishable in their shared content — same position, element design, alignment, colors, and fonts — achieved by having `QuickMeasureScreen` actually reuse the components/styling `TimerDialog` uses, not by independently re-declaring matching values that can drift apart later. `QuickMeasureScreen` remains a full-screen `Scaffold` (per the existing, unchanged `cpt-climberapp-dod-measurement-mode-entry-quick-full-screen` DoD) — this change is about the visual content within that screen matching `TimerDialog`'s content, not about converting Quick into a modal dialog.

## What Changes

- Extract `TimerDialog`'s clock text style and toggle-button style/label-style into shared, reusable code (e.g. a small shared widget or style-constant module under `lib/widgets/`), and have both `TimerDialog` and `QuickMeasureScreen` consume it, so the two surfaces cannot visually drift apart from independent duplication.
- Apply that shared clock typography (`displayMedium` + `tabularFigures` + `w600`, centered) and button label typography (`labelLarge` + `fontSize: 21`) to `QuickMeasureScreen`, matching `TimerDialog` exactly.
- Reposition `QuickMeasureScreen`'s content column to be vertically centered within the `Scaffold` body — matching where `TimerDialog`'s compact `Dialog` box visually sits on screen (centered), rather than pinned to the top under the AppBar. `TimerDialog`'s modal `Dialog` presentation and `PopScope`/leave-guard behavior are unchanged; only `QuickMeasureScreen`'s content position moves.
- Preserve `TimerDialog`'s existing `insetPadding`/content-padding proportions so both surfaces' content occupies the same horizontal width band on screen.
- No change to either surface's phase/state logic, persistence, or the `timer-toggle-control` interaction-state contract (default hover/press/disabled-tap/focus, Save/Cancel color exception) established in the archived `single-toggle-timer-control` change — this change is presentation-only.
- Add acceptance criteria/tests that directly verify `QuickMeasureScreen`'s clock style, button style, and content position match `TimerDialog`'s, so future changes to one surface's styling are caught if the other isn't updated to match.

## Capabilities

### Modified Capabilities
- `timer-toggle-control`: adds requirements for shared component reuse and matching visual presentation (typography, alignment, centered position) between `TimerDialog` and `QuickMeasureScreen`, extending the existing single-toggle-button requirements already recorded there.

### New Capabilities
(none)

## Impact

- **Code**: `lib/widgets/timer_dialog.dart` (extract shared clock/button styling into reusable code, otherwise unchanged), `lib/screens/quick_measure_screen.dart` (consume the shared styling; recenter content column vertically).
- **Tests**: `test/widgets/timer_dialog_test.dart`, `test/screens/quick_measure_screen_test.dart` — new assertions comparing resolved `TextStyle`s and button heights/positions between the two surfaces (or against the shared constant/widget directly).
- **Docs**: `docs/sdlc/FEATURE/climberapp-session-timer.md` and `docs/sdlc/FEATURE/climberapp-measurement-mode-entry.md` — note the shared-component relationship where relevant; the full-screen DoD in the latter is unaffected and unchanged.
