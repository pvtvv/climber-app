## Context

`TimerDialog` (`lib/widgets/timer_dialog.dart`) shows the frozen duration as a plain `Text` in its Stopped phase (alongside Save/Cancel). `QuickMeasureScreen` (`lib/screens/quick_measure_screen.dart`) shows the frozen/cached duration as the same `Text` (keyed `quick_elapsed`) whenever `_phase == QuickPhase.idle`. Both already use the shared `elapsedClockTextStyle` helper from `lib/widgets/timer_toggle_button.dart` (`quick-screen-visual-parity`). See `proposal.md` for motivation; see `openspec/specs/run-time-clipboard-copy/spec.md` for the behavior contract.

## Goals / Non-Goals

**Goals:**
- Add long-press-to-copy on the frozen duration display on both surfaces, sharing one implementation.
- Use Flutter's standard long-press gesture and clipboard APIs — no custom timing, no new dependency.
- Keep the confirmation notification lightweight and self-dismissing.

**Non-Goals:**
- Does not add copy affordance to the live-updating clock while a run is in progress.
- Does not add any other new interaction (no copy-icon button, no share sheet, no history of past copies).
- Does not change existing phase logic, persistence, or the `timer-toggle-control` contract.

## Decisions

**D1 — Wrap the frozen-duration `Text` in a `GestureDetector` (`onLongPress`) on both surfaces, factored into a shared widget: `CopyableRunTime` in `lib/widgets/timer_toggle_button.dart` (or a new sibling file, `lib/widgets/copyable_run_time.dart`).**
`CopyableRunTime({required String display, required TextStyle? style})` renders the `Text` and wraps it in a `GestureDetector` whose `onLongPress` calls `Clipboard.setData(ClipboardData(text: display))` then shows a `SnackBar` via the nearest `ScaffoldMessenger`. Both `TimerDialog`'s Stopped-phase text and `QuickMeasureScreen`'s idle-with-duration text are replaced with this widget, matching the existing pattern of sharing components between the two surfaces (per `quick-screen-visual-parity`).
Alternative considered: use `InkWell`'s `onLongPress` instead of a bare `GestureDetector` for a visible press ripple — rejected; the existing `timer-toggle-control` spec's "no custom interaction affordance beyond framework defaults" principle extends here: a `GestureDetector` with no visual embellishment is the minimal, unopinionated choice, and no ripple was requested.

**D2 — `TimerDialog` requires a `ScaffoldMessenger` to show the `SnackBar`, but `TimerDialog` is itself shown via `showDialog` (no `Scaffold` of its own) — the `SnackBar` is shown via the enclosing route's `ScaffoldMessenger` (`ScaffoldMessenger.of(context)`), which resolves to the underlying screen's messenger (e.g. `HomeScreen`'s), so the notification appears at the bottom of the screen behind the dialog, not inside the dialog box itself.**
This matches "small system notification on screen bottom" from the request — a `SnackBar` is conventionally screen-bottom, not dialog-internal. `QuickMeasureScreen` already has its own `Scaffold`, so its `ScaffoldMessenger` is local.
Alternative considered: show an in-dialog toast/label instead of a real `SnackBar` for `TimerDialog` — rejected; the request explicitly says "small system notification on screen bottom," which is exactly what `SnackBar` provides, and reusing the same shared widget for both surfaces (rather than a dialog-specific variant) keeps the behavior consistent.

**D3 — Long-press is gated by which surface/phase currently renders `CopyableRunTime` at all, not by a runtime flag inside the widget.**
`TimerDialog` only renders `CopyableRunTime` in its Stopped-phase branch (replacing the plain `Text('Save'/'Cancel' branch's duration text)`); its Idle/Running branch continues to render a plain `Text` (no long-press). `QuickMeasureScreen` only renders `CopyableRunTime` when `_phase == QuickPhase.idle`; its Running branch renders a plain `Text`. This means "long-press inactive while live" (spec requirement) is satisfied structurally — there's no long-press-capable widget mounted while the clock is live — rather than by a conditional inside one always-mounted widget.

## Risks / Trade-offs

- [Risk] A `SnackBar` shown from `TimerDialog` while the dialog is still open could be visually obscured by the dialog's modal barrier — Mitigation: `SnackBar`s render in the `Scaffold`'s overlay, above the modal barrier in the same way any `Scaffold`-hosted content would show through/around a non-fullscreen dialog; verify visually via a widget test asserting the `SnackBar` is found in the tree after long-press while `TimerDialog` is still showing.
- [Risk] Two long-presses in quick succession could queue two `SnackBar`s — Mitigation: call `ScaffoldMessenger.of(context).hideCurrentSnackBar()` before showing a new one, so only the latest confirmation is visible at a time.
- [Risk] Copying via `Clipboard.setData` is asynchronous (`Future<void>`) — a widget could be unmounted before it resolves — Mitigation: guard the subsequent `SnackBar` call with a `mounted` check, consistent with the existing pattern already used for async calls in both files (e.g. `_onStop`'s `if (!mounted) return;` in `QuickMeasureScreen`).
- [Risk] This test environment has no real platform to answer `Clipboard.setData`/`getData` platform-channel calls — awaiting the real `Clipboard` API in a widget test hangs indefinitely (confirmed by direct reproduction) rather than throwing or timing out — Mitigation: every test exercising the copy path mocks `SystemChannels.platform` directly (intercepting `Clipboard.setData`/`Clipboard.getData` method calls in-memory) instead of calling the real `Clipboard` API; this is the standard Flutter testing pattern for clipboard interactions and is not specific to this app.
