#!/usr/bin/env bash
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
  echo 'INCONCLUSIVE: UI governance requires Python 3'
  exit 2
fi
exec python3 "$(dirname "$0")/governance.py" --ui-only "$@"
