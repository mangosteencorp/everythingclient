#!/bin/bash

# Get the simulator ID for testing
xcodebuild -scheme "$default" -showdestinations
# first simulator is usually just the placeholder
LAST_SIMULATOR_ID=$(xcodebuild -scheme "$default" -showdestinations | grep "iOS Simulator" | tail -n 1 | awk -F 'id:' '{print $2}' | awk -F ',' '{print $1}' | xargs)

# Export the simulator ID so it can be used in subsequent steps
echo "SIMULATOR_ID=$LAST_SIMULATOR_ID" >> $GITHUB_ENV

# Print for debugging
echo "Selected simulator ID: $LAST_SIMULATOR_ID" 