#!/bin/bash
set -euo pipefail

# Xcode 26+ no longer bundles the Metal compiler: it ships as a downloadable
# component. Without it, any target holding a .metal file (here:
# Sources/Shared_UI_Support/Views/CoverFlow/KSCoverFlowReflection.metal) fails
# with "cannot execute tool 'metal' due to missing Metal Toolchain".
# Run this after select_xcode.sh, since the component is per-Xcode.
#
# `xcodebuild -showComponent` is not trusted: on the runner image it reports the
# toolchain as installed while `metal` still refuses to run (stale / unmounted
# asset), so the check is a real compile of a tiny .metal file.

probe_dir=$(mktemp -d)
trap 'rm -rf "$probe_dir"' EXIT

metal_works() {
  printf '#include <metal_stdlib>\nusing namespace metal;\nkernel void ci_probe() {}\n' > "$probe_dir/probe.metal"
  if xcrun -sdk iphonesimulator metal -c "$probe_dir/probe.metal" -o "$probe_dir/probe.air" > "$probe_dir/probe.log" 2>&1; then
    return 0
  fi
  sed 's/^/  metal: /' "$probe_dir/probe.log" >&2
  return 1
}

echo "Xcode: $(xcode-select -p)"
xcodebuild -showComponent MetalToolchain || true

if metal_works; then
  echo "Metal toolchain works for $(xcode-select -p)"
  exit 0
fi

echo "Metal toolchain missing or unusable for $(xcode-select -p), reinstalling"

for attempt in 1 2 3; do
  # A listed-but-broken install makes -downloadComponent a no-op, so clear it first.
  xcodebuild -deleteComponent MetalToolchain || sudo -n xcodebuild -deleteComponent MetalToolchain || true

  if xcodebuild -downloadComponent MetalToolchain || { sudo -n true 2>/dev/null && sudo xcodebuild -downloadComponent MetalToolchain; }; then
    xcodebuild -showComponent MetalToolchain || true
    if metal_works; then
      echo "Metal toolchain works after install (attempt $attempt)"
      exit 0
    fi
  fi

  echo "Metal toolchain install attempt $attempt failed" >&2

  if [ "$attempt" -lt 3 ]; then
    sleep 30
  fi
done

echo "Could not get a working Metal toolchain" >&2
exit 1
