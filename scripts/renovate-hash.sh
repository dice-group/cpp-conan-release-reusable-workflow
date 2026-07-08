#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-renovate.json}"

sha256sum "$CONFIG_FILE" | cut -c1-12
