# Login and quit

Launch at Login controls registration with macOS. Quit exits normally and restores
a disabled built-in panel before leaving.

## Sub-features

- `login-switch`: show and control launch-at-login registration.
- `normal-quit`: terminate through the menu with panel restoration.

## How to get to it (user POV)

Open the toolbox icon. Launch at Login and Quit are at the bottom of the menu.

## Driving it with native Accessibility

Preconditions: doctor passes. The run reuses the user's existing app.

- Open and snapshot the menu. Record Launch at Login's checkmark and the Quit entry.
- Login registration and exit/relaunch are persistent or lifecycle journeys; do
  not run them for an unrelated display-effects PR. Record them as unexercised.
- Use the harness's close-menu command for cleanup, not the Quit menu item.

## Gotchas

- Disappearing from the menu bar is not proof the built-in display was restored.
- Never use SIGKILL or force termination as an alternative to normal Quit.
