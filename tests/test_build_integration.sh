#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "FAIL: $1" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/repo"

cat >"$tmp/bin/docker" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" >>"$MOCK_LOG"
exit 0
EOF
chmod +x "$tmp/bin/docker"

# Committed tree, with the working-tree file under test overlaid
git archive HEAD | tar -x -C "$tmp/repo"
cp build.sh "$tmp/repo/build.sh"
mkdir -p "$tmp/repo/tmp"

cat >"$tmp/repo/cfg/env" <<'EOF'
USER_NAME=tester
USER_ID=1000
USER_GROUP=1000
MISE_DATA_DIR=/mise
MISE_CONFIG_DIR=/mise
MISE_CACHE_DIR=/mise/cache
MISE_INSTALL_PATH=/usr/local/bin/mise
IMAGE_NAME=test_img
EOF
echo "GLOBAL_ONLY=1" >"$tmp/repo/cfg/services.cfg"

export MOCK_LOG="$tmp/mock.log"

out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash build.sh 2>&1) ||
  fail "global-only build failed: $out"
grep -q "Using services from .*cfg/services.cfg" <<<"$out" ||
  fail "expected global services message, got: $out"

mkdir -p "$tmp/repo/profiles/bp"
echo "PROFILE_ONLY=1" >"$tmp/repo/profiles/bp/services.cfg"
out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash build.sh --profile bp 2>&1) ||
  fail "profile build failed: $out"
grep -q "Using services from .*profiles/bp/services.cfg" <<<"$out" ||
  fail "expected profile services message, got: $out"
grep -qx -- '--build-arg' "$MOCK_LOG" || fail "build args missing"
grep -qx 'USER_NAME=tester' "$MOCK_LOG" || fail "USER_NAME build arg missing"

echo "test_build_integration: all passed"
