#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
probe_dir="$(mktemp -d "${TMPDIR:-/tmp}/mac-toolbox-time-announcement.XXXXXX")"
trap 'rm -rf "$probe_dir"' EXIT

xcrun clang -fobjc-arc -dynamiclib -framework Foundation \
    "$project_dir/Tests/TimeAnnouncementBackendTests/PreferencesFixture.m" \
    -o "$probe_dir/PreferencesFixture.dylib"
xcrun clang -fobjc-arc -c \
    -I "$project_dir/Sources/SystemControlsShim/include" \
    "$project_dir/Sources/SystemControlsShim/SystemControlsShim.m" \
    -o "$probe_dir/SystemControlsShim.o"
cat > "$probe_dir/module.modulemap" <<MODULE
module SystemControlsShim {
    header "$project_dir/Sources/SystemControlsShim/include/SystemControlsShim.h"
    export *
}
MODULE
xcrun swiftc -swift-version 6 -parse-as-library -I "$probe_dir" -framework Foundation \
    "$project_dir/Sources/MacToolbox/TimeAnnouncementController.swift" \
    "$project_dir/Tests/TimeAnnouncementBackendTests/Main.swift" \
    "$probe_dir/SystemControlsShim.o" -o "$probe_dir/TimeAnnouncementBackendTests"
DYLD_INSERT_LIBRARIES="$probe_dir/PreferencesFixture.dylib" \
    "$probe_dir/TimeAnnouncementBackendTests"
