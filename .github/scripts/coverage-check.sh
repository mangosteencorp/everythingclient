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

SHARED_SCHEMES=(
  "TMDB_Shared_Backend"
  "TMDB_Shared_UI"
  "CoreFeatures"
  "Shared_UI_Support"
)

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.DerivedData/everythingclient}"
COVERAGE_REPORT=".output/coverage_report.txt"
COVERAGE_100_REPORT=".output/coverage_100_report.txt"

mkdir -p "$(dirname "$COVERAGE_REPORT")"

echo "Coverage Report Generated on $(date)" > "$COVERAGE_REPORT"
echo "100% Coverage Report Generated on $(date)" > "$COVERAGE_100_REPORT"
echo "----------------------------------------" >> "$COVERAGE_REPORT"
echo "----------------------------------------" >> "$COVERAGE_100_REPORT"

for scheme in "${TEST_SCHEMES[@]}"; do
  echo "Processing coverage for scheme: $scheme"
  printf "\nCoverage for %s...\n" "$scheme" >> "$COVERAGE_REPORT"

  ignore_patterns=(
    "--ignore-filename-regex=.*/Tests/.*"
    "--ignore-filename-regex=.*/SourcePackages/checkouts/.*"
    "--ignore-filename-regex=.*/Intermediates\\.noindex/.*"
    "--ignore-filename-regex=.*/generated/.*"
    "--ignore-filename-regex=.*/Generated/.*"
  )

  for shared_scheme in "${SHARED_SCHEMES[@]}"; do
    if [[ ! "$scheme" =~ ^"${shared_scheme}" ]]; then
      ignore_patterns+=("--ignore-filename-regex=.*/${shared_scheme}/.*")
    fi
  done

  binary="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/$scheme.xctest/$scheme"
  profile_data=$(find "$DERIVED_DATA_PATH/Build/ProfileData" -name Coverage.profdata -print \
    | while read -r profile_path; do
        printf "%s %s\n" "$(stat -f "%m" "$profile_path")" "$profile_path"
      done \
    | sort -rn \
    | head -n 1 \
    | cut -d " " -f 2-)

  if [ -z "$profile_data" ]; then
    echo "No Coverage.profdata found for $scheme" >&2
    exit 1
  fi

  if [ ! -f "$binary" ]; then
    echo "Test binary not found at $binary" >&2
    exit 1
  fi

  coverage_cmd=(
    xcrun llvm-cov report
    "$binary"
    -instr-profile "$profile_data"
    "${ignore_patterns[@]}"
    --use-color
  )

  printf "\nFull coverage report for %s:\n" "$scheme"
  "${coverage_cmd[@]}"

  printf "\nSaving files with less than 100%% coverage to %s\n" "$COVERAGE_REPORT"
  "${coverage_cmd[@]}" | while read -r line; do
    if [[ $line =~ [0-9]+\.[0-9]+% ]]; then
      if [[ $line =~ "100.00%" ]]; then
        echo "$line" >> "$COVERAGE_100_REPORT"
      else
        echo "$line" >> "$COVERAGE_REPORT"
        echo "1" > .incomplete_coverage_flag
      fi
    fi
  done

  echo "----------------------------------------" >> "$COVERAGE_REPORT"
done

echo "Coverage report has been generated in $COVERAGE_REPORT"

printf "\nFiles with 100%% coverage:\n"
cat "$COVERAGE_100_REPORT"
echo "Files with less than 100% coverage:"
cat "$COVERAGE_REPORT"

if [ -f .incomplete_coverage_flag ]; then
  echo "Found files with less than 100% coverage"
  rm .incomplete_coverage_flag
  exit 1
fi
