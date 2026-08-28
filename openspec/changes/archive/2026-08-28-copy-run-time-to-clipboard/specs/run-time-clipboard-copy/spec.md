## Purpose

Defines long-press-to-copy behavior on the frozen run-time display shared by the Session timing surface (`TimerDialog`) and the Quick run surface (`QuickMeasureScreen`): when it is active, what gets copied, and how the operator is notified.

## ADDED Requirements

### Requirement: Long-Press Copies the Frozen Run Time
When the run-time display shows a frozen (not live-updating) duration, the system SHALL copy the exact displayed formatted string to the system clipboard when the operator performs a long-press on that display, using the platform's standard long-press recognition threshold. No custom, extended hold duration SHALL be required.

#### Scenario: Long-press on a frozen duration copies it
- **WHEN** the operator performs a standard long-press on the run-time display while it shows a frozen duration
- **THEN** the exact displayed formatted string (e.g. "00:12.34") is copied to the system clipboard

### Requirement: Long-Press Is Inactive While the Clock Is Live
The system SHALL NOT copy anything, and SHALL NOT show the confirmation notification, if the operator long-presses the run-time display while the clock is live-updating (i.e. a run is currently in progress) rather than frozen.

#### Scenario: Long-press while running has no effect
- **WHEN** the operator performs a long-press on the run-time display while a run is in progress and the clock is actively updating
- **THEN** nothing is copied to the clipboard and no confirmation notification appears

### Requirement: Confirmation Notification on Copy
Immediately after a successful copy, the system SHALL display a brief notification at the bottom of the screen confirming the value was copied to the clipboard. The notification SHALL remain visible for a short, typical duration (on the order of 2-3 seconds) before it dismisses itself automatically, without requiring operator interaction to dismiss it.

#### Scenario: Confirmation appears and auto-dismisses
- **WHEN** a long-press successfully copies the run time to the clipboard
- **THEN** a notification confirming the copy appears at the bottom of the screen and disappears on its own after a few seconds

### Requirement: Copied Value Persists Across Navigation
Once a value has been copied to the clipboard, it SHALL remain available for pasting after the operator navigates away from the current screen, closes the app, or switches to another app.

#### Scenario: Value is still pasteable after leaving the app
- **WHEN** the operator copies a run time, then leaves the current screen or the app entirely
- **THEN** the previously copied value can still be pasted into another application
