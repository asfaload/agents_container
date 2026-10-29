#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for t in tests/test_*.sh; do
  echo "== $t"
  bash "$t"
done
echo "all tests passed"
