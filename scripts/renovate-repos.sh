#!/usr/bin/env bash
set -euo pipefail

env | grep '^DICE_GROUP_REPO_' | cut -d= -f2- | sort | jq -R -s -c 'split("\n") | map(select(length > 0))'
