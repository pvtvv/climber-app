## ADDED Requirements

### Requirement: Shared Component Reuse Between Session and Quick Surfaces
The system SHALL implement the clock display and the toggle button on the Quick run surface (`QuickMeasureScreen`) by reusing the same underlying styling/components used by the Session timing surface (`TimerDialog`), rather than by independently declaring separately-maintained values that happen to match. A future change to the shared styling SHALL apply to both surfaces without requiring a matching edit to be made twice.

#### Scenario: Clock and button styling is defined once and consumed by both surfaces
- **WHEN** the clock text style or the toggle button's label style is defined
- **THEN** both the Session timing surface and the Quick run surface consume that same definition, rather than each declaring their own copy of the same values

### Requirement: Matching Visual Presentation and Position
The Quick run surface's clock display and toggle button SHALL match the Session timing surface's element design, alignment, colors, and fonts exactly: the clock uses the same text style (bold, fixed-width digits, centered) and the toggle button uses the same label typography and the same theme-driven coloring. The Quick run surface's content column (clock + toggle button) SHALL be positioned vertically centered within its full-screen surface, matching where the Session timing surface's compact dialog box visually sits on screen — the Quick run surface SHALL remain a full-screen surface, not a modal dialog; only the internal content's position and appearance change.

#### Scenario: Clock typography matches between surfaces
- **WHEN** the clock is displayed on either the Session timing surface or the Quick run surface
- **THEN** both render the elapsed time with the same bold, fixed-width-digit, centered text style

#### Scenario: Toggle button typography and coloring match between surfaces
- **WHEN** the toggle button is displayed on either surface
- **THEN** both render its label with the same typography and use the same theme-driven button coloring

#### Scenario: Quick surface content is vertically centered
- **WHEN** the Quick run surface is displayed in the Idle or Running phase
- **THEN** the clock and toggle button are positioned vertically centered within the screen, rather than pinned directly under the app bar
