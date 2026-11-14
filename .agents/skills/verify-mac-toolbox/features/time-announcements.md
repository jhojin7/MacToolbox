# Time announcements

## Sub-features

- `clock-menu`: Clock → Announce the time is an independent menu toggle.
- `clock-state`: the checkmark reads the system preference on startup, menu open, and after a change.
- `clock-preservation`: toggling changes only TimeAnnouncementsEnabled inside TimeAnnouncementPrefs, preserving voice, interval, volume, rate, and unknown keys.
- `clock-errors`: read, write, service activation, and readback failures show actionable errors; successful retry clears them.

## Driving it with native Accessibility

Run doctor, open-menu, and snapshot using the skill's native harness. Require
Clock and Announce the time; record the toggle's mark and enabled fields. The
read-only system value is available with:

```sh
defaults read com.apple.speech.synthesis.general.prefs TimeAnnouncementPrefs
```

A missing preference means off. During a change the toggle is temporarily
disabled. Successful changes add no status line. Close the menu after inspection.

Run TimeAnnouncementControllerTests for injected on/off, missing preferences,
external changes, preservation, write/read/service failure, and readback coverage.
Those fixtures never write the real speech preferences or launch system speech.
The menu harness proves reachability and rendering only.

A live functional journey needs a separately scoped settings change: save the
original dictionary, toggle off/on, inspect Clock Options and confirm the interval
and voice remain unchanged, listen across an announcement boundary, and restore
the original enabled state. Do not equate preference readback with audible proof.
The system notification and speech-service app paths are undocumented and may
vary by macOS release. No additional daemon or helper is installed.
