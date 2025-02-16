#!/bin/bash

# Required environment variables:
# - scheme: The Xcode scheme to build
# - platform: The platform to build for (e.g. "iOS Simulator")

# Get the first available iPhone simulator
device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`
echo "Using device: $device"

# Use the scheme from default file if needed
if [ "$scheme" = "default" ]; then 
    scheme=$(cat default)
fi

# Determine if we're using workspace or project
if [ "`ls -A | grep -i \\.xcworkspace\$`" ]; then 
    filetype_parameter="workspace" 
    file_to_build="`ls -A | grep -i \\.xcworkspace\$`"
else 
    filetype_parameter="project" 
    file_to_build="`ls -A | grep -i \\.xcodeproj\$`"
fi

# Clean up the file_to_build string
file_to_build=`echo $file_to_build | awk '{$1=$1;print}'`

echo "Building scheme: $scheme"
echo "File type: $filetype_parameter"
echo "File to build: $file_to_build"

# Run the build
xcodebuild build-for-testing \
    -scheme "$scheme" \
    -"$filetype_parameter" "$file_to_build" \
    -destination "platform=$platform,name=$device" 