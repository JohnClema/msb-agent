#! /usr/bin/env bash

# Single verification entry point for agents and for scripts/msb-loop.
# Exit 0 only when the work is done. Replace the examples with real checks.

set -euo pipefail

cd "$(dirname "$0")/.."

# Examples, uncomment what applies:
# npm test
# npm run lint
# pytest -q
# go test ./...
# cargo test

echo "verify.sh: no checks configured yet, edit .agents/verify.sh" >&2
exit 1
