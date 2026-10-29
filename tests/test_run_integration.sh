#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "FAIL: $1" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/work" "$tmp/repo"

cat >"$tmp/bin/docker" <<'EOF'
#!/bin/bash
while [ $# -gt 0 ]; do
  if [ "$1" = "--env-file" ]; then
    printf 'ENVFILE %s\n' "$2" >>"$MOCK_LOG"
    cat "$2" >>"$MOCK_LOG"
    shift 2
  else
    printf '%s\n' "$1" >>"$MOCK_LOG"
    shift
  fi
done
exit 0
EOF
cat >"$tmp/bin/xhost" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$tmp/bin/docker" "$tmp/bin/xhost"

# Committed tree, with the working-tree file under test overlaid
git archive HEAD | tar -x -C "$tmp/repo"
cp run.sh "$tmp/repo/run.sh"

unset DISPLAY

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
: >"$tmp/repo/cfg/mounts.cfg"

mkdir -p "$tmp/repo/profiles/tp"
echo "GLOBAL_ONLY=1" >"$tmp/repo/cfg/services.cfg"
echo "PROFILE_ONLY=1" >"$tmp/repo/profiles/tp/services.cfg"

export MOCK_LOG="$tmp/mock.log"
out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash run.sh --profile tp "$tmp/work" 2>&1)

grep -q "Using services from .*profiles/tp/services.cfg" <<<"$out" ||
  fail "expected profile services message, got: $out"
[ "$(grep -c '^ENVFILE ' "$MOCK_LOG")" -eq 2 ] || fail "expected two --env-file flags"
grep -q 'PROFILE_ONLY=1' "$MOCK_LOG" || fail "profile services var missing from docker env"
grep -q 'GLOBAL_ONLY' "$MOCK_LOG" && fail "global services var leaked (must be replaced, not merged)"
grep -q 'USER_NAME=tester' "$MOCK_LOG" || fail "infrastructure env var missing"

# No services file anywhere: hard error, no container start.
rm "$tmp/repo/cfg/services.cfg"
: >"$MOCK_LOG"
out2=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash run.sh --profile tp2 "$tmp/work" 2>&1) &&
  fail "run.sh must fail when no services.cfg exists"
grep -q 'services.cfg not found' <<<"$out2" || fail "missing-file error hint absent: $out2"
grep -q 'cfg/services.cfg.sample' <<<"$out2" || fail "error must name the sample file"
[ ! -s "$MOCK_LOG" ] || fail "container must not start when services.cfg is missing"

echo "test_run_integration: all passed"
