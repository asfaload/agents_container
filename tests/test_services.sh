#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
. utils/services.sh

fail() { echo "FAIL: $1" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/profiles/p" "$tmp/cfg"

echo "A=1" >"$tmp/profiles/p/services.cfg"
echo "B=1" >"$tmp/cfg/services.cfg"
[ "$(resolve_services_file "$tmp/profiles/p" "$tmp")" = "$tmp/profiles/p/services.cfg" ] ||
  fail "profile file must win over global"

rm "$tmp/profiles/p/services.cfg"
[ "$(resolve_services_file "$tmp/profiles/p" "$tmp")" = "$tmp/cfg/services.cfg" ] ||
  fail "global file must be used when profile has none"

rm "$tmp/cfg/services.cfg"
if resolve_services_file "$tmp/profiles/p" "$tmp" >/dev/null 2>&1; then
  fail "must fail when neither profile nor global file exists"
fi

echo "test_services: all passed"
