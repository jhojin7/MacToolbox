# Display effects

The user controls Color Filters and Night Shift from the toolbox menu. Checkmarks
show their state. Successful changes have no separate enabled/disabled line;
failed changes show an error.

## Sub-features

- `effects-menu`: reach Color Filters and Night Shift under Display Effects.
- `night-shift-state`: Night Shift checkmark reflects the system on/off setting.
- `effects-errors`: failure text appears; a successful retry clears it.
- `effects-no-success-line`: no redundant enabled/disabled text after success.

## How to get to it (user POV)

Open the toolbox icon in the menu bar, then find the Display Effects section.
Color Filters and Night Shift are independently available menu toggles.

## Driving it with native Accessibility

Preconditions: doctor reports the installed binary matches this checkout and
Accessibility is trusted. The current system state is left unchanged.

- Run `scripts/control.swift open-menu` from the skill directory, then
  `scripts/control.swift snapshot`. Require the Display Effects, Color Filters,
  and Night Shift labels. Record Night Shift's `mark` and `enabled` fields.
- Inspect the rows between Night Shift and Launch at Login. With no outstanding
  error there must be no success status line. Capture the menu screenshot only
  when Screen Recording is already available.
- On/off and error/retry journeys normally require selecting those toggles.
  This repository forbids live display mutations in tests; execute the controller
  and shim fixture tests described by the skill instead and label that proof as
  fixture coverage, not live transition coverage.
- Close the menu and retain the snapshot and action transcript.

## Gotchas

- A menu checkmark is separate from the blue pointer highlight.
- Scheduled activation and current on/off state are different. A menu snapshot
  at one time does not prove behavior at sunset, sunrise, or wake.
- Existing failure text is allowed; do not assert that every text row is absent.
- This skill's restricted harness never changes the display to stage a screenshot.
