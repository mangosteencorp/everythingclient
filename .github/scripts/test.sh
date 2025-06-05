#!/bin/bash

# List of test schemes
TEST_SCHEMES=(
    "TMDB_clean_MLS_tests"
    # "TMDB_Shared_Backend_Tests"
    "TMDB_MVVM_MLS_Tests"
    # Add more schemes here as needed
)

SHARED_SCHEMES=(
    "TMDB_Shared_Backend"
    "TMDB_Shared_UI"
    "CoreFeatures"
    "Shared_UI_Support"
)

# Create output directory if it doesn't exist
COVERAGE_REPORT=".output/coverage_report.txt"
COVERAGE_100_REPORT=".output/coverage_100_report.txt"
mkdir -p $(dirname "$COVERAGE_REPORT")

# Create coverage report files
echo "Coverage Report Generated on $(date)" > $COVERAGE_REPORT
echo "100% Coverage Report Generated on $(date)" > $COVERAGE_100_REPORT
echo "----------------------------------------" >> $COVERAGE_REPORT
echo "----------------------------------------" >> $COVERAGE_100_REPORT

# Run tests and generate coverage for each scheme
for scheme in "${TEST_SCHEMES[@]}"
do
    echo "Processing scheme: $scheme"
    echo "\nTesting $scheme..." >> $COVERAGE_REPORT
    xcodebuild test \
        -scheme "$scheme" \
        -destination "id=$SIMULATOR_ID" \
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
    
    # Store the coverage command to reuse it
    # First try workspace-relative .DerivedData
    local_derived_data="./.DerivedData/everythingclient"
    default_derived_data="$HOME/Library/Developer/Xcode/DerivedData/everythingclient"
    
    derived_data_path=$local_derived_data # use local_derived_data for local testing

    coverage_cmd="xcrun llvm-cov report \
        $derived_data_path/Build/Products/Debug-iphonesimulator/$scheme.xctest/$scheme \
        -instr-profile \$(find $derived_data_path/Build/ProfileData -type d -depth 1 -exec ls -td {} + | head -n 1)/Coverage.profdata \
        ${ignore_patterns[@]} \
        --use-color"
    
    # Print full coverage report to console
    echo "\nFull coverage report for $scheme:"
    eval "$coverage_cmd"
    
    # Process coverage report for the file
    echo "\nSaving files with less than 100% coverage to $COVERAGE_REPORT"
    eval "$coverage_cmd" | while read -r line
    do
        # Check if line contains coverage data (has a percentage)
        if [[ $line =~ [0-9]+\.[0-9]+% ]]; then
            if [[ $line =~ "100.00%" ]]; then
                echo "$line" >> $COVERAGE_100_REPORT
            else
                echo "$line" >> $COVERAGE_REPORT
                echo "1" > .incomplete_coverage_flag
            fi
        fi
    done
    
    echo "----------------------------------------" >> $COVERAGE_REPORT
done

echo "Coverage report has been generated in $COVERAGE_REPORT"

# Print the contents of both coverage reports
echo -e "\nFiles with 100% coverage:"
cat "$COVERAGE_100_REPORT"
echo "Files with less than 100% coverage:"
cat "$COVERAGE_REPORT"

# Read the flag file and exit with error if incomplete coverage was found
if [ -f .incomplete_coverage_flag ]; then
    echo "❌ Found files with less than 100% coverage"
    rm .incomplete_coverage_flag
    exit 1
fi