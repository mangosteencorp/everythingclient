#!/bin/bash
set -euo pipefail

# Required environment variables:
# - scheme: The Xcode scheme to build, or "default" to read ./default
# - platform: The destination platform. Defaults to "iOS Simulator".

scheme="${scheme:-default}"
platform="${platform:-iOS Simulator}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.DerivedData/everythingclient}"

if [ "$scheme" = "default" ]; then
  scheme=$(cat default)
fi

build_file_args=()
shopt -s nullglob
workspaces=(./*.xcworkspace)
projects=(./*.xcodeproj)

if [ ${#workspaces[@]} -gt 0 ]; then
  workspace="${workspaces[0]}"
  build_file_args=(-workspace "$workspace")
elif [ ${#projects[@]} -gt 0 ]; then
  project="${projects[0]}"
  build_file_args=(-project "$project")
else
  echo "No root .xcworkspace or .xcodeproj found" >&2
  exit 1
fi

echo "Building scheme: $scheme"
echo "Build file args: ${build_file_args[*]}"
echo "Destination platform: $platform"
echo "DerivedData: $DERIVED_DATA_PATH"
xcrun xctrace list devices 2>&1 || true

xcodebuild build-for-testing \
  "${build_file_args[@]}" \
  -scheme "$scheme" \
  -destination "generic/platform=$platform" \
  -derivedDataPath "$DERIVED_DATA_PATH"
