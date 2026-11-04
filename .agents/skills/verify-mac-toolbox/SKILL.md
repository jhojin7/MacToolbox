---
name: verify-mac-toolbox
description: Verify Mac Toolbox PRs and native macOS menu behavior using build checks, a native Accessibility menu harness, and saved evidence. Use for verification of this repository; distinguish live menu proof from fixture tests and blocked hardware or permission paths.
---

# Verify Mac Toolbox

Read repository `AGENTS.md`, the PR diff, and the [feature index](features/README.md).
This skill follows poteto's project-local verification and feature-map workflow;
upstream details are in [POTETO-SOURCE.md](../POTETO-SOURCE.md).

## Launch

From the repository root, run `swift build` and `scripts/package-app.sh`.
Mac Toolbox is a menu-bar app (`local.hojin.MacToolbox`), with no normal window,
server, accounts, or seed database. It shares real display configuration and
UserDefaults with the user's installed app; two instances cannot be isolated
safely. Never start a second instance or reset preferences for a test.

Prefer reusing `/Applications/Mac Toolbox.app` when doctor confirms it matches
this checkout's package. If an update is authorized, use
`scripts/update-installed-app.sh`; it stages the bundle, requests normal
termination, and aborts rather than force-killing a live app. Do not directly
overwrite the installed bundle. A process existing is not UI readiness: require
`open-menu` and a snapshot containing the mapped menu entries.

## Doctor

```sh
.agents/skills/verify-mac-toolbox/scripts/control.swift doctor
```

This read-only command requires exactly one installed instance, compares its
binary SHA-256 to the package in this checkout, and reports Accessibility and
Screen Recording access separately. Run before driving and after any surprising
result. An Accessibility failure blocks native menu driving; missing Screen
Recording access blocks screenshots, not AX snapshots. The helper never asks
for permissions or changes them. Report the limitation without treating missing
screenshots as successful capture.

## Drive

Use the native macOS Accessibility harness rather than assuming a menu-bar app
has a normal window. It reads `AXExtrasMenuBar`, finds `Mac Toolbox` by title,
and uses `AXPress` to open the status menu and `AXCancel` to dismiss it. It never presses
product toggles or the Quit command.

```sh
.agents/skills/verify-mac-toolbox/scripts/control.swift open-menu
.agents/skills/verify-mac-toolbox/scripts/control.swift snapshot
.agents/skills/verify-mac-toolbox/scripts/control.swift close-menu
```

The commands verify observed menu visibility; AXPress's return alone is not
proof. Read the feature file for exact menu labels and expected state. Repository
policy forbids changing real display settings from tests, so on/off transitions
are checked at the existing injected backend and Objective-C fixture boundaries.
Live menu inspection proves rendering and reachability only. Do not claim it
proves a toggle changed the hardware. Other persistent settings and Music launches
also need an explicitly scoped user journey; do not change them for a generic PR.

## Evidence

Keep run evidence outside the checkout, for example
`/tmp/mac-toolbox-verification-pr2/`. Use a new directory for another PR/run.
Record the revision, dirty state, command, stdout/stderr, and exit code. Save
`doctor.json`, `open-menu.json`, and `menu.json`; the latter contains only this
app's status menu, not the system Apple menu or unrelated recent documents.

When Screen Recording is already available, capture only the app's menu window:

```sh
.agents/skills/verify-mac-toolbox/scripts/control.swift screenshot /tmp/mac-toolbox-verification-pr2/menu.png
```

Inspect the saved image before attaching it. Attachments require the user's
request; a previous user-provided image can be labeled **before**, never used as
proof of the current UI. AX snapshots and screenshots are different evidence.

Run `swift test` and `scripts/test-night-shift-status.sh` for this PR's state
logic. Preserve valid tests if the local Command Line Tools cannot find
`TestingMacros` or `XCTest`. For the observed TestingMacros discovery problem,
first confirm the plugin exists; then this local workaround runs the same tests:

```sh
swift test -Xswiftc -load-plugin-library -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib
```

Keep the default failure and workaround results separately. Finish with
`git diff --check`. Report passed, failed, and blocked/unexercised journeys
separately, including remaining gaps such as schedule-boundary notifications or
other macOS private-API layouts. A green unit suite is not full live UI proof.

## Cleanup

Use `close-menu` for a popup this run opened, then confirm the saved evidence
still exists. Reuse of the user's already running app does not give the run
ownership to quit it. Never stop by process name or use SIGKILL. Do not delete
proof artifacts during cleanup. No persistent settings are changed by the harness.

## Helpers and maintenance

`control.swift` is executable and uses only macOS frameworks and system tools.
Its commands are documented above; there is intentionally no arbitrary action or
setting-change command. Keep the [feature map](features/README.md) synchronized
with actual menu paths. Use `$maintain-verification-skill` for a later full audit;
blocked features must remain visible in the report rather than being dropped.
