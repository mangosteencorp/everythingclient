#!/bin/bash

# Debug info
pwd
ls -la

# Get the scheme list in JSON format
scheme_list=$(xcodebuild -list -json | tr -d "\n")
echo "Available schemes: $scheme_list"

# Determine the default scheme
if echo $scheme_list | grep -q "workspace"; then
    default=$(echo $scheme_list | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['workspace']['schemes'][0]" || echo "Rebuild")
else
    default=$(echo $scheme_list | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['project']['targets'][0]" || echo "Rebuild")
fi

# Save to file for other scripts
echo $default | cat >default
echo "Using default scheme: $default"

# Set environment variable for GitHub Actions
echo "default=$default" >> $GITHUB_ENV 