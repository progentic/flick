#!/usr/bin/env bash
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
  echo 'INCONCLUSIVE: package validation requires Python 3'
  exit 2
fi
exec python3 "$(dirname "$0")/validate_packages.py"
