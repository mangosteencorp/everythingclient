#!/bin/bash

# Select latest Xcode with version filtering
# Usage: ./select_xcode.sh [max_major_version] [max_minor_version]
# Example: ./select_xcode.sh 16 4 (for max Xcode 16.4)

# Default to max Xcode 16.4 if no arguments provided
MAX_MAJOR_VERSION=${1:-16}
MAX_MINOR_VERSION=${2:-4}

echo "Selecting Xcode with max version: $MAX_MAJOR_VERSION.$MAX_MINOR_VERSION"

XCODE_LIST_RAW=$(ls -d /Applications/Xcode*.app)
echo "Xcode List full: $XCODE_LIST_RAW"
XCODE_LIST=$(ls -d /Applications/Xcode*.app | grep -i -v beta)
echo "Xcode List: $XCODE_LIST"

# Filter Xcode versions to specified max version
FILTERED_XCODE_LIST=""
for xcode_path in $XCODE_LIST; do
  xcode_name=$(basename "$xcode_path" .app)
  if [[ "$xcode_name" == "Xcode" ]]; then
    # Handle Xcode without version suffix (likely Xcode 15 or earlier)
    FILTERED_XCODE_LIST="$FILTERED_XCODE_LIST $xcode_path"
  elif [[ "$xcode_name" =~ ^Xcode([0-9]+)\.([0-9]+)$ ]]; then
    major_version="${BASH_REMATCH[1]}"
    minor_version="${BASH_REMATCH[2]}"
    if [[ "$major_version" -lt $MAX_MAJOR_VERSION ]] || [[ "$major_version" -eq $MAX_MAJOR_VERSION && "$minor_version" -le $MAX_MINOR_VERSION ]]; then
      FILTERED_XCODE_LIST="$FILTERED_XCODE_LIST $xcode_path"
    fi
  fi
done

echo "Filtered Xcode List (max $MAX_MAJOR_VERSION.$MAX_MINOR_VERSION): $FILTERED_XCODE_LIST"
LATEST_XCODE=$(echo "$FILTERED_XCODE_LIST" | tr ' ' '\n' | sort -V | tail -n 1)
echo "Using Xcode: $LATEST_XCODE"
sudo xcode-select -switch "$LATEST_XCODE" 