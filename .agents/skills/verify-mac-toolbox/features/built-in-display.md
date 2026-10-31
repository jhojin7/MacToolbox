# Built-in display control

Automatic mode turns off the built-in panel only with a usable external display.
Manual restoration, last-external removal, appropriate wake recovery, and normal
quit restore the panel.

## Sub-features

- `display-summary`: current panel status and usable external display count.
- `display-auto-mode`: independently enable or pause automatic switching.
- `display-restore`: Restore Internal Display requests recovery.
- `display-safety`: retain a usable display and recover on external removal.

## How to get to it (user POV)

Open the toolbox icon. Read Displays, Auto-disable Built-in Display, and Restore
Internal Display at the top of the menu.

## Driving it with native Accessibility

Preconditions: doctor passes. No monitor connections or display settings are
changed during automated verification.

- Open and snapshot the menu. Record the status, external count, automatic-mode
  checkmark, and presence of Restore Internal Display.
- Switching modes, selecting restoration, unplugging the last external display,
  and sleep/wake are hardware journeys, not exercised by this inspection. Record
  that limit and use the existing policy tests for pure decision coverage.
- Close the menu without pressing any display action.

## Gotchas

- Do not force-quit this app; the built-in display may be disabled.
- Pausing automatic mode does not itself restore a disabled panel.
- Do not disconnect the external monitor to manufacture an automated test state.
