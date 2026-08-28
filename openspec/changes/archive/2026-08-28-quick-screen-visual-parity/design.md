## Context

`TimerDialog` (`lib/widgets/timer_dialog.dart`) renders its clock (`displayMedium` + `tabularFigures` + `w600`, centered) and its single toggle button (162px `FilledButton`, label at `labelLarge` + `fontSize: 21`) inside a `Dialog` with `insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24)` and an inner `Padding(24)`, in a `Column(mainAxisSize: MainAxisSize.min)` — which is what makes the dialog box appear as a compact, vertically-centered card on screen. `QuickMeasureScreen` (`lib/screens/quick_measure_screen.dart`) currently declares its own, plainer clock style (`displayMedium` with no overrides) and its own unstyled button label, in a `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` pinned to the top of the `Scaffold` body. See `proposal.md` for the motivation; see `openspec/specs/timer-toggle-control/spec.md` for the existing single-toggle-button requirements this change extends.

## Goals / Non-Goals

**Goals:**
- Extract `TimerDialog`'s clock style and toggle-button widget into shared code that both surfaces call, so they cannot independently drift.
- Make `QuickMeasureScreen`'s content column visually centered on screen, matching where `TimerDialog`'s dialog box sits, without converting Quick into an actual dialog/overlay.
- Keep the change presentation-only: no phase-logic, persistence, or interaction-state behavior changes.

**Non-Goals:**
- Does not change `QuickMeasureScreen`'s full-screen `Scaffold` surface type (still governed by `cpt-climberapp-dod-measurement-mode-entry-quick-full-screen`, unchanged).
- Does not touch `TimerDialog`'s Save/Cancel result phase, or `QuickMeasureScreen`'s auto-persist-on-stop behavior.
- Does not introduce a design-system/theming layer beyond what's needed for this one shared clock/button pair.

## Decisions

**D1 — Extract a shared `TimerToggleButton` widget and a shared clock text-style helper into a new file, `lib/widgets/timer_toggle_button.dart`.**
`TimerToggleButton` takes `{required bool isRunning, required VoidCallback? onStart, required VoidCallback? onStop}` and renders the exact 162px `SizedBox` + `FilledButton` + `labelLarge`-`fontSize:21` label that `TimerDialog` already has, with the label and handler chosen from `isRunning`. A top-level `elapsedClockTextStyle(BuildContext)` function returns `Theme.of(context).textTheme.displayMedium?.copyWith(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w600)`. Both `TimerDialog` and `QuickMeasureScreen` are edited to call these instead of declaring their own copies.
Alternative considered: leave both files with independently-declared-but-matching style values (as `climberapp-start-stop-layout-design.md`'s original, now-superseded approach did) — rejected per the explicit request to reuse components, not duplicate matching values; duplication is exactly what let Quick's styling drift from `TimerDialog`'s in the first place.

**D2 — Center `QuickMeasureScreen`'s content column with `Center` + `Column(mainAxisSize: MainAxisSize.min)`, mirroring `TimerDialog`'s `Dialog` + `Column(mainAxisSize: MainAxisSize.min)` shape.**
Wrap the existing `Padding(24)` content in a `Center` widget inside the `Scaffold` body, and change the inner `Column`'s `mainAxisSize` to `min` (dropping `crossAxisAlignment: stretch` in favor of a fixed-width `SizedBox`-wrapped button, matching how `TimerDialog` constrains its button width). This reproduces the same "compact, vertically-centered content block" visual position as the dialog, without making Quick an actual `Dialog`/overlay — it's still a full-screen `Scaffold`, just with its content centered rather than top-pinned.
Alternative considered: keep top-pinned content and only fix typography — rejected; the user explicitly asked for matching *position*, and top-pinned vs. centered is a real, visible difference from `TimerDialog`.

**D3 — Button width**: `TimerDialog`'s button fills the Dialog's content width (bounded by `insetPadding` 24 each side); to match, `QuickMeasureScreen`'s centered column uses the same 24px horizontal padding and a `SizedBox(width: double.infinity, height: 162)` for the button, so both surfaces' buttons span the same proportion of screen width.

## Risks / Trade-offs

- [Risk] Centering content vertically on a full-screen surface can look different across screen sizes/orientations than a fixed-size dialog box does — Quick's content will now float in empty space above and below on a tall screen, whereas `TimerDialog`'s dialog box is already meant to be compact — Mitigation: this is the explicitly requested behavior (match the dialog's visual position); no further scope beyond matching it.
- [Risk] Extracting shared widgets touches `TimerDialog`, which is otherwise stable, implemented, and covered by tests — Mitigation: `TimerToggleButton` reproduces `TimerDialog`'s exact existing widget tree (same `SizedBox`/`FilledButton`/`Text` shape), so `test/widgets/timer_dialog_test.dart`'s existing assertions (button type, text, no custom wrapper) should continue to pass unmodified; any failure indicates an unintended shape change, not just a refactor.
- [Risk] `elapsedClockTextStyle` centralizes a style used only twice today — a minor abstraction for a small duplication — Mitigation: justified specifically because the proposal requires reuse, not just duplicate-but-matching values; it's the smallest unit that satisfies that requirement.
