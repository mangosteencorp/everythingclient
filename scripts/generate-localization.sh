#!/bin/bash

# Check if target name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 TARGET_NAME"
    echo "Example: $0 TMDB_TVShowDetail"
    exit 1
fi

TARGET_NAME=$1

mint run xcstrings-tool generate \
    Sources/${TARGET_NAME}/Resources/Localizable.xcstrings \
    Sources/${TARGET_NAME}/generated/Localizable.swift