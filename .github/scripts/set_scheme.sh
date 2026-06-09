#!/bin/bash
set -euo pipefail

pwd
ls -la

scheme_list=$(xcodebuild -list -json)
echo "Available schemes: $scheme_list"

schemes=$(printf "%s" "$scheme_list" | ruby -e '
  require "json"
  data = JSON.parse(STDIN.read)
  container = data["workspace"] || data["project"] || {}
  puts Array(container["schemes"])
')

if [ -z "$schemes" ]; then
  echo "No schemes found" >&2
  exit 1
fi

preferred_schemes=(
  "Rebuild"
  "EverythingClient"
  "TMDB"
)

default=""
for preferred_scheme in "${preferred_schemes[@]}"; do
  if printf "%s\n" "$schemes" | grep -qx "$preferred_scheme"; then
    default="$preferred_scheme"
    break
  fi
done

if [ -z "$default" ]; then
  default=$(printf "%s\n" "$schemes" | head -n 1)
fi

printf "%s" "$default" > default
echo "Using default scheme: $default"

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "default=$default" >> "$GITHUB_ENV"
fi
