#!/bin/bash
set -euo pipefail

# Configure Xcode defaults for CI builds.
# Swift macros from transitive dependencies (e.g. via Swiftfin) require trust
# before use; CI has no UI to approve them.

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-./.DerivedData}"

defaults write com.apple.dt.Xcode IDECustomDerivedDataLocation "$DERIVED_DATA_PATH"
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "Configured Xcode defaults:"
echo "  IDECustomDerivedDataLocation=$DERIVED_DATA_PATH"
echo "  IDESkipMacroFingerprintValidation=YES"
