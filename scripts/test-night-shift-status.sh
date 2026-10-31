#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
probe_dir="$(mktemp -d "${TMPDIR:-/tmp}/mac-toolbox-night-shift.XXXXXX")"
trap 'rm -f "$probe_dir/NightShiftStatusTests"; rmdir "$probe_dir"' EXIT

xcrun clang -framework Foundation \
    -I "$project_dir/Sources/SystemControlsShim/include" \
    "$project_dir/Sources/SystemControlsShim/SystemControlsShim.m" \
    "$project_dir/Tests/SystemControlsShimTests/NightShiftStatusTests.m" \
    -o "$probe_dir/NightShiftStatusTests"
"$probe_dir/NightShiftStatusTests"
