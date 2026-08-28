## Purpose

Defines the single toggling Start/Stop button shared by the Session timing surface (`TimerDialog`, "Tap to time…") and the Quick run surface (`QuickMeasureScreen`), including its label/counter behavior, its interaction-state contract, and each surface's distinct behavior after Stop.

## ADDED Requirements

### Requirement: Single Toggling Button for Start and Stop
The system SHALL present exactly one button for controlling run measurement, not two separate buttons. While idle, the button SHALL be labeled "Start" and SHALL be enabled. When tapped, the counter SHALL begin running and the same button SHALL immediately be relabeled "Stop", remaining enabled. When tapped again while running, the counter SHALL stop and control SHALL pass to the surface-specific post-Stop behavior (see the Session and Quick requirements below).

#### Scenario: Idle shows a single Start button
- **WHEN** the timing surface is idle (no run in progress)
- **THEN** exactly one button is visible, labeled "Start", and enabled

#### Scenario: Tapping Start begins the run and relabels the button
- **WHEN** the operator taps the "Start" button
- **THEN** the counter begins running and the same button is now labeled "Stop", still enabled

#### Scenario: Tapping Stop ends the run
- **WHEN** the operator taps the "Stop" button while the counter is running
- **THEN** the counter stops and the surface transitions to its post-Stop behavior

### Requirement: Session Surface Preserves Save/Cancel After Stop
On the Session timing surface (`TimerDialog`), after Stop is tapped, the system SHALL replace the single toggle button with the existing split Save/Cancel control pair, unchanged from current behavior: Save persists the captured duration and closes the surface; Cancel discards it and closes the surface.

#### Scenario: Stop on Session surface shows Save and Cancel
- **WHEN** the operator taps Stop on the Session timing surface
- **THEN** the toggle button is replaced by a Save control and a Cancel control; no further toggling occurs until the surface is reopened for the next run

### Requirement: Quick Surface Auto-Saves and Returns to Start Immediately
On the Quick run surface (`QuickMeasureScreen`), after Stop is tapped, the system SHALL persist the captured duration automatically without operator confirmation, and SHALL immediately relabel the same button back to "Start" — with no intermediate confirmation screen, no "Result saved" message, and no separate Retake control. The clock display SHALL continue showing the just-completed duration until the operator taps "Start" again, at which point the counter resets to zero and a new run begins.

#### Scenario: Stop on Quick surface auto-saves and is immediately ready for the next run
- **WHEN** the operator taps Stop on the Quick run surface
- **THEN** the duration is saved automatically, the button immediately reads "Start" again, and the clock continues to display the just-completed duration until Start is tapped

#### Scenario: Starting a new run after a completed one
- **WHEN** the operator taps "Start" after a previous run's duration is displayed
- **THEN** the counter resets to zero and begins running, and the button relabels to "Stop"

#### Scenario: Reopening the Quick surface with a previously saved result
- **WHEN** the operator opens the Quick run surface and a previously saved result exists
- **THEN** the clock displays that saved duration and the button reads "Start", ready to begin a new run

### Requirement: Default Interaction States on the Toggle Button
The system SHALL present hover, press, disabled-tap, and keyboard-focus feedback on the toggle button (and on the Session surface's Save/Cancel controls) using only the underlying UI framework's default behavior. The system SHALL NOT introduce a custom hover treatment, a custom press animation, haptic or audio feedback, or a custom keyboard focus/tab-order override.

#### Scenario: Default press feedback only
- **WHEN** the operator taps the toggle button, or Save, or Cancel
- **THEN** only the framework's default press feedback is shown, and the underlying action fires immediately

#### Scenario: No custom hover or focus treatment
- **WHEN** a pointer hovers over, or a keyboard user focuses, the toggle button or the Save/Cancel controls
- **THEN** only the framework's default hover and focus indication is shown, with no custom visual treatment layered on top

### Requirement: Confirm/Danger Color Exception for Save and Cancel
The system SHALL render the Session surface's Save control with a green confirm color and its Cancel control with a red danger color, regardless of the application's seeded theme color. This exception applies only to Save/Cancel; the toggle button itself uses the application's theme-driven button coloring.

#### Scenario: Save and Cancel colors are independent of the seeded theme
- **WHEN** the Session surface shows Save and Cancel after Stop
- **THEN** Save is rendered with a green confirm color and Cancel with a red danger color, independent of the application's seeded theme color
