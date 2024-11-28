#!/bin/bash

# List of test schemes
TEST_SCHEMES=(
    "TMDB_Dimilian_clean_tests"
    # Add more schemes here as needed
)

# Create a coverage report file
COVERAGE_REPORT=".output/coverage_report.txt"
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
    
    # Get the coverage report
    xcrun llvm-cov report \
        ./.DerivedData/everythingclient/Build/Products/Debug-iphonesimulator/"$scheme".xctest/"$scheme" \
        -instr-profile $(find ./.DerivedData/everythingclient/Build/ProfileData -type d -depth 1 -exec ls -td {} + | head -n 1)/Coverage.profdata \
        --ignore-filename-regex='.*/Tests/.*' \
        --ignore-filename-regex='.*/SourcePackages/checkouts/.*' \
        --use-color | while read -r line
    do
        # Check if line contains coverage data (has a percentage)
        if [[ $line =~ [0-9]+\.[0-9]+% ]] && [[ ! $line =~ "100.00%" ]]; then
            echo "$line" >> $COVERAGE_REPORT
        fi
    done
    
    echo "----------------------------------------" >> $COVERAGE_REPORT
done

echo "Coverage report has been generated in $COVERAGE_REPORT"