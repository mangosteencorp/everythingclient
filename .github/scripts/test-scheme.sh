#!/bin/bash
set -e

# Script to build and run tests for a specific scheme
# Usage: scheme=SCHEME_NAME bash .github/scripts/test-scheme.sh

if [ -z "$scheme" ]; then
    echo "❌ Error: Please specify a scheme"
    echo "Usage: scheme=SCHEME_NAME bash .github/scripts/test-scheme.sh"
    echo "Example: scheme=TMDB_Discover_Tests bash .github/scripts/test-scheme.sh"
    exit 1
fi

echo "🔨 Building and testing scheme: $scheme"

# Shared schemes that might need to be excluded from coverage
SHARED_SCHEMES=(
    "TMDB_Shared_Backend"
    "TMDB_Shared_UI"
    "CoreFeatures"
    "Shared_UI_Support"
)

# Create output directory if it doesn't exist
COVERAGE_REPORT=".output/coverage_${scheme}_report.txt"
COVERAGE_100_REPORT=".output/coverage_${scheme}_100_report.txt"
mkdir -p $(dirname "$COVERAGE_REPORT")

# Create coverage report files
echo "Coverage Report for $scheme Generated on $(date)" > $COVERAGE_REPORT
echo "100% Coverage Report for $scheme Generated on $(date)" > $COVERAGE_100_REPORT
echo "----------------------------------------" >> $COVERAGE_REPORT
echo "----------------------------------------" >> $COVERAGE_100_REPORT

# Get simulator ID (use default if not set)
if [ -z "$SIMULATOR_ID" ]; then
    SIMULATOR_ID="platform=iOS Simulator,name=iPhone 16,OS=latest"
fi

echo "🏗️ Building and testing $scheme..."
echo "Testing $scheme..." >> $COVERAGE_REPORT

# Run the test
xcodebuild test \
    -scheme "$scheme" \
    -destination "$SIMULATOR_ID" \
    -quiet \
    -enableCodeCoverage YES

# Initialize ignore_schemes array with default ignores
ignore_schemes=()

# Check if the test scheme is related to any shared scheme
for shared_scheme in "${SHARED_SCHEMES[@]}"; do
    if [[ "$scheme" =~ ^"${shared_scheme}" ]]; then
        continue  # Skip adding this shared scheme to ignores
    else
        ignore_schemes+=("$shared_scheme")
    fi
done

# Build the ignore patterns for coverage command
ignore_patterns=(
    "--ignore-filename-regex='.*/Tests/.*'"
    "--ignore-filename-regex='.*/SourcePackages/checkouts/.*'"
    "--ignore-filename-regex='.*/Intermediates\.noindex/.*'"
    "--ignore-filename-regex='.*/generated/.*'"
    "--ignore-filename-regex='.*/Generated/.*'"
)

# Add ignore patterns for shared schemes
for ignore_scheme in "${ignore_schemes[@]}"; do
    ignore_patterns+=("--ignore-filename-regex='.*/${ignore_scheme}/.*'")
done

# Determine derived data path
# First try workspace-relative .DerivedData
local_derived_data="./.DerivedData/everythingclient"
default_derived_data="$HOME/Library/Developer/Xcode/DerivedData/everythingclient"

derived_data_path=$local_derived_data # use local_derived_data for local testing

# Build coverage command
coverage_cmd="xcrun llvm-cov report \
    $derived_data_path/Build/Products/Debug-iphonesimulator/$scheme.xctest/$scheme \
    -instr-profile \$(find $derived_data_path/Build/ProfileData -type d -depth 1 -exec ls -td {} + | head -n 1)/Coverage.profdata \
    ${ignore_patterns[@]} \
    --use-color"

# Print full coverage report to console
echo "📊 Full coverage report for $scheme:"
eval "$coverage_cmd"

# Process coverage report for the file
echo "📝 Saving coverage results to reports..."
eval "$coverage_cmd" | while read -r line
do
    # Check if line contains coverage data (has a percentage)
    if [[ $line =~ [0-9]+\.[0-9]+% ]]; then
        if [[ $line =~ "100.00%" ]]; then
            echo "$line" >> $COVERAGE_100_REPORT
        else
            echo "$line" >> $COVERAGE_REPORT
            echo "1" > .incomplete_coverage_flag_${scheme}
        fi
    fi
done

echo "----------------------------------------" >> $COVERAGE_REPORT

echo "✅ Coverage report has been generated:"
echo "  📄 Full report: $COVERAGE_REPORT"
echo "  📄 100% coverage: $COVERAGE_100_REPORT"

# Print the contents of both coverage reports
echo -e "\n🎯 Files with 100% coverage:"
cat "$COVERAGE_100_REPORT"
echo -e "\n⚠️  Files with less than 100% coverage:"
cat "$COVERAGE_REPORT"

# Read the flag file and exit with error if incomplete coverage was found
if [ -f .incomplete_coverage_flag_${scheme} ]; then
    echo "❌ Found files with less than 100% coverage in $scheme"
    rm .incomplete_coverage_flag_${scheme}
    exit 1
else
    echo "🎉 All files have 100% coverage in $scheme!"
fi