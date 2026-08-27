#!/usr/bin/env bash
set -euo pipefail

pins=$(grep -hoE 'lukka/get-cmake@v[0-9.]+' .github/workflows/*.yml | sed 's/.*@//' | sort -u)
pin_count=$(echo "$pins" | wc -l)
if [ "$pin_count" -ne 1 ]; then
  echo "::error::Expected exactly one lukka/get-cmake pin across .github/workflows/*.yml, found: $(echo "$pins" | tr '\n' ' ')"
  exit 1
fi
pin="$pins"

defaults=$(grep -A2 '^[[:space:]]*cmake-version:[[:space:]]*$' .github/workflows/*.yml | grep -oE 'default:[[:space:]]*[0-9.]+' | grep -oE '[0-9.]+' | sort -u)
default_count=$(echo "$defaults" | wc -l)
if [ "$default_count" -ne 1 ]; then
  echo "::error::Expected exactly one cmake-version default across .github/workflows/*.yml, found: $(echo "$defaults" | tr '\n' ' ')"
  exit 1
fi
default="$defaults"

supported=$(curl -fsSL "https://raw.githubusercontent.com/lukka/get-cmake/${pin}/.latest_cmake_version")

echo "lukka/get-cmake pin: ${pin} (supports CMake up to ${supported})"
echo "cmake-version default in this repo: ${default}"

newest=$(printf '%s\n%s\n' "$supported" "$default" | sort -V | tail -n1)
if [ "$newest" != "$supported" ]; then
  echo "::error::cmake-version default (${default}) exceeds what lukka/get-cmake@${pin} supports (${supported}). Bump the lukka/get-cmake pin before merging, or this default will break any caller that doesn't override cmake-version."
  exit 1
fi

echo "OK: lukka/get-cmake@${pin} covers the cmake-version default (${default})."
