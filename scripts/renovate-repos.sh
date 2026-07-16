#!/usr/bin/env bash
set -euo pipefail

PREFIX="${1:?PREFIX is not set}"

env | grep "^${PREFIX}_" | cut -d= -f2- | sort | jq -R -s -c 'split("\n") | map(select(length > 0))'
