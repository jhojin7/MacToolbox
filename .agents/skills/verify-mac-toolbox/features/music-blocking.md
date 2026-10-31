# Music blocking

Block Apple Music controls a rule that closes the real system Music app when it
launches. The menu reports whether the rule is active or paused.

## Sub-features

- `music-switch`: enable or pause the rule independently.
- `music-status`: show blocked, paused, or a recent block status.
- `music-match`: only the real system Music app is targeted.

## How to get to it (user POV)

Open the toolbox icon and find App Blocking → Block Apple Music.

## Driving it with native Accessibility

Preconditions: doctor passes. Existing Music playback and the user's rule setting
are left unchanged.

- Open and snapshot the menu. Record the Block Apple Music checkmark and nearby
  status. This proves visibility and current reported state.
- Testing launch blocking would require opening Music and observing termination;
  record it as unexercised for an unrelated display-effects PR. Run the existing
  Music matching policy tests for fixture coverage only.
- Close the menu and keep evidence.

## Gotchas

- Launching Music for a test can disrupt playback; it is not part of a generic
  verification run.
- A rule checkmark alone does not prove a launch was terminated.
