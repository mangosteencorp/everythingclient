#!/bin/bash
set -euo pipefail

TEST_SCHEMES=(
  "TMDB_Discover_Tests"
  # "TMDB_Shared_Backend_Tests"
  "TMDB_Feed_Tests"
  "TMDB_MovieDetail_Tests"
  "TMDB_TVShowDetail_Tests"
  "TMDB_Person_Tests"
  "TMDB_Profile_Tests"
)

if [ -z "${SIMULATOR_ID:-}" ]; then
  echo "SIMULATOR_ID is required. Run find_simulator.sh first." >&2
  exit 1
fi

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.DerivedData/everythingclient}"

build_file_args=()
shopt -s nullglob
workspaces=(./*.xcworkspace)
projects=(./*.xcodeproj)

if [ ${#workspaces[@]} -gt 0 ]; then
  build_file_args=(-workspace "${workspaces[0]}")
elif [ ${#projects[@]} -gt 0 ]; then
  build_file_args=(-project "${projects[0]}")
fi

for scheme in "${TEST_SCHEMES[@]}"; do
  echo "Testing scheme: $scheme"

  xcodebuild test \
    "${build_file_args[@]}" \
    -scheme "$scheme" \
    -destination "id=$SIMULATOR_ID" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -quiet \
    -enableCodeCoverage YES
done

echo "All tests passed."
