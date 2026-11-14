# Time announcements

## Sub-features

- `clock-menu`: Clock → Announce the time is an independent menu toggle.
- `clock-state`: the checkmark reads the system preference on startup, menu open, and after a change.
- `clock-preservation`: toggling changes only TimeAnnouncementsEnabled inside TimeAnnouncementPrefs, preserving voice, interval, volume, rate, and unknown keys.
- `clock-application`: both on and off use SpeechSynthesis's SetTimeAnnouncementsPreferences so the speech service reloads its cached preferences.
- `clock-errors`: read, native setter, and readback failures show actionable errors; successful retry clears them.

## Driving it with native Accessibility

Run doctor, open-menu, and snapshot using the skill's native harness. Require
Clock and Announce the time; record the toggle's mark and enabled fields. The
read-only system value is available with:

```sh
defaults read com.apple.speech.synthesis.general.prefs TimeAnnouncementPrefs
```

A missing preference means off. Successful changes add no status line. Close the
menu after inspection.

Run TimeAnnouncementControllerTests for injected on/off, missing preferences,
external changes, preservation, write/read failure, and readback coverage.
Those fixtures never write the real speech preferences or launch system speech.
The menu harness proves reachability and rendering only.

Run `scripts/test-time-announcement-backend.sh` for the real Swift system backend
and Objective-C shim with process-local interposition of preferences and the
native setter. It must observe the setter on both off and on changes, preserve
voice and interval settings, and report a native failure. A file-only write plus
a clock-format notification fails this regression check. These are intercepted
backend fixtures, not proof of a running speech service or audible behavior.

A live functional journey needs a separately scoped settings change: save the
original dictionary, toggle off/on, inspect Clock Options and confirm the interval
and voice remain unchanged, listen across an announcement boundary, and restore
the original enabled state. Do not equate preference readback with audible proof.
The system speech-preferences setter is undocumented and may vary by macOS
release. No additional daemon or helper is installed.
