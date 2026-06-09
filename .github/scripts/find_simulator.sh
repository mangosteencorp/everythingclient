#!/bin/bash
set -euo pipefail

scheme="${scheme:-${default:-}}"
if [ -z "$scheme" ] || [ "$scheme" = "default" ]; then
  scheme=$(cat default)
fi

build_file_args=()
shopt -s nullglob
workspaces=(./*.xcworkspace)
projects=(./*.xcodeproj)

if [ ${#workspaces[@]} -gt 0 ]; then
  build_file_args=(-workspace "${workspaces[0]}")
elif [ ${#projects[@]} -gt 0 ]; then
  build_file_args=(-project "${projects[0]}")
fi

destinations=$(xcodebuild "${build_file_args[@]}" -scheme "$scheme" -showdestinations)
echo "$destinations"

simulator_id=$(printf "%s\n" "$destinations" \
  | grep "platform:iOS Simulator" \
  | grep "name:iPhone" \
  | grep -v "placeholder" \
  | tail -n 1 \
  | sed -n 's/.*id:\([^,}]*\).*/\1/p' \
  | xargs || true)

if [ -z "$simulator_id" ]; then
  simulator_id=$(printf "%s\n" "$destinations" \
    | grep "platform:iOS Simulator" \
    | grep -v "placeholder" \
    | tail -n 1 \
    | sed -n 's/.*id:\([^,}]*\).*/\1/p' \
    | xargs || true)
fi

if [ -z "$simulator_id" ]; then
  echo "No concrete iOS Simulator destination found" >&2
  exit 1
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "SIMULATOR_ID=$simulator_id" >> "$GITHUB_ENV"
fi

echo "Selected simulator ID: $simulator_id"
