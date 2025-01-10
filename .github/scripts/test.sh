#!/bin/bash

# List of test schemes
TEST_SCHEMES=(
    "TMDB_clean_MLS_tests"
    "TMDB_Shared_Backend_Tests"
    # Add more schemes here as needed
)

# Create output directory if it doesn't exist
COVERAGE_REPORT=".output/coverage_report.txt"
mkdir -p $(dirname "$COVERAGE_REPORT")

# Create a coverage report file
echo "Coverage Report Generated on $(date)" > $COVERAGE_REPORT
echo "----------------------------------------" >> $COVERAGE_REPORT

# Run tests and generate coverage for each scheme
for scheme in "${TEST_SCHEMES[@]}"
do
    echo "Processing scheme: $scheme"
    echo "\nTesting $scheme..." >> $COVERAGE_REPORT
    
    # Run xcodebuild test
    xcodebuild test \
        -scheme "$scheme" \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
        -enableCodeCoverage YES
    
    # Store the coverage command to reuse it
    # First try workspace-relative .DerivedData
    local_derived_data="./.DerivedData/everythingclient"
    default_derived_data="$HOME/Library/Developer/Xcode/DerivedData/everythingclient"
    
    derived_data_path=$default_derived_data # use local_derived_data for local testing

    coverage_cmd="xcrun llvm-cov report \
        $derived_data_path/Build/Products/Debug-iphonesimulator/$scheme.xctest/$scheme \
        -instr-profile \$(find $derived_data_path/Build/ProfileData -type d -depth 1 -exec ls -td {} + | head -n 1)/Coverage.profdata \
        --ignore-filename-regex='.*/Tests/.*' \
        --ignore-filename-regex='.*/SourcePackages/checkouts/.*' \
        --use-color"
    
    # Print full coverage report to console
    echo "\nFull coverage report for $scheme:"
    eval "$coverage_cmd"
    
    # Process coverage report for the file
    echo "\nSaving files with less than 100% coverage to $COVERAGE_REPORT"
    eval "$coverage_cmd" | while read -r line
    do
        # Check if line contains coverage data (has a percentage)
        if [[ $line =~ [0-9]+\.[0-9]+% ]] && [[ ! $line =~ "100.00%" ]]; then
            echo "$line" >> $COVERAGE_REPORT
        fi
    done
    
    echo "----------------------------------------" >> $COVERAGE_REPORT
done

echo "Coverage report has been generated in $COVERAGE_REPORT"