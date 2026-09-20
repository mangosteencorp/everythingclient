#!/bin/bash
set -euo pipefail

# Xcode 26+ no longer bundles the Metal compiler: it ships as a downloadable
# component. Without it, any target holding a .metal file (here:
# Sources/Shared_UI_Support/Views/CoverFlow/KSCoverFlowReflection.metal) fails
# with "cannot execute tool 'metal' due to missing Metal Toolchain".
# Run this after select_xcode.sh, since the component is per-Xcode.

if xcodebuild -showComponent MetalToolchain >/dev/null 2>&1; then
  echo "Metal toolchain already installed for $(xcode-select -p)"
  exit 0
fi

echo "Downloading Metal toolchain for $(xcode-select -p)"

for attempt in 1 2 3; do
  if xcodebuild -downloadComponent MetalToolchain; then
    xcodebuild -showComponent MetalToolchain || true
    exit 0
  fi

  if sudo -n true 2>/dev/null && sudo xcodebuild -downloadComponent MetalToolchain; then
    xcodebuild -showComponent MetalToolchain || true
    exit 0
  fi

  echo "Metal toolchain download attempt $attempt failed" >&2

  if [ "$attempt" -lt 3 ]; then
    sleep 30
  fi
done

echo "Could not download the Metal toolchain" >&2
exit 1
