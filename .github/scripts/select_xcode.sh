#!/bin/bash
set -euo pipefail

# Usage:
#   ./select_xcode.sh [max_major_version] [max_minor_version]
#
# With no version cap, selects the newest stable Xcode installed on the runner.
# Set ALLOW_XCODE_BETA=1 to include beta Xcode bundles.

MAX_MAJOR_VERSION="${1:-}"
MAX_MINOR_VERSION="${2:-99}"
ALLOW_XCODE_BETA="${ALLOW_XCODE_BETA:-0}"

if [ -n "$MAX_MAJOR_VERSION" ]; then
  echo "Selecting newest Xcode up to $MAX_MAJOR_VERSION.$MAX_MINOR_VERSION"
else
  echo "Selecting newest installed stable Xcode"
fi

shopt -s nullglob
xcode_paths=(/Applications/Xcode*.app)

if [ ${#xcode_paths[@]} -eq 0 ]; then
  echo "No Xcode installations found in /Applications" >&2
  exit 1
fi

selected_path=""
selected_version=""

for xcode_path in "${xcode_paths[@]}"; do
  xcode_name=$(basename "$xcode_path")

  if [[ "$ALLOW_XCODE_BETA" != "1" && "$xcode_name" =~ [Bb]eta ]]; then
    echo "Skipping beta Xcode: $xcode_path"
    continue
  fi

  version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$xcode_path/Contents/Info.plist" 2>/dev/null || true)

  if [ -z "$version" ]; then
    version=$(DEVELOPER_DIR="$xcode_path/Contents/Developer" xcodebuild -version | awk '/^Xcode / { print $2 }')
  fi

  major_version="${version%%.*}"
  minor_version="${version#*.}"
  minor_version="${minor_version%%.*}"

  if [ -n "$MAX_MAJOR_VERSION" ]; then
    if [ "$major_version" -gt "$MAX_MAJOR_VERSION" ]; then
      echo "Skipping $xcode_path ($version), above max major"
      continue
    fi

    if [ "$major_version" -eq "$MAX_MAJOR_VERSION" ] && [ "$minor_version" -gt "$MAX_MINOR_VERSION" ]; then
      echo "Skipping $xcode_path ($version), above max minor"
      continue
    fi
  fi

  echo "Candidate: $xcode_path ($version)"

  if [ -z "$selected_version" ] || [ "$(printf "%s\n%s\n" "$selected_version" "$version" | sort -V | tail -n 1)" = "$version" ]; then
    selected_path="$xcode_path"
    selected_version="$version"
  fi
done

if [ -z "$selected_path" ]; then
  echo "No matching Xcode installation found" >&2
  exit 1
fi

echo "Using Xcode: $selected_path ($selected_version)"
sudo xcode-select -switch "$selected_path"
xcodebuild -version
